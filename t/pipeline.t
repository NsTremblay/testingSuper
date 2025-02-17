#!/usr/bin/env perl

=pod

=head1 NAME

t::pipeline.t

=head1 SNYNOPSIS



=head1 DESCRIPTION

Tests for Data/genodo_pipeline.pl

Creates clone of demo database for testing and uploads a single sequence.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Test::More;
use Test::Exception;
use lib "$FindBin::Bin/lib/";
use TestPostgresDB;
use t::lib::App;
use Config::Simple;
use File::Temp qw/tempdir/;
use IO::CaptureOutput qw(capture_exec);
use Modules::User;
use Test::DBIx::Class {
	schema_class => 'Database::Chado::Schema',
	deploy_db => 0,
	keep_db => 0,
	traits => [qw/TestPostgresDB/]
}, 'Tracker', 'Login';


# Create test CGIApp and work environment
my $cgiapp;
lives_ok { $cgiapp = t::lib::App::launch(Schema, $ARGV[0]) } 'Test::WWW::Mechanize::CGIApp initialized';
BAIL_OUT('CGIApp initialization failed') unless $cgiapp;


# Login as test user
fixtures_ok [
	'Login' => [
		[qw/username password firstname lastname email/],
	    ['testbot', Modules::User::_encode_password('password'), 'testbot', '3000', 'donotemailme@ever.com'],
	    ['eviltestbot', Modules::User::_encode_password('password'), 'eviltestbot', '4000', 'donotemailme@ever.com']
	]
], 'Inserted test users';
t::lib::App::login_ok($cgiapp, 'testbot', 'password');
ok(my $login_id = Login->find({ username => 'testbot' })->login_id, 'Retrieved login ID for test user');


# Submit genome upload
my $genome_name = upload_genome($cgiapp);

# Validate tracker table entry
my $tracking_id = tracker_table($cgiapp, $login_id, $genome_name);

# Initiate loading pipeline
run_pipeline();




done_testing();

########
## SUBS
########

=head2 init

Prepare test sandbox and CGIApp config file

=cut
sub init {
	my $root_dir = shift;
	my $orig_cfg_file = shift;

	# Create temporary directory for test files
	my $test_dir = tempdir('XXXX', DIR => $root_dir, CLEANUP => 1);

	# Create config file with test server parameters
	my $cfg_file = $test_dir . '/test.cfg';
	my $cfg = new Config::Simple(syntax=>'ini');

	# Temp directory
	my $tmp_dir = $test_dir . '/tmp/';
	mkdir $tmp_dir or die "Error: mkdir $tmp_dir failed ($!).\n";
	$cfg->param('tmp.dir', $tmp_dir);

	# Pipeline input directory
	my $seq_dir = $test_dir . '/inbox/';
	mkdir $seq_dir or die "Error: mkdir $seq_dir failed ($!).\n";
	$cfg->param('dir.seq', $seq_dir);

	# Log directory
	my $log_dir = $test_dir . '/logs/';
	mkdir $log_dir or die "Error: mkdir $log_dir failed ($!).\n";
	$cfg->param('dir.log', $log_dir);

	# Pipeline work directory
	my $work_dir = $test_dir . '/data/';
	mkdir $work_dir or die "Error: mkdir $work_dir failed ($!).\n";
	$cfg->param('dir.sandbox', $work_dir);

	# Copy external commands from a current config file
	my $oldcfg = new Config::Simple($orig_cfg_file);
	unless($oldcfg) {
		die Config::Simple->error();
	}

	my @copy_params = qw/ext.blastdir ext.mummerdir ext.parallel ext.muscle ext.blastdatabase ext.panseq mail.address mail.pass/;
	foreach my $p (@copy_params) {
		$cfg->param($p, $oldcfg->param($p));
	}

	$cfg->write($cfg_file) or die "Write to config file $cfg_file failed:" . Config::Simple->error();

	return $cfg_file;
}

=head2 upload_genome

Send request to server to upload genome

=cut
sub upload_genome {
	my $cgiapp = shift;

	# Fasta file
	my $fasta_file = "$FindBin::Bin/etc/JRGD.fasta";
	ok(-e $fasta_file, "Fasta file exists");

	my $file = [
		$fasta_file,
		"genome.ffn",
		'Content-type' => 'text/plain'
	];

	# Genome properties
	my $genome_name = 'Experimental strain Gamma-22';
	# Location submission needs to be fixed
	my $form = [
		g_name => $genome_name,
		g_serotype => 'O48:H6',
		g_strain => 'K12',
		g_date => '2001-02-03',
		g_mol_type => 'wgs',
		g_host => 'hsapiens',
		g_source => 'stool',
		g_locate_method => 'name',
		g_location_country => 'Canada',
		address => 'Canada',
		g_privacy => 'public',
		g_file => $file
	];

	# Submit form
	my $rm = '/upload/upload_genome';
	$cgiapp->post($rm,
		$form,
		'Content_Type' => 'form-data'
	);
	ok($cgiapp->success, 'Genome upload POST');

	#diag $cgiapp->content(format => 'text');

	$cgiapp->content_contains('Status of Uploaded Genome', "Redirected to upload status page");
	$cgiapp->content_contains('Queued', "Genome queued for analysis") or 
		BAIL_OUT('Genome upload failed');

	return $genome_name;
}

=head2 tracking_table

Make sure tracking table contains uploaded genome details

=cut
sub tracker_table {
	my $cgiapp = shift;
	my $login_id = shift;
	my $genome_name = shift;

	ok my $track = Tracker->find( { login_id => $login_id, feature_name => $genome_name })
    	=> 'Tracker table entry found';

    is_fields [qw/step access_category/], $track, [1, 'public'],
    	'Tracker entry valid';

    return $track->tracker_id;
}

=head2 run_pipeline

Run analysis pipeline and ensure that it completes successfully

=cut
sub run_pipeline {

	my $perl_interpreter = $^X;
	my $cmd = "$perl_interpreter $FindBin::Bin/../Data/genodo_pipeline.pl";
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);

	ok($success, "loading pipeline completed") or
		BAIL_OUT("Loading pipeline failed ($stderr)");
}

