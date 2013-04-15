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
		#'bioinfo'=>'bioinfo',
		'bioinfo_strain_list'=>'bioinfoStrainList',
		'bioinfo_virulence_factors'=>'bioinfoVirulenceFactors',
		'bioinfo_statistics'=>'bioinfoStatistics',
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

	my $features = $self->_getFormData();

	#Each row of column data is stored into a hash table. A reference to each hash table row is stored in an array.
	#Returns a reference to an array with references to each row of data in the hash table
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl ( 'single_strain.tmpl' , die_on_bad_params=>0 );
	
	my $q = $self->query();
	my $strainName = $q->param("singleStrainName");

	if(!defined $strainName || $strainName eq ""){
		$template->param(FEATURES=>$formFeatureRef);
	}
	else {
		$template->param(FEATURES=>$formFeatureRef);
		
		my $_sSFeatureprop = $self->dbixSchema->resultset('Featureprop')->find({value => "$strainName"});
		my $_sSFeatures = $self->dbixSchema->resultset('Feature')->find({feature_id => $_sSFeatureprop->feature_id});
		#my $sSMetaInfo = _getSSMetaInfo($strainName);
		#my $sSRef = _hashSSMetaInfo($sSMetaInfo);
		
		#$template->param(sSMETAINFO=>$sSRef);
		#$template->param(sSRESIDUE=>$_sSFeatures->residues);
		$template->param(sSFEATUREID=>$_sSFeatureprop->feature_id);
		$template->param(sSVALUE=>$_sSFeatureprop->value);
		$template->param(sSUNIQUENAME=>$_sSFeatures->uniquename);
		$template->param(sSEQLENGTH=>$_sSFeatures->seqlen);
		my $ssvalidator = "Return Success";
		$template->param(sSVALIDATOR=>$ssvalidator);
	}
	return $template->output();
}

sub multiStrain {
	my $self = shift;
	my $features = $self->_getFormData();
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl ( 'multi_strain.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my $strainFeaturepropTable = $self->dbixSchema->resultset('Featureprop');
	my $strainFeatureTable = $self->dbixSchema->resultset('Feature');
	my @groupOneStrainFeatureIds = $q->param("group1");
	my @groupTwoStrainFeatureIds = $q->param("group2");

	if(!(@groupOneStrainFeatureIds) && !(@groupTwoStrainFeatureIds)) {
		$template->param(FEATURES=>$formFeatureRef);
	}
	else {
		my $groupOneDataRef = $self->_getMultiStrainData(\@groupOneStrainFeatureIds, $strainFeaturepropTable, $strainFeatureTable);
		my $groupTwoDataRef = $self->_getMultiStrainData(\@groupTwoStrainFeatureIds, $strainFeaturepropTable, $strainFeatureTable);
		$template->param(FEATURES=>$formFeatureRef);
		$template->param(mSGPONEFEATURES=>$groupOneDataRef);
		$template->param(mSGPTWOFEATURES=>$groupTwoDataRef);
		my $msvalidator = "Return Success";
		$template->param(mSVALIDATOR=>$msvalidator);
	}
	return $template->output();
}

sub bioinfoStrainList {

	#For now just testing to see if we can display joined data on the website
	my $self = shift;
	#Returns an object with column data
	my $vFactors = $self->_getVFData();
	my $features = $self->_getFormData();
	my $vFRef = $self->_hashVFData($vFactors);
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl( 'bioinfo_strain_list.tmpl' , die_on_bad_params=>0 );
	$template->param(vFACTORS=>$vFRef);
	$template->param(FEATURES=>$formFeatureRef);
	return $template->output();
}

sub bioinfoVirulenceFactors {
	my $self = shift;
	my $vFactors = $self->_getVFData();
	my $vFRef = $self->_hashVFData($vFactors);
	
	my $q = $self->query();
	my $template = $self->load_tmpl( 'bioinfo_virulence_factors.tmpl' , die_on_bad_params=>0 );
	my $vfFeatureId = $q->param("VFName");

	if (!defined $vfFeatureId || $vfFeatureId eq ""){
		$template->param(vFACTORS=>$vFRef);
	}
	else {
		my $vFMetaInfoRef = $self->_getVFMetaInfo($vfFeatureId);
		$template->param(vFACTORS=>$vFRef);
		my $vfvalidator = "Return Success";
		$template->param(vFVALIDATOR=>$vfvalidator);
		$template->param(vFMETAINFO=>$vFMetaInfoRef);
	}
	return $template->output();
}

sub bioinfoStatistics {
	my $self = shift;
	my $vFactors = $self->_getVFData();
	my $features = $self->_getFormData();
	my $vFRef = $self->_hashVFData($vFactors);
	my $formFeatureRef = $self->_hashFormData($features);
	my $template = $self->load_tmpl( 'bioinfo_statistics.tmpl' , die_on_bad_params=>0 );
	$template->param(vFACTORS=>$vFRef);
	$template->param(FEATURES=>$formFeatureRef);
	return $template->output();
}

#######################
###Helper Functions ###
#######################

# sub _getFormData {
# 	my $self = shift;
# 	my $_features = $self->dbixSchema->resultset('Featureprop')->search(
# 		{value => 'Genome Sequence'},
# 		{
# 			join		=> ['type', 'feature'],
# 			select		=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/],
# 			as 			=> ['feature_id', 'type_id' , 'value' , 'cvterm_id', 'term_name' , 'uniquename'],
# 			group_by 	=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/ ],
# 			order_by 	=> { -asc => ['uniquename']}
# 		}
# 		);
# 	return $_features;
# }

# #Inputs all column data into a hash table and returns a reference to the hash table.
# sub _hashFormData {
# 	my $self=shift;
# 	my $features=shift;

# 	#Initialize an array to hold the loop
# 	my @formData;

# 	while (my $featureRow = $features->next){
# 		#Initialize a hash structure to store column data in.
# 		my %formRowData;
# 		$formRowData{'FEATUREID'}=$featureRow->feature_id;
# 		$formRowData{'UNIQUENAME'}=$featureRow->feature->uniquename;
# 		#push a reference to each row into the loop
# 		push(@formData, \%formRowData);
# 	}
# 	#return a reference to the loop array
# 	return \@formData;
# }

sub _getFormData {
	my $self = shift;
	my $_features = $self->dbixSchema->resultset('Featureprop')->search(
		{
		name => 'genome_of'
		},
		{	join => ['type'],
			select => [qw/me.value type.name/],
			group_by => [qw/me.value type.name/],
			order_by 	=> { -asc => ['me.value']}
		}
		);
	return $_features;
}

sub _hashFormData {
	my $self=shift;
	my $features=shift;
	my @formData;
	while (my $featureRow = $features->next){
		my %formRowData;
		#$formRowData{'FEATUREID'}=$featureRow->feature_id;
		$formRowData{'UNIQUENAME'}=$featureRow->value;
		push(@formData, \%formRowData);
	}
	return \@formData;
}

#TODO: This needs to be tweaked a bit
# sub _getSSMetaInfo {
# 	my $self = shift;
# 	my $_strainName = shift;
# 	my $_sSMetaInfoTable = $self->dbixSchema->resultset('Featureprop');

# 	my $_sSMetaInfo = $_sSMetaInfoTable->search(
# 	{},
# 	#{value => $_strainName},
# 	{
# 		column	=> [ qw/me.feature_id/]
# 	}
# 	);
# 	return $_sSMetaInfo;
#}

# sub _hashSSMetaInfo {
# 	my $self = shift;
# 	my $_sSData = shift;
# 	my @sSMetaInfo;
# 	while (my $sSMetaInfoRow = $_sSData->next){
# 		my %sSMetaRowData;
# 		$sSMetaRowData{'sSFEATUREID'}=$sSMetaInfoRow->feature_id;
# 		push(@sSMetaInfo, \%sSMetaRowData);
# 	}
# 	return \@sSMetaInfo;
# }

sub _getMultiStrainData {
	my $self = shift;
	my $strainFeatureNames = shift;
	my $strainFeaturepropTable = shift;
	my $strainFeatureTable = shift;
	my @multiStrainData;
	my %multiRowData;
	my @multiNestedRowLoop;

	foreach my $multiStrainName (@{$strainFeatureNames}) {

		my $_mSFeatureprops = $strainFeaturepropTable->find({value => "$multiStrainName"});
		my $_mSFeatures = $strainFeatureTable->find({feature_id => $_mSFeatureprops->feature_id});
		
		#Create a hash table and push these keys onto it
		my %multiNestedRow;
		$multiNestedRow{'mSFEATUREID'}=$_mSFeatureprops->feature_id;
		$multiNestedRow{'mSVALUE'}=$_mSFeatureprops->value;
		#$multiNestedRow{'mSRESIDUES'}=$_mSFeatures->residues;
		$multiNestedRow{'mSSEQLENGTH'}=$_mSFeatures->seqlen;
		$multiNestedRow{'mSUNIQUENAME'}=$_mSFeatures->uniquename;
		push(@multiNestedRowLoop, \%multiNestedRow);
	}
	return \@multiNestedRowLoop;
}

sub _getVFData {
	my $self = shift;
	my $_virulenceFactorProperties = $self->dbixSchema->resultset('Featureprop')->search(
		{value => 'Virulence Factor'},
		{
			join		=> ['type', 'feature'],
			select		=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/],
			as 			=> ['feature_id', 'type_id' , 'value' , 'cvterm_id', 'term_name' , 'uniquename'],
			group_by 	=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/ ],
			order_by 	=> { -asc => ['uniquename'] }
		}
		);
	return $_virulenceFactorProperties;
}

