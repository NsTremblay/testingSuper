# This is similar to an interface in Java. We'll set up a connection 
# subroutine here.

#!/usr/bin/perl

package Roles::DatabaseConnector;

use strict;
use warnings;
use FindBin;
use lib "FindBin::Bin/../";
use Database::Chado::TestSchema;
use Role::Tiny;

sub connectDatabase{
	my $self = shift;
	my $paramsRef = shift; #This pulls the relevant connection parameters
	#dbi:Pg:dbname=chado_db_test;host=localhost;port=5432' , 'username' , ' password'
	my $dataSource = 'dbi:' . $paramsRef->{'dbi'} . ':dbname=' . $paramsRef->{'dbName'} . ';host=' . $paramsRef->{'dbHost'} . ';port=' . $paramsRef->{'dbPort'};
	my $dbHandle = Database::Chado::TestSchema->connect($dataSource,$paramsRef->{'dbUser'},$paramsRef->{'dbPass'}) or die "Could not connect to database";
	$self->dbixSchema($dbHandle);
}

#Get/Set methods
#Assigns the parameters as a new connection to the database, otherwise returns the existing dbHandle.
sub dbixSchema{
	my $self = shift;
	$self->{'_dbixSchema'}=shift // return $self->{'_dbixSchema'};
}

1;
