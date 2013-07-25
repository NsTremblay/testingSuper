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
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
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

	$template->param(vFACTORS=>$vFactorsRef);
	$template->param(vJSON=>$vJsonData);

	$template->param(FEATURES=>$pubDataRef);
	$template->param(strainJSONData=>$pubStrainJsonDataRef);

	$template->param(amrFACTORS=>$amrFactorsRef);
	$template->param(amrJSON=>$amrJsonData);
	return $template->output();
}

=head2 virulenceAmrByStrain

Run mode for selected virulence and amr by strain

=cut

sub virulence_amr_by_strain : Runmode {
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);

	my $q = $self->query();
	my @selectedStrainNames = $q->param("selectedStrains");
	my @selectedVirulenceFactors = $q->param("selectedVirulence");
	my @selectedAmrGenes = $q->param("selectedAmr");

	#my ($vfByStrainJSONref , $amrByStrainJSONref , $strainTableNamesJSONref);
	my $virAmrByStrainJSONref;
	my ($vfByStrainRef , $amrByStrainRef , $strainTableNamesRef); 

	if (!@selectedStrainNames || !@selectedVirulenceFactors || !@selectedAmrGenes) {
		return "";
	}
	else {
		($vfByStrainRef , $strainTableNamesRef) = $self->_getVirulenceByStrain(\@selectedStrainNames , \@selectedVirulenceFactors);
		($amrByStrainRef , $strainTableNamesRef) = $self->_getAmrByStrain(\@selectedStrainNames , \@selectedAmrGenes);
		#($amrByStrainJSONref , $strainTableNamesJSONref) = $formDataGenerator->_getJSONFormat($amrByStrainRef , $strainTableNamesRef) or die "$!\n";
	}
	my %strainHash;
	$strainHash{'strain'} = $strainTableNamesRef;
	my @arr;
	push (@arr , \%strainHash , $vfByStrainRef , $amrByStrainRef);
	$virAmrByStrainJSONref = $formDataGenerator->_getJSONFormat(\@arr) or die "$!\n";
	return $virAmrByStrainJSONref;
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

sub amr_meta_info : Runmode {
	my $self = shift;
	my $q = $self->query();
	my $_amrFeatureId = $q->param("AMRName");

#	my $_amrMetaProperties = $self->dbixSchema->resultset('Cvterm')->search(
#		{'featureprops.feature_id' => $_amrFeatureId},
#		{
#			#result_class => 'DBIx::Class::ResultClass::HashRefInflator',
#			join		=> ['featureprops' , 'feature_cvterms' , 'features'],
#			select		=> [ qw/feature_cvterms.feature_id me.name me.definition features.uniquename featureprops.value/],
#			as 			=> ['feature_id' , 'term_name' , 'term_definition' , 'uniquename' , 'value'],
#			order_by	=> { -asc => ['me.name'] }
#		}
#	);
	
	my $feature_rs = $self->dbixSchema->resultset('Feature')->search(
		{
			'me.feature_id' => $_amrFeatureId
		},
		{
			#result_class => 'DBIx::Class::ResultClass::HashRefInflator',
			join => [
				'type',
				{ featureprops => 'type' },
				{ feature_cvterms => { cvterm => 'dbxref'}}
			],
			#select		=> [ qw/feature_cvterms.feature_id me.name me.definition features.uniquename featureprops.value/],
			#as 			=> ['feature_id' , 'term_name' , 'term_definition' , 'uniquename' , 'value'],
			order_by	=> { -asc => ['me.name'] }
		}
	);
	
	
	my $frow = $feature_rs->first;
	die "Error: feature $_amrFeatureId is not of antimicrobial resistance gene type (feature type: ".$frow->type->name.").\n" unless $frow->type->name eq 'antimicrobial_resistance_gene';
	
	my @desc;
	my @syn;
	my @aro;
	
	my $fp_rs = $frow->featureprops;
	
	while(my $fprow = $fp_rs->next) {
		if($fprow->type->name eq 'description') {
			push @desc, $fprow->value;
		} elsif($fprow->type->name eq 'synonym') {
			push @syn, $fprow->value;
		}
	}
	
	my $fc_rs = $frow->feature_cvterms;
	
	while(my $fcrow = $fc_rs->next) {
		my $aro_entry = {
			accession => 'ARO:'.$fcrow->cvterm->dbxref->accession,
			term_name => $fcrow->cvterm->name,
			term_defn => $fcrow->cvterm->definition
		};
		push @aro, $aro_entry;
	}
	
	my %data_hash = (
		name => $frow->uniquename,
		descriptions  => \@desc,
		synonyms     => \@syn,
		aro_terms    => \@aro
	);
	
	my $formDataGenerator = Modules::FormDataGenerator->new();
	my $amrMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\%data_hash);
	return $amrMetaInfoJsonRef;

}

sub _getVirulenceByStrain {
	my $self = shift;
	my $_selectedStrainNames = shift;
	my $_selectedVirulenceFactors = shift;

	my @_selectedStrainNames = @{$_selectedStrainNames};
	my @_selectedVirulenceFactors = @{$_selectedVirulenceFactors};
	
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
			$strainName{'strain_name'} = $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainName})->uniquename;
			push (@unprunedTableNames , \%strainName);
			$data{'value'} = $presenceAbsenceValue;
			push (@presenceAbsence , \%data);
		}
		$virGene{'presence_absence'} = \@presenceAbsence;
		$virGene{'gene_name'} = $self->dbixSchema->resultset('Feature')->find({'feature_id' => $virGeneName})->name . ' - ' .  $self->dbixSchema->resultset('Feature')->find({'feature_id' => $virGeneName})->uniquename ;
		push (@virulenceTableData, \%virGene);
	}
	my @strainTableNames = @unprunedTableNames[0..scalar(@_selectedStrainNames)-1];
	my %virluenceHash;
	$virluenceHash{'virulence'} = \@virulenceTableData;
	return (\%virluenceHash, \@strainTableNames);
}

sub _getAmrByStrain {
	my $self = shift;
	my $_selectedStrainNames = shift;
	my $_selectedAmrFactors = shift;

	my @_selectedStrainNames = @{$_selectedStrainNames};
	my @_selectedAmrFactors = @{$_selectedAmrFactors};

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
			$strainName{'strain_name'} = $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainName})->uniquename;
			push (@unprunedTableNames , \%strainName);
			$data{'value'} = $presenceAbsenceValue;
			push (@presenceAbsence , \%data);
		}
		$amrGene{'presence_absence'} = \@presenceAbsence;
		$amrGene{'gene_name'} = $self->dbixSchema->resultset('Feature')->find({'feature_id' => $amrGeneName})->uniquename;
		push (@amrTableData, \%amrGene);
	}
	my @strainTableNames = @unprunedTableNames[0..scalar(@_selectedStrainNames)-1];
	my %amrHash;
	$amrHash{'amr'} = \@amrTableData;
	return (\%amrHash , \@strainTableNames);
}

1;
