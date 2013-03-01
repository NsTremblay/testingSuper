#!/usr/bin/perl

package Modules::DisplayTest;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use parent 'CGI::Application';
use Role::Tiny::With;
#use Phylogeny::PhyloTreeBuilder;
with 'Roles::DatabaseConnector'; 

sub setup{
	my $self = shift;
	$self->start_mode('hello');
	# <reference name> => <sub name>
	$self->run_modes( 'hello'=>'hello', 
		'display'=>'displayTest', 
		'single_strain'=>'singleStrain',
		'multi_strain'=>'multiStrain',
		'bioinfo'=>'bioinfo',
		'process_single_strain_form'=>'singleStrainForm');

#connect to the local database

$self->connectDatabase({
	'dbi'=>'Pg',
	'dbName'=>'chado_db_test',
	'dbHost'=>'localhost',
	'dbPort'=>'5432',
	'dbUser'=>'postgres',
	'dbPass'=>'postgres'
});
}

###############
###Run Modes###
###############

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

# if a run mode is not indicated the program will croak(), so we set the default/start mode to this.
sub hello {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

sub singleStrain {
	my $self = shift;

	#Returns an object with column data
	my $features = $self->_getAllData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $featureRef = $self->_hashData($features);

	my $template = $self->load_tmpl ( 'single_strain.tmpl' , die_on_bad_params=>0 );
	$template->param(FEATURES=>$featureRef);
	return $template->output();
	#Phylogeny::PhyloTreeBuilder->new('NewickTrees/example_tree' , 'NewickTrees/tree');
}

sub multiStrain {
	my $self = shift;

	#Returns an object with column data
	my $features = $self->_getAllData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $featureRef = $self->_hashData($features);

	my $template = $self->load_tmpl ( 'multi_strain.tmpl' , die_on_bad_params=>0 );
	$template->param(FEATURES=>$featureRef);
	return $template->output();
}

sub bioinfo {
	my $self = shift;
	my $template = $self->load_tmpl ( 'bioinfo.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

###############################
###Form Processing Run Modes###
###############################

sub singleStrainForm {
	my $self = shift;
	##TODO: This needs to query the db and return information to be displayed in the browser
}


#######################
###Helper Functions ###
#######################

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

1;