#!/usr/bin/perl

package Modules::DisplayTest;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use parent 'CGI::Application';
use Role::Tiny::With;
with 'Roles::DatabaseConnector'; 

sub setup{
	my $self = shift;
	$self->start_mode('hello');
	# <reference name> => <sub name>
    $self->run_modes( 'hello'=>'hello' , 'display'=>'displayTest');

#connect to the local database

	$self->connectDatabase(
		{
			'dbi'=>'Pg',
			'dbName'=>'chado_db_test',
			'dbHost'=>'localhost',
			'dbPort'=>'5432',
			'dbUser'=>'postgres',
			'dbPass'=>'postgres'
		}
	);
}

#This will display the home page. Need to set the parameters for the templates so that they get loaded into browser properly
sub displayTest {
	my $self = shift;
	
	#Returns an object with column data
	my $features = $self->_getAllData();
	
	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $featureRef = $self->_hashData($features);

	my $template = $self->load_tmpl( 'display_test.tmpl' , die_on_bad_params=>0 );

	$template->param(FEATURES=>$featureRef);
	
	return $template->output();
}

sub _getAllData {
	my $self = shift;
	my $_features = $self->dbixSchema->resultset('Feature')->search(
		undef,
			{
				columns=>[ qw/feature_id uniquename residues/ ]
			}
		);
	return $_features;
}

#Inputs all column data into a hash table and returns a reference to the hash table.
sub _hashData {
	my $self=shift;
	my $features=shift;
	
	#Initialize an array to hold the loop
	my @featureData;
	
	while (my $featureRow = $features->next){
		#Initialize a hash structure to store column data in.
		my %featureRowData;
		$featureRowData{'FEATUREID'}=$featureRow->feature_id;
		$featureRowData{'UNIQUENAME'}=$featureRow->uniquename;
		$featureRowData{'RESIDUES'}=$featureRow->residues;
		#push a reference to each row into the loop
		push(@featureData, \%featureRowData);
	}
	#return a reference to the loop array
	return \@featureData;
}

# if a run mode is not indicated the program will croak(), so we set the default/start mode to this.
sub hello {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

1;