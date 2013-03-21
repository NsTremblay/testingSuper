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
		'process_single_strain_form'=>'singleStrain',
		'process_multi_strain_form'=>'multiStrain');

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
	my $features = $self->_getFormData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $formFeatureRef = $self->_hashFormData($features);

	my $template = $self->load_tmpl( 'display_test.tmpl' , die_on_bad_params=>0 );
	$template->param(FEATURES=>$formFeatureRef);	
	return $template->output();
}

# if a run mode is not indicated the program will croak(), so we set the default/start mode to this.
sub hello {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

###############################
###Form Processing Run Modes###
###############################

sub singleStrain {
	#TODO: Need to reload either the home page or single_strain depending on which page the user is on.

	my $self = shift;

	#Returns an object with column data
	my $features = $self->_getFormData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl ( 'single_strain.tmpl' , die_on_bad_params=>0 );
	
	my $q = $self->query();
	my $strainFeatureId = $q->param("singleStrainName");

	if(!defined $strainFeatureId || $strainFeatureId == ""){
		$template->param(FEATURES=>$formFeatureRef);
	}
	else {
		my $_sSFeatures = $self->dbixSchema->resultset('Feature')->find({feature_id => "$strainFeatureId"});
		$template->param(FEATURES=>$formFeatureRef);
		$template->param(sSUNIQUENAME=>$_sSFeatures->uniquename);
		$template->param(sSRESIDUE=>$_sSFeatures->residues);
		$template->param(sSFEATUREID=>$_sSFeatures->feature_id);
		$template->param(sSEQLENGTH=>$_sSFeatures->seqlen);
		my $ssvalidator = "Return Success";
		$template->param(sSVALIDATOR=>$ssvalidator);
	}
	return $template->output();
	#Phylogeny::PhyloTreeBuilder->new('NewickTrees/example_tree' , 'NewickTrees/tree');
}

sub multiStrain {
	my $self = shift;
	my $features = $self->_getFormData();
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl ( 'multi_strain.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my $strainFeatureTable = $self->dbixSchema->resultset('Feature');
	my @strainFeatureIds = $q->param("multiStrainNames"); #This is causing errors.

	if(!(@strainFeatureIds)) {
		$template->param(FEATURES=>$formFeatureRef);
	}
	else {
		my $multiStrainDataRef = $self->_getMultiStrainData(\@strainFeatureIds, $strainFeatureTable);
		$template->param(FEATURES=>$formFeatureRef);
		$template->param(mSFEATURES=>$multiStrainDataRef);
		my $msvalidator = "Return Success";
		$template->param(mSVALIDATOR=>$msvalidator);
	}
	return $template->output();
}

sub bioinfo {
	my $self = shift;

	#Returns an object with column data
	my $features = $self->_getFormData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $formFeatureRef = $self->_hashFormData($features);

	my $template = $self->load_tmpl( 'bioinfo.tmpl' , die_on_bad_params=>0 );
	$template->param(FEATURES=>$formFeatureRef);	
	return $template->output();
}

#######################
###Helper Functions ###
#######################

#Returns unique names and their feature ids to fill search and selection forms
sub _getFormData {
	my $self = shift;
	my $_features = $self->dbixSchema->resultset('Feature')->search(
		undef,
		{
			#join		=> ['featureprops', 'type'],
			#select		=> [ qw/me.feature_id me.uniquename featureprops.type_id featureprops.value type.cvterm_id type.name/],
			#as 			=> ['feature_id', 'uniquename' , 'type_id' , 'value' , 'cvterm_id', 'term_name'],
			#group_by 	=> [ qw/me.feature_id me.uniquename featureprops.type_id featureprops.value type.cvterm_id type.name/ ],
			#having 		=> [ 'featureprops.value' =>'eae'],
			#order_by 	=> { -asc => ['uniquename']},
			columns		=> [ qw/feature_id uniquename/ ]
		}
		);
	#TODO: This nee	#TODO: This needs to be changed to pull only sequence data and not virulence factors.
	return $_features;
}

#Inputs all column data into a hash table and returns a reference to the hash table.
sub _hashFormData {
	my $self=shift;
	my $features=shift;
	
	#Initialize an array to hold the loop
	my @formData;
	
	while (my $featureRow = $features->next){
		#Initialize a hash structure to store column data in.
		my %formRowData;
		$formRowData{'FEATUREID'}=$featureRow->feature_id;
		$formRowData{'UNIQUENAME'}=$featureRow->uniquename;
		#$formRowData{'TERMNAME'}=$featureRow->type->name;
		#$formRowData{'TERMVALUE'}=$featureRow->featureprops;
		#push a reference to each row into the loop
		push(@formData, \%formRowData);
	}
	#return a reference to the loop array
	return \@formData;
}

sub _getMultiStrainData {
	my $self = shift;
	my $strainFeatureIds = shift;
	my $strainFeatureTable = shift;
	my @multiStrainData;
	my %multiRowData;
	my @multiNestedRowLoop;

	foreach my $multiStrainId (@{$strainFeatureIds}) {

		my $_mSFeatures = $strainFeatureTable->find({feature_id => "$multiStrainId"});
		
		#Create a hash table and push these keys onto it
		my %multiNestedRow;
		$multiNestedRow{'mSFEATUREID'}=$_mSFeatures->feature_id;
		$multiNestedRow{'mSRESIDUES'}=$_mSFeatures->residues;
		$multiNestedRow{'mSSEQLENGTH'}=$_mSFeatures->seqlen;
		$multiNestedRow{'mSUNIQUENAME'}=$_mSFeatures->uniquename;
		push(@multiNestedRowLoop, \%multiNestedRow);
	}
	return \@multiNestedRowLoop;
}

1;