#!/usr/bin/env perl

=pod

=head1 NAME

t::App

=head1 SNYNOPSIS

=head1 DESCRIPTION



=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

package t::lib::App;

use strict;
use warnings;
use File::Basename qw< dirname >;
use lib dirname(__FILE__) . '/../../';
use Test::WWW::Mechanize::CGIApp;
use Test::More;
use Modules::Dispatch;
use JSON::MaybeXS;
use t::lib::QuickDB;
use Config::Simple;
use File::Temp qw/tempdir/;


=head2 launch

=cut

sub launch {
	my $schema = shift; # DBICx schema ref

	my $cfg_file = init(@_);

	$ENV{SUPERPHY_CONFIGFILE} = $cfg_file;

	my $mech = Test::WWW::Mechanize::CGIApp->new;
  	$mech->app(
	    sub {
		    #require "Modules::Dispatch";
		    Modules::Dispatch->dispatch( 
		    	args_to_new => {
	            	PARAMS => {
	            		'test_mode' => 1,
	            		'test_schema' => $schema
	            	},
	            }
	        );
    	}
    );

  	return $mech;
}

=head2 init

Prepare test sandbox and CGIApp config file

=cut
sub init {

	my $orig_cfg_file = dirname(__FILE__) . '/config/demo.cfg' ;
	my $root_dir = dirname(__FILE__) . '/sandbox';
	
	die "[Error] test work directory $root_dir invalid.\n" unless -d $root_dir;
	die "[Error] config file $orig_cfg_file invalid.\n" unless -f $orig_cfg_file;

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

=head2 quickdb_login

Login as test user for the quickdb database

=cut
sub quickdb_login {
	my $mech = shift;

	my $login_crudentials = t::QuickDB::login_crudentials();

	my $page = '/home';
	$mech->post_ok( $page, $login_crudentials, 'attempt login as test user' );
	$mech->content_contains( $login_crudentials->{authen_username}, 'logged in as test user' ) or 
		BAIL_OUT('Login as test user failed');
}

=head2 login_ok

Login as user to webserver

Will BAIL_OUT if unsuccessful

=cut
sub login_ok {
	my $mech = shift;
	my $user = shift;
	my $passwd = shift;

	my $login_crudentials = {
		authen_username => $user,
        authen_password => $passwd,
        authen_rememberuser => 0
    };

	my $page = '/home';
	$mech->post_ok( $page, $login_crudentials, 'Login form POST' );
	$mech->content_contains( $login_crudentials->{authen_username}, 'Logged in as test user' ) or 
		BAIL_OUT('Login failed');
}


# The following methods are from Test::WWW::Mechanize::JSON

=head2 $mech->json_ok($desc)

Tests that the last received resopnse body is valid JSON.

A default description of "Got JSON from $url"
or "Not JSON from $url"
is used if none if provided.

Returns the L<JSON|JSON> object, that you may perform
further tests upon it.

=cut

sub json_ok {
	my ($mech, $desc) = @_;
	return _json_ok($mech, $desc, $mech->content );
}

=head2 json

=cut

sub json {
	my ($mech, $text) = @_;
	$text ||= exists $mech->response->headers->{'x-json'} ?
		$mech->response->headers->{'x-json'}
	:	$mech->content;
	my $json = eval {
		JSON::Any->jsonToObj($text);
	};
	return $json;
}

sub _json_ok {
	my ($mech, $desc, $text) = @_;
	my $json = json($mech, $text );

	if (not $desc){
		if (defined $json and ref $json eq 'HASH' and not $@){
			$desc = sprintf 'got JSON from %s', $mech->uri;
		}
		else {
			$desc = sprintf 'not JSON from %s (%s)', $mech->uri, $@;
		}
	}

	Test::Builder->new->ok( $json, $desc );

	return $json || undef;
}


=head2 $mech->diag_json

Like L<diag|Test::More/diag>, but renders the JSON of body the last request
with indentation.

=cut

sub diag_json {
	my $mech = shift;
	return _diag_json($mech, $mech->content );
}

=head2 $mech->diag_x_json

Like L<diag|Test::More/diag>, but renders the JSON
from the C<x-json> header of the last request with indentation.

=cut

sub diag_x_json {
	my $mech = shift;
	return _diag_json($mech,
		$mech->response->headers->{'x-json'}
	);
}

sub _diag_json {
	my ($mech, $text) = @_;
	eval {
		my $json = json($mech, $text );
		if (not defined $json){
			warn "Not a $json objet";
		}
		elsif (not ref $json or ref $json ne 'HASH'){
			warn "Not an JSON object";
		}
		else {
			warn "Not a JSON object?";
		}
	};
	warn $@ if $@;
}





1;
