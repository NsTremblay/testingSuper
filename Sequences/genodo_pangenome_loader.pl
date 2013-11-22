#!/usr/bin/env perl

=head1 NAME

$0 - Processes a fasta file of pangenome sequence fragments and uploads into the feature table of the database specified in the config file.

=head1 SYNOPSIS
	
	% genodo_pangenome_loader.pl [options]

=head1 COMMAND-LINE OPTIONS

	--panseq            Optionally, specify a panseq results output directory. If not provided, script will download genome from DB.
	--config 			Specify a valid config file with db connection params.

=head1 DESCRIPTION



=head1 AUTHOR

Matt Whiteside

=cut

use strict;
use warnings;

use Getopt::Long;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Config::Simple;
use Carp qw/croak carp/;
use File::Path qw/remove_tree/;

# Globals (set these to match local values)
my $muscle_exe = '/usr/bin/muscle';
my $mummer_dir = '/home/matt/MUMer3.23/';
my $blast_dir = '/home/matt/blast/bin/';
my $parallel_exe = '/usr/bin/parallel';
my $nr_location = '/home/matt/tmp/data/blast_databases/nr';
my $panseq_exe = '/home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl';

my ($panseq_dir, $config_file);

# Parse command-line
GetOptions(
	'panseq=s' => \$panseq_dir,
	'config=s' => \$config_file,
) or ( system( 'pod2text', $0 ), exit -1 );

croak "[Error] missing argument. You must supply a valid config file\n" . system('pod2text', $0) unless $config_file;

# Connect to DB
my ($dbname, $dbuser, $dbpass, $dbhost, $dbport, $dbi, $tmp_dir);

if(my $db_conf = new Config::Simple($config_file)) {
	$dbname    = $db_conf->param('db.name');
	$dbuser    = $db_conf->param('db.user');
	$dbpass    = $db_conf->param('db.pass');
	$dbhost    = $db_conf->param('db.host');
	$dbport    = $db_conf->param('db.port');
	$dbi       = $db_conf->param('db.dbi');
	$tmp_dir   = $db_conf->param('tmp.dir');
} 
else {
	croak "[Error] unable to read configuration file ( " . Config::Simple->error() . ").\n";
}

croak "[Error] invalid configuration file." unless $dbname;

my $dbsource = 'dbi:' . $dbi . ':dbname=' . $dbname . ';host=' . $dbhost;
$dbsource . ';port=' . $dbport if $dbport;

my $schema = Database::Chado::Schema->connect($dbsource, $dbuser, $dbpass) or croak "[Error] could not connect to database ($!).\n";


unless($panseq_dir) {
	# Run pan-seq
	print "Running panseq...\n";
	
	my $root_dir = $tmp_dir . 'panseq_pangenome/';
	unless (-e $root_dir) {
		mkdir $root_dir or croak "[Error] unable to create directory $root_dir ($!).\n";
	}
	
	# Download all genome sequences
	print "\tdownloading genome sequences...\n";
	my $fasta_dir = $root_dir . '/fasta/';
	unless (-e $fasta_dir) {
		mkdir $fasta_dir or croak "[Error] unable to create directory $fasta_dir ($!).\n";
	}
	my $fasta_file = $fasta_dir . 'genomes.ffn';
	
	my $cmd = "perl $FindBin::Bin/../Database/contig_fasta.pl --config $config_file --output $fasta_file";
	system($cmd) == 0 or croak "[Error] download of contig sequences failed (syscmd: $cmd).\n";
	print "\tcomplete\n";
	
	# Run panseq
	print "\tpreparing panseq input...\n";
	$panseq_dir = $root_dir . 'panseq/';
	if(-e $panseq_dir) {
		remove_tree $panseq_dir or croak "[Error] unable to delete directory $panseq_dir ($!).\n";
	}
	
	my $pan_cfg_file = $root_dir . 'pg.conf';
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out
qq|queryDirectory	$fasta_dir
baseDirectory	$panseq_dir
numberOfCores	24
mummerDirectory	$mummer_dir
blastDirectory	$blast_dir
minimumNovelRegionSize	1000
novelRegionFinderMode	no_duplicates
muscleExecutable	$muscle_exe
fragmentationSize	1000
percentIdentityCutoff	90
coreGenomeThreshold	4
runMode	pan
|;
	close $out;
	
	my @loading_args = ($panseq_exe,
	$pan_cfg_file);
	print "\tcomplete\n";
	
	print "\trunning panseq...\n";
	$cmd = join(' ', @loading_args);
	system($cmd) == 0 or croak "[Error] Panseq analysis failed.\n";
	print "\tcomplete\n";
	
}
