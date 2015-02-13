#!/usr/bin/env perl

=pod

=head1 NAME

Modules::Collection

=head1 SNYNOPSIS

=head1 DESCRIPTION

Run-mode to handle requests for user-defined strain groups.

Run-mode methods return the following JSON Response fields:

{ success: boolean, error: string, ...  }

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

package Modules::Collections;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::JSON qw/:all/;
use JSON::Any;
use Log::Log4perl qw/get_logger/;
use Modules::GenomeWarden;


=head2 setup

Run-mode initialization

=cut
sub setup {
	my $self = shift;

	# Logger
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Initializing Modules::Collections");

	# This is a AJAX module
	# Allow unathenticated users to reach server, but then
	# send JSON error rather than redirecting them to the
	# login page.
	# $self->authen->protected_runmodes(
	# 	qw/create/
	# );

}

=head2 update

Save changes to existing group

=cut
sub update {
	my $self = shift;

	

}

=head2 create

Create new group & collection if it doesn't
exist.

=cut
sub create : Runmode {
	my $self = shift;

	# User needs to be logged in to create groups
	unless($self->authen->is_authenticated) {
		return $self->json_body({ success => 0, error => "User not logged in" });
	}
	my $username = $self->authen->username;
	

	# Params
	my $q = $self->query();

	# Group name, required
	my $group_name = $q->param('name');
	unless($group_name) {
		return $self->json_body({ success => 0, error => "Parameter 'name' missing" });
	}

	# Group strains, required
	my @genomes = $q->param('genome');
	unless(@genomes) {
		return $self->json_body({ success => 0, error => "Parameter 'genome' missing" });
	}

	# Group description, optional 
	my $group_desc = $q->param('description');

	# Collection name, optional
	my $collection = $q->param('collection');

	# Validate genomes
	my $warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, genomes => \@genomes, user => $username, cvmemory => $self->cvmemory);
	my ($err, $bad1, $bad2) = $warden->error; 

	if($err) {
 		# User requested invalid strains or strains that they do not have permission to view
 		return $self->json_body({
 			success => 0,
 			error => 'Access violation for uploaded genomes: '.join(', ',@$bad1, @$bad2)
 		});
 	}
 	
	# Create group
	my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema, cvmemory => $self->cvmemory);
	my $grp_id = $data->createGroup($warden, {
		name => $group_name,
		username => $username,
		collection => $collection,
		description => $group_desc,
	});
	
	if($grp_id) {
		# Success, return new group ID
		return $self->json_body({
 			success => 1,
 			error => 'none',
 			group_id => $grp_id
 		});

	} else {
		# Error
		return $self->json_body({
 			success => 0,
 			error => 'Group creation failed. Is group name unique?'
 		});
	}

}

=head2 delete

Delete existing group, and remove collection
if empty.

=cut

sub delete {
	my $self = shift;

	

}

1;