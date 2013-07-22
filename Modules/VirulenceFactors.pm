#!/usr/bin/env perl

=pod

=head1 NAME

Modules::VirulenceFactors

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Matthew Whiteside, for all their assistance on this project

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::VirulenceFactors;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;;

use Log::Log4perl;
use Carp;

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::VirulenceFactors");
}

=head2 virulenceFactors

Run mode for the virulence factor page

=cut

sub virulence_factors : StartRunmode {
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	my ($vFactorsRef , $vJsonData) = $formDataGenerator->getVirulenceFormData();
	my ($amrFactorsRef , $amrJsonData) = $formDataGenerator->getAmrFormData();
	my ($pubDataRef, $priDataRef , $pubStrainJsonDataRef) = $formDataGenerator->getFormData();

	my $template = $self->load_tmpl( 'bioinfo_virulence_factors.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my $vfFeatureId = $q->param("VFName");
	my $amrFeatureId = $q->param("AMRName");

	$template->param(vFACTORS=>$vFactorsRef);
	$template->param(vJSON=>$vJsonData);

	$template->param(FEATURES=>$pubDataRef);
	$template->param(strainJSONData=>$pubStrainJsonDataRef);

	$template->param(amrFACTORS=>$amrFactorsRef);
	$template->param(amrJSON=>$amrJsonData);

	if ((!defined $vfFeatureId || $vfFeatureId eq "") && (!defined $amrFeatureId || $amrFeatureId eq "")){
	}
	elsif (defined $amrFeatureId || $amrFeatureId ne "") {
		my $vFMetaInfoRef = $self->_getVFMetaInfo($vfFeatureId);
		my $amrMetaInfoRef = $self->_getAMRMetaInfo($amrFeatureId);
		my $validator = "Return Success";
		$template->param(amrVALIDATOR=>$validator);
		$template->param(amrMETAINFO=>$amrMetaInfoRef);
	}
	else {
		my $vFMetaInfoRef = $self->_getVFMetaInfo($vfFeatureId);
		my $amrMetaInfoRef = $self->_getAMRMetaInfo($amrFeatureId);
		my $validator = "Return Success";
		$template->param(vfVALIDATOR=>$validator);
		$template->param(vFMETAINFO=>$vFMetaInfoRef);
	}	
	return $template->output();
}

=head2 virulenceAmrByStrain

Run mode for selected virulence and amr by strain

=cut

sub virulenceAmrByStrain {
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	my ($vFactorsRef , $vJsonData) = $formDataGenerator->getVirulenceFormData();
	my ($amrFactorsRef , $amrJsonData)= $formDataGenerator->getAmrFormData();
	my ($pubDataRef, $priDataRef) = $formDataGenerator->getFormData();

	my $template = $self->load_tmpl( 'bioinfo_virulence_factors.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my @selectedStrainNames = $q->param("selectedStrains");
	my @selectedVirulenceFactors = $q->param("selectedVirulence");
	my @selectedAmrGenes = $q->param("selectedAmr");

	$template->param(vFACTORS=>$vFactorsRef);
	$template->param(vJSON=>$vJsonData);
	
	$template->param(FEATURES=>$pubDataRef);

	$template->param(amrFACTORS=>$amrFactorsRef);
	$template->param(amrJSON=>$amrJsonData);

	if (!@selectedStrainNames || (!@selectedVirulenceFactors && !@selectedAmrGenes)) {
		# do nothing because either strain list is empty or the user didnt specify any virulence or amr factors
	}
	else {
		my ($vfByStrainRef , $strainTableNamesRef) = $self->_getVirulenceByStrain(\@selectedStrainNames , \@selectedVirulenceFactors);
		my ($amrByStrainRef , $strainTableNamesRef) = $self->_getAmrByStrain(\@selectedStrainNames , \@selectedAmrGenes);
		$template->param(vFACTORSBYSTRAIN=>$vfByStrainRef);
		$template->param(amrFACTORSBYSTRAIN=>$amrByStrainRef);
		$template->param(STRAINTABLENAMES=>$strainTableNamesRef);
	}
	return $template->output();
}

=head2 _getVFMetaInfo

Queries the database for a virulence factor feature_id.
Returns an array reference containing the virulence factor meta info

=cut

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
		elsif ($vFMetaRow->type->name eq "biological_process"){
			$vFMetaRowData{'vFTERMNAME'}="Biological Process";
		}
		else {
			$vFMetaRowData{'vFTERMNAME'}=$vFMetaRow->type->name;
		}
		push(@vFMetaData, \%vFMetaRowData);
	}
	return \@vFMetaData;
}

sub vf_meta_info : Runmode {
	my $self = shift;
	my $q = $self->query();
	my $_vFFeatureId = $q->param("VFName");

	my $_virulenceFactorMetaProperties = $self->dbixSchema->resultset('Featureprop')->search(
		{'me.feature_id' => $_vFFeatureId},
		{
			result_class => 'DBIx::Class::ResultClass::HashRefInflator',
			join		=> ['type' , 'feature'],
			select		=> [ qw/feature_id me.value type.name feature.uniquename/],
			as 			=> ['me.feature_id' , 'value' , 'term_name' , 'uniquename'],
			group_by 	=> [ qw/me.feature_id me.value type.name feature.uniquename/ ],
			order_by	=> { -asc => ['type.name'] }
		}
		);

	my @virMetaData = $_virulenceFactorMetaProperties->all;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	my $vfMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\@virMetaData);
	return $vfMetaInfoJsonRef;
}

=head2 _getAMRMetaInfo

Queries the database for an AMR gene feature_id.
Returns an array reference containing the virulence factor meta info.

=cut

sub _getAMRMetaInfo {
	my $self = shift;
	my $_amrFeatureId = shift;

	my @amrMetaData;

	my $_amrFactorMetaProperties = $self->dbixSchema->resultset('Featureprop')->search(
		{'me.feature_id' => $_amrFeatureId},
		{
			join		=> ['type' , 'feature'],
			select		=> [ qw/feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/],
			as 			=> ['me.feature_id', 'type_id' , 'value' , 'cvterm_id', 'term_name' , 'uniquename'],
			group_by 	=> [ qw/me.feature_id me.type_id me.value type.cvterm_id type.name feature.uniquename/ ],
			order_by	=> { -asc => ['type.name'] }
		}
		);

	while (my $amrMetaRow = $_amrFactorMetaProperties->next) {
		my %amrMetaRowData;
		$amrMetaRowData{'amrFEATUREID'} = $amrMetaRow->feature_id;
		$amrMetaRowData{'amrUNIQUENAME'} = $amrMetaRow->feature->uniquename;
		$amrMetaRowData{'amrTERMVALUE'} = $amrMetaRow->value;
		if ($amrMetaRow->type->name eq "description") {
			$amrMetaRowData{'amrTERMNAME'}="Description";
		}
		elsif ($amrMetaRow->type->name eq "organism"){
			$amrMetaRowData{'amrTERMNAME'}="Organism";
		}
		elsif ($amrMetaRow->type->name eq "keywords"){
			$amrMetaRowData{'amrTERMNAME'}="Keyword";
		}
		else {
			$amrMetaRowData{'amrTERMNAME'}=$amrMetaRow->type->name;
		}
		push(@amrMetaData , \%amrMetaRowData);
	}
	return \@amrMetaData;
}

sub amr_meta_info : Runmode {
	my $self = shift;
	my $q = $self->query();
	my $_amrFeatureId = $q->param("AMRName");

	my $_amrMetaProperties = $self->dbixSchema->resultset('FeatureCvterm')->search(
		{'me.feature_id' => $_amrFeatureId},
		{
			result_class => 'DBIx::Class::ResultClass::HashRefInflator',
			join		=> ['cvterm' , 'feature'],
			select		=> [ qw/feature_id cvterm.name cvterm.definition feature.uniquename/],
			as 			=> ['me.feature_id' , 'term_name' , 'term_definition' , 'uniquename'],
			order_by	=> { -asc => ['cvterm.name'] }
		}
		);

	my @amrMetaData = $_amrMetaProperties->all;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	my $amrMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\@amrMetaData);
	return $amrMetaInfoJsonRef;
}

sub _getVirulenceByStrain {
	my $self = shift;
	my $_selectedStrainNames = shift;
	my $_selectedVirulenceFactors = shift;

	my @_selectedStrainNames = @{$_selectedStrainNames};
	my @_selectedVirulenceFactors = @{$_selectedVirulenceFactors};

	my @strainTableNames;
	my @unprunedTableNames;
	my @virulenceTableData;

	my $_dataTable = $self->dbixSchema->resultset('RawVirulenceData');

	foreach my $virGeneName (@_selectedVirulenceFactors) {
		my $_dataTableByVirGene = $_dataTable->search(
			{'gene_name' => "$virGeneName"},
			{
				select => [qw/me.strain me.gene_name me.presence_absence/],
				as 	=> ['strain', 'gene_name', 'presence_absence']
			}
			);

		my %virGene;
		my @presenceAbsence;

		foreach my $strainName (@_selectedStrainNames) {
			my %strainName;
			my %data;
			my $presenceAbsenceValue = "Unknown";
			my $_dataRowByStrain = $_dataTableByVirGene->search(
				{'strain' => "$strainName"},
				{
					column => [qw/strain gene_name presence_absence/]
				}
				);
			while (my $_dataRow = $_dataRowByStrain->next) {
				$presenceAbsenceValue = $_dataRow->presence_absence;
			}
			$strainName{'strain_name'} = $strainName;
			push (@unprunedTableNames , \%strainName);
			$data{'value'} = $presenceAbsenceValue;
			push (@presenceAbsence , \%data);
		}
		$virGene{'presence_absence'} = \@presenceAbsence;
		$virGene{'gene_name'} = $virGeneName;
		push (@virulenceTableData, \%virGene);
	}
	my @strainTableNames = @unprunedTableNames[0..scalar(@_selectedStrainNames)-1];
	return (\@virulenceTableData , \@strainTableNames);
}

sub _getAmrByStrain {
	my $self = shift;
	my $_selectedStrainNames = shift;
	my $_selectedAmrFactors = shift;

	my @_selectedStrainNames = @{$_selectedStrainNames};
	my @_selectedAmrFactors = @{$_selectedAmrFactors};

	my @strainTableNames;
	my @unprunedTableNames;
	my @amrTableData;

	my $_dataTable = $self->dbixSchema->resultset('RawAmrData');

	foreach my $amrGeneName (@_selectedAmrFactors) {
		my $_dataTableByAmrGene = $_dataTable->search(
			{'gene_name' => "$amrGeneName"},
			{
				select => [qw/me.strain me.gene_name me.presence_absence/],
				as 	=> ['strain', 'gene_name', 'presence_absence']
			}
			);

		my %amrGene;
		my @presenceAbsence;

		foreach my $strainName (@_selectedStrainNames) {
			my %strainName;
			my %data;
			my $presenceAbsenceValue = "Unknown";
			my $_dataRowByStrain = $_dataTableByAmrGene->search(
				{'strain' => "$strainName"},
				{
					column => [qw/strain gene_name presence_absence/]
				}
				);
			while (my $_dataRow = $_dataRowByStrain->next) {
				$presenceAbsenceValue = $_dataRow->presence_absence;
			}
			$strainName{'strain_name'} = $strainName;
			push (@unprunedTableNames , \%strainName);
			$data{'value'} = $presenceAbsenceValue;
			push (@presenceAbsence , \%data);
		}
		$amrGene{'presence_absence'} = \@presenceAbsence;
		$amrGene{'gene_name'} = $amrGeneName;
		push (@amrTableData, \%amrGene);
	}
	my @strainTableNames = @unprunedTableNames[0..scalar(@_selectedStrainNames)-1];
	return (\@amrTableData , \@strainTableNames);
}

1;
