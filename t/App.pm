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

package t::App;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::WWW::Mechanize::CGIApp;
use Test::More;
use Modules::Dispatch;
use JSON::Any;
use t::QuickDB;


=head2 launch

=cut

sub launch {
	my $schema = shift; # DBICx schema ref

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
	$text ||= exists $mech->response->headers->{'x-json'}?
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
