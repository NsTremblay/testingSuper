#!/usr/bin/perl

package Modules::DisplayTest;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Role::Tiny::With;
use parent 'Modules::App_Super';
use parent 'CGI::Application';
#use Phylogeny::PhyloTreeBuilder;
with 'Roles::DatabaseConnector';

setup();

sub setup {

$self->connectDatabase({
	'dbi'=>'Pg',
	'dbName'=>'chado_db_test',
	'dbHost'=>'localhost',
	'dbPort'=>'5432',
	'dbUser'=>'postgres',
	'dbPass'=>'postgres'
	});
}

sub displayTest {

	#Returns an object with column data
	my $features = _getFormData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $formFeatureRef = _hashFormData($features);
}

sub _getFormData {
	my $_features = dbixSchema->resultset('Feature')->search(
		undef,
		{
			columns=>[ qw/feature_id uniquename/ ]
		}
		);
	#TODO: This needs to be changed to pull only sequence data and not virulence factors.
	return $_features;
}

#Inputs all column data into a hash table and returns a reference to the hash table.
sub _hashFormData {
	my $features=shift;
	
	#Initialize an array to hold the loop
	my @formData;
	
	while (my $featureRow = $features->next){
		#Initialize a hash structure to store column data in.
		my %formRowData;
		$formRowData{'FEATUREID'}=$featureRow->feature_id;
		$formRowData{'UNIQUENAME'}=$featureRow->uniquename;
		
		#push a reference to each row into the loop
		push(@formData, \%formRowData);
	}
	#return a reference to the loop array
	return \@formData;
}

1;