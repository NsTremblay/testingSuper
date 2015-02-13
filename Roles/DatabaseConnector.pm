#!/usr/bin/perl
package Roles::DatabaseConnector;

use strict;
use warnings;
use Role::Tiny;
use Carp qw/croak/;
use FindBin;
use lib "FindBin::Bin/../";
use Database::Chado::Schema;



=head2 connectDatabase

Create and save dbix::class::schema handle.  Connect to database using DBI::connect parameters.  If already connected,
it will die.

=cut
sub connectDatabase {
	my $self = shift;
	my %params = @_;
	
	croak "Cannot call connectDatabase with existing connection to database.\n" if $self->{_dbixSchema};
	
	my $dbi = $params{'dbi'} // croak 'Missing dbi argument.';
	my $dbName = $params{'dbName'} // croak 'Missing dbName argument.';
	my $dbHost = $params{'dbHost'} // croak 'Missing dbHost argument.';
	my $dbPort = $params{'dbPort'};
	
	$self->{_dbixConif}->{dbUser} = $params{'dbUser'} // croak 'Missing dbUser argument.';
	$self->{_dbixConif}->{dbPass} = $params{'dbPass'} // croak 'Missing dbPass argument.';
	my $source = 'dbi:' . $dbi . ':dbname=' . $dbName . ';host=' . $dbHost;
	$source . ';port=' . $dbPort if $dbPort;
	$self->{_dbixConif}->{dbSource} = $source;
	
	$self->{_dbixSchema} = Database::Chado::Schema->connect($self->{_dbixConif}->{'dbSource'}, $self->{_dbixConif}->{'dbUser'},
			$self->{_dbixConif}->{'dbPass'}) or croak "Could not connect to database";
}

=head2 dbixSchema

Return the dbix::class::schema object.

=cut

sub dbixSchema {
	my $self = shift;
	
	croak "Database not connected" unless $self->{_dbixSchema};
	
	return($self->{_dbixSchema});
}

=head2 dbixSchema

Set the dbix::class::schema object.

=cut

sub setDbix {
	my $self = shift;
	my $dbix_handle = shift;
	
	$self->{_dbixSchema} = $dbix_handle;
}

=head2 dbh

Return the DBI dbh from the dbix::class::schema object.

=cut

sub dbh {
	my $self = shift;
	
	croak "Database not connected" unless $self->{_dbixSchema};
	
	return($self->{_dbixSchema}->storage->dbh);
}

=head2 dbh

Return entry in Login table corresponding to "System admin".
This user is used as a default for user groups e.g.

=cut
sub adminUser {
	my $self = shift;
	
	return $self->{_dbixConif}->{dbUser};
}

1;
