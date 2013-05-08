#!/usr/bin/perl

=pod

=head1 NAME

Modules::VirulenceFactors

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Michael Whiteside, for all their assistance on this project

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

use Log::Log4perl;
use Carp;

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::VirulenceFactors");
	$self->start_mode('default');
	$self->run_modes(
		'default'=>'default',
		'virulence_factors'=>'virulenceFactors'
		);
}

=head2 default

Default start mode. Must be decalared or CGI:Application will die. 

=cut

sub default {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

=head2 virulenceFactors

Run mode for the virulence factor page

=cut

sub virulenceFactors {
	my $self = shift;
	my $vFactorsRef = $self->_getVirulenceFactors();
	my $template = $self->load_tmpl( 'bioinfo_virulence_factors.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my $vfFeatureId = $q->param("VFName");

	if (!defined $vfFeatureId || $vfFeatureId eq ""){
		$template->param(vFACTORS=>$vFactorsRef);
	}
	else {
		my $vFMetaInfoRef = $self->_getVFMetaInfo($vfFeatureId);
		$template->param(vFACTORS=>$vFactorsRef);
		my $validator = "Return Success";
		$template->param(VALIDATOR=>$validator);
		$template->param(vFMETAINFO=>$vFMetaInfoRef);
	}	
	return $template->output();
}

=head2 _getVirulenceFactors

Queries the database for all the available virulence factors or their meta info.
Returns an array reference of virulence factors or the meta info of a virulence factor.

=cut

sub _getVirulenceFactors {
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
	$self->_hashVirulenceFactors($_virulenceFactorProperties);
}

=head2 _hashVirulenceFactors

Inputs all column data into a hash table and returns a reference to the hash table.
Note: the Cvterms must be defined when up-loading sequences to the database otherwise you'll get a NULL exception and the page wont load.
	i.e. You cannot just upload sequences into the db just into the Feature table without having any terms defined in the Featureprop table.
	i.e. Fasta files must have attributes tagged to them before uploading.

=cut

sub _hashVirulenceFactors {
	my $self=shift;
	my $_virulenceFactorProperties = shift;

	my @virulenceFactors;
	
	while (my $vFRow = $_virulenceFactorProperties->next){
		my %vFRowData;
		$vFRowData{'FEATUREID'}=$vFRow->feature_id;
		$vFRowData{'UNIQUENAME'}=$vFRow->feature->uniquename;
		push(@virulenceFactors, \%vFRowData);
	}
	return \@virulenceFactors;
}

=head2

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
		else {
			$vFMetaRowData{'vFTERMNAME'}=$vFMetaRow->type->name;
		}
		push(@vFMetaData, \%vFMetaRowData);
	}
	return \@vFMetaData;
}

1;