#Inputs all column data into a hash table April 29tand returns a reference to the hash table.
#Note: the Cvterms must be defined when up loading sequences to the database otherwise you'll get a NULL exception and the page wont load.
#	i.e. You cannot just upload sequences into the db just into the Feature table without having any terms defined in the Featureprop table.
#	i.e. Fasta files must have attributes tagged to them before uploading.
sub _hashVFData {
	my $self=shift;
	my $_vFactors=shift;
	
	#Initialize an array to hold the loop
	my @vFData;
	
	while (my $vFRow = $_vFactors->next){
		#Initialize a hash structure to store column data in.
		my %vFRowData;
		$vFRowData{'FEATUREID'}=$vFRow->feature_id;
		$vFRowData{'UNIQUENAME'}=$vFRow->feature->uniquename;
		push(@vFData, \%vFRowData);
	}
	#return a reference to the loop array
	return \@vFData;
}

sub _getVFMetaInfo {
	my $self = shift;
	my $_vFFeatureId = shift;

	my @vFMetaData;

	my $_virulenceFactorMetaProperties = $self->dbixSchema->resultset('Featureprop')->search(
		{'me.feature_id' => $_vFFeatureId},
		{
			join		=> ['type' , 'feature'],
			select		=> [ qw/feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/],
			as 			=> ['me.feature_id', 'type_id' , 'value' , 'cvterm_id', 'term_name' , 'uniquename'],
			group_by 	=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/ ],
			order_by	=> { -asc => ['type.name'] }
		}
		);

	while (my $vFMetaRow = $_virulenceFactorMetaProperties->next){
		#Initialize a hash structure to store column data
		my %vFMetaRowData;
		$vFMetaRowData{'vFFEATUREID'}=$vFMetaRow->feature_id;
		$vFMetaRowData{'vFUNIQUENAME'}=$vFMetaRow->feature->uniquename;
		$vFMetaRowData{'vFTERMVALUE'}=$vFMetaRow->value;
		if ($vFMetaRow->type->name eq "description") {
			$vFMetaRowData{'vFTERMNAME'}="Description";
		}
		elsif ($vFMetaRow->type->name eq "keywords"){
			$vFMetaRowData{'vFTERMNAME'}="Keyword";
		}
		elsif ($vFMetaRow->type->name eq "mol_type"){
			$vFMetaRowData{'vFTERMNAME'}="Molecular Type";
		}
		elsif ($vFMetaRow->type->name eq "name"){
			$vFMetaRowData{'vFTERMNAME'}="Factor Name";
		}
		elsif ($vFMetaRow->type->name eq "organism"){
			$vFMetaRowData{'vFTERMNAME'}="Organism";
		}
		elsif ($vFMetaRow->type->name eq "plasmid"){
			$vFMetaRowData{'vFTERMNAME'}="Plasmid name";
		}
		elsif ($vFMetaRow->type->name eq "strain"){
			$vFMetaRowData{'vFTERMNAME'}="Strain";
		}
		elsif ($vFMetaRow->type->name eq "uniquename"){
			$vFMetaRowData{'vFTERMNAME'}="Unique Name";
		}
		else {
			$vFMetaRowData{'vFTERMNAME'}=$vFMetaRow->type->name;
		}
		push(@vFMetaData, \%vFMetaRowData);
	}
	return \@vFMetaData;
}

1;