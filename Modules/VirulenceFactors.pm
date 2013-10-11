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
use Phylogeny::Tree;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
use Carp;
use JSON qw/encode_json/;

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
	my $vFactorsRef = $formDataGenerator->getVirulenceFormData();
	my $amrFactorsRef = $formDataGenerator->getAmrFormData();
	my ($pubDataRef, $priDataRef , $pubStrainJsonDataRef) = $formDataGenerator->getFormData();

	my $template = $self->load_tmpl( 'bioinfo_virulence_factors.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();

	my $username = $self->authen->username;

# Retrieve form data
my ($pub_json, $pvt_json) = $formDataGenerator->genomeInfo($username);

$template->param(public_genomes => $pub_json);
$template->param(private_genomes => $pvt_json) if $pvt_json;

$template->param(FEATURES=>$pubDataRef);
$template->param(strainJSONData=>$pubStrainJsonDataRef);

$template->param(vFACTORS=>$vFactorsRef);
$template->param(amrFACTORS=>$amrFactorsRef);
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
my ($vfByStrainRef , $amrByStrainRef , $virStrainTableNamesRef, $amrStrainTableNamesRef); 

#If somehow the user passes an empty strain list or both selected virulence and amr lists are empty
if (!@selectedStrainNames || !@selectedVirulenceFactors && !@selectedAmrGenes) {
	return "";
}
else {
	($vfByStrainRef , $virStrainTableNamesRef) = $self->_getVirulenceByStrain(\@selectedStrainNames , \@selectedVirulenceFactors);
	($amrByStrainRef , $amrStrainTableNamesRef) = $self->_getAmrByStrain(\@selectedStrainNames , \@selectedAmrGenes);
}
my %strainHash;
$strainHash{'virStrains'} = $virStrainTableNamesRef;
$strainHash{'amrStrains'} = $amrStrainTableNamesRef;
my @arr;
push (@arr , \%strainHash , $vfByStrainRef , $amrByStrainRef);
$virAmrByStrainJSONref = $formDataGenerator->_getJSONFormat(\@arr) or die "$!\n";
return $virAmrByStrainJSONref;
}

sub vf_meta_info : Runmode {
	my $self = shift;
	my $_vFFeatureId = shift;
	
	my $q = $self->query();
	$_vFFeatureId = $q->param("VFName") unless $_vFFeatureId;
	my @virMetaData;

	my $_virulenceFactorMetaProperties = $self->dbixSchema->resultset('Featureprop')->search(
		{'me.feature_id' => $_vFFeatureId},
		{
		#result_class => 'DBIx::Class::ResultClass::HashRefInflator',
		join		=> ['type' , 'feature'],
		columns		=> [ qw/feature_id me.value type.name feature.uniquename feature.name/],
		order_by	=> { -asc => ['type.name'] }
	}
	);

	my $vFMetaFirstRow = $_virulenceFactorMetaProperties->first;
	my %vFMetaFirst;

	$vFMetaFirst{'feature_id'} = $vFMetaFirstRow->feature->feature_id;
	$vFMetaFirst{'uniquename'} = $vFMetaFirstRow->feature->uniquename;
	$vFMetaFirst{'gene_name'} = $vFMetaFirstRow->feature->name;

	push(@virMetaData , \%vFMetaFirst);

	while (my $vFMetaRow = $_virulenceFactorMetaProperties->next){
	#Initialize a hash structure to store column data
	my %vFMetaRowData;
	if ($vFMetaRow->type->name eq "description") {
		$vFMetaRowData{'term_name'}="Description";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "keywords"){
		$vFMetaRowData{'term_name'}="Type";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "mol_type"){
		$vFMetaRowData{'term_name'}="Molecular Type";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "name"){
		$vFMetaRowData{'term_name'}="Factor Name";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "organism"){
		$vFMetaRowData{'term_name'}="Organism";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "plasmid"){
		$vFMetaRowData{'term_name'}="Plasmid name";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "strain"){
		$vFMetaRowData{'term_name'}="Strain";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "uniquename"){
		$vFMetaRowData{'term_name'}="Unique Name";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	elsif ($vFMetaRow->type->name eq "virulence_id"){
		$vFMetaRowData{'term_name'}="Virulence ID";
		$vFMetaRowData{'value'}=$vFMetaRow->value;
	}
	else {
	}
	push(@virMetaData, \%vFMetaRowData);
}

#my @virMetaData = $_virulenceFactorMetaProperties->all;
my $formDataGenerator = Modules::FormDataGenerator->new();
my $vfMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\@virMetaData);
return $vfMetaInfoJsonRef;
}

=head2 amr_meta_info

=cut
sub amr_meta_info : Runmode {
	my $self = shift;
	my $_amrFeatureId = shift;
	
	my $q = $self->query();
	$_amrFeatureId = $q->param("AMRName") unless $_amrFeatureId;

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

	unless(@_selectedVirulenceFactors) {
		return ("" , \@_selectedStrainNames);
	}

	my @unprunedTableNames;
	my @virulenceTableData;

	my $_dataTable = $self->dbixSchema->resultset('RawVirulenceData');

	# my $_dataTableByVirGene = $_dataTable->search(
	# 	{gene_id => $_selectedVirulenceFactors},
	# 	{
	# 		join => ['gene'],
	# 		select => [qw/me.genome_id me.gene_id me.presence_absence/],
	# 		as 	=> ['genome_id', 'gene_id', 'presence_absence']
	# 	}
	# 	);

	# my %virGene;
	# my @presenceAbsence;

	# my $presenceAbsenceValue = "n/a";

	foreach my $virGeneName (@_selectedVirulenceFactors) {
		my $_dataTableByVirGene = $_dataTable->search(
			{'gene_id' => "$virGeneName"},
			{
				select => [qw/me.genome_id me.gene_id me.presence_absence/],
				as 	=> ['genome_id', 'gene_id', 'presence_absence']
			}
			);

		my %virGene;
		my @presenceAbsence;

		foreach my $strainName (@_selectedStrainNames) {
			my %strainName;
			my %data;
			my $presenceAbsenceValue = "n/a";
			my $_dataRowByStrain = $_dataTableByVirGene->search(
				{'genome_id' => "public_".$strainName},
				{
					column => [qw/genome_id gene_id presence_absence/]
				}
				);
			while (my $_dataRow = $_dataRowByStrain->next) {
				$presenceAbsenceValue = $_dataRow->presence_absence;
			}
			if ($strainName =~ /^(public_)/) {
				$strainName =~ s/(public_)//;
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

	unless(@_selectedAmrFactors) {
		return ("" , \@_selectedStrainNames);
	}

	my @unprunedTableNames;
	my @amrTableData;

	my $_dataTable = $self->dbixSchema->resultset('RawAmrData');

	foreach my $amrGeneName (@_selectedAmrFactors) {
		my $_dataTableByAmrGene = $_dataTable->search(
			{
				'gene_id' => "$amrGeneName"
			},
			{
				select => [qw/me.genome_id me.gene_id me.presence_absence/],
				as 	=> ['genome_id', 'gene_id', 'presence_absence']
			}
		);

		my %amrGene;
		my @presenceAbsence;

		foreach my $strainName (@_selectedStrainNames) {
			my %strainName;
			my %data;
			my $presenceAbsenceValue = "n/a";
			my $_dataRowByStrain = $_dataTableByAmrGene->search(
				{
					'genome_id' => "public_".$strainName
				},
				{
					column => [qw/strain gene_id presence_absence/]
				}
			);
			
			while (my $_dataRow = $_dataRowByStrain->next) {
				$presenceAbsenceValue = $_dataRow->presence_absence;
			}
			
			if ($strainName =~ /^(public_)/) {
				$strainName =~ s/(public_)//;
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

=head2 view



=cut

sub view : Runmode {
	my $self = shift;
	
	# Params 
	my $q = $self->query();
	my $qgene;
	my $qtype;
	if($q->param('amr')) {
		$qtype='amr';
		$qgene = $q->param('amr');
	} elsif($q->param('vf')) {
		$qtype='vf';
		$qgene = $q->param('vf');
	}
	my @genomes = $q->param("genome");
	
	croak "Error: no query gene parameter." unless $qgene;
	
	
	# Data object
	my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema);
	
	# User
	my $user = $self->authen->username;
	

	# Validate gene and retrieve gene information
	my $qgene_info;
	if($qtype eq 'amr') {
		$qgene_info = $self->amr_meta_info($qgene);
	} elsif($qtype eq 'vf') {
		$qgene_info = $self->vf_meta_info($qgene);
	}
	
	# Validate genomes
	my %visable_genomes;
	my $subset_genomes = 0;
	if(@genomes) {
		$subset_genomes = 1;
		my @private_ids = map m/private_(\d+)/ ? $1 : (), @genomes;
		my @public_ids = map m/public_(\d+)/ ? $1 : (), @genomes;
		
		croak "Error: one or more invalid genome parameters." unless ( scalar(@private_ids) + scalar(@public_ids) == scalar(@genomes) );
		
		# Retrieve genome names accessible to user
		my $public_genomes = $data->publicGenomes(\@public_ids);
		my $private_genomes = $data->privateGenomes($user, \@private_ids);
		
		foreach my $g (@$public_genomes) {
			$visable_genomes{'public_'.$g->{feature_id}} = $g->{uniquename};
		}
		foreach my $g (@$private_genomes) {
			$visable_genomes{'private_'.$g->{feature_id}} = $g->{uniquename};
		}
		
		unless(keys %visable_genomes) {
			# User requested strains that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@private_ids) );
			return $self->redirect( $self->home_page );
		}
		
	} else {
		# Default is to show all viewable genomes
		my $public_genomes = $data->publicGenomes();
		my $private_genomes = $data->privateGenomes($user);
		
		foreach my $g (@$public_genomes) {
			$visable_genomes{'public_'.$g->{feature_id}} = $g->{uniquename};
		}
		foreach my $g (@$private_genomes) {
			$visable_genomes{'private_'.$g->{feature_id}} = $g->{uniquename};
		}
	}
	
	# Template
	my $template = $self->load_tmpl( 'query_gene_view.tmpl' , die_on_bad_params => 0);
	
	if($qtype eq 'amr') {
		$template->param(amr => 1);
	} elsif($qtype eq 'vf') {
		$template->param(vf => 1);
	}
	$template->param(gene_info => $qgene_info);
	
	# Retrieve presence / absence
	my @lookup_genomes = keys %visable_genomes;
	my $all_alleles = $self->_getResidentGenomes([$qgene], $qtype, \@lookup_genomes, $subset_genomes, 0);
	my $gene_alleles; 
	
	if(%$all_alleles) {
		$gene_alleles = $all_alleles->{$qgene};
		my $allele_json = encode_json($gene_alleles); # Only encode the lists for the gene we need
		$template->param(allele_json => $allele_json);
	}
	
	my $num_alleles = 0;
	$num_alleles = scalar(@{$gene_alleles->{present}}) if $gene_alleles && $gene_alleles->{present};
	
	get_logger->debug('Number of alleles found:'.$num_alleles);
	
	# Retrieve tree
	if($num_alleles > 2) {
		my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
		my $tree_string = $tree->geneTree($qgene, 1, \%visable_genomes);
		$template->param(tree_json => $tree_string);
	}
	
	# Retrieve meta info
	my ($pub_json, $pvt_json) = $data->genomeInfo($user);
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;

	
	# Retrieve MSA
	if($num_alleles > 1) {
		my $msa_json = $data->seqAlignment($qgene, \%visable_genomes);
		$template->param(msa_json => $msa_json) if($msa_json);
	}
	
	return $template->output();
}

=head2 _getResidentGenomes

Obtain genome feature IDs that contain
a VF or AMR allele.

Changes are needed with amr/vf tables are
upgraded to handle private/public

=cut

sub _getResidentGenomes {
	my $self = shift;
	my $markers_ref = shift;
	my $marker_type = shift;
	my $genomes_ref = shift;
	my $incl_absent = shift;
	my $tabular     = shift;
	
#	$self->dbixSchema->storage->debug(1);
#	$self->dbixSchema->storage->debugfh(IO::File->new('/tmp/trace.out', 'w'));
	
	# Convert to public/private notation
	# Assume that in future, can distinguish which genome_id are public and private
	
	my $rs;
	if($marker_type eq 'amr') {
		$rs = 'RawAmrData';
	} elsif($marker_type eq 'vf') {
		$rs = 'RawVirulenceData';
	} else {
		croak "[Error] unrecognized marker type: $marker_type.\n";
	}
	
	my $select = {
		'gene_id' => { '-in' => $markers_ref }
	};
	if($genomes_ref) {
		$select->{genome_id} = { '-in' => $genomes_ref };
	}
	
	my $allele_rs = $self->dbixSchema->resultset($rs)->search($select);
	
	if($tabular) {
		# Tabular format
		
		# Setup indices
		my %col;
		my $i = 0;
		my @empty = ('n/a') x scalar(@$genomes_ref);
		foreach my $gn (@$genomes_ref) {
			$col{$gn} = $i++;
		}
		
		# Setup emtpy matrix;
		my %matrix;
		foreach my $marker (@$markers_ref) {
			$matrix{$marker} = [@empty];
		}
		
		# Fill in values
		while(my $allele_row = $allele_rs->next) {
			my $gene = $allele_row->gene_id;
		
			$matrix{$gene}->[$col{$allele_row->genome_id}] = $allele_row->presence_absence;
		}
		
		return(\%matrix);
		
	} else {
		# List format
		
		my %alleles;
		while(my $allele_row = $allele_rs->next) {
			if($allele_row->presence_absence == 1) {
				$alleles{$allele_row->gene_id}{'present'} = [] unless defined $alleles{$allele_row->gene_id}{'present'};
				push @{$alleles{$allele_row->gene_id}{'present'}}, $allele_row->genome_id;
			} elsif($incl_absent) {
				$alleles{$allele_row->gene_id}{'absent'} = [] unless defined $alleles{$allele_row->gene_id}{'absent'};
				push @{$alleles{$allele_row->gene_id}{'absent'}}, $allele_row->genome_id;
			}
		}
		
		return \%alleles;
	}
	
}

=head2 binaryMatrix


=cut

sub binaryMatrix : RunMode {
	my $self = shift;
	
	# Params
	my $q = $self->query();
	my @genomes = $q->param("selectedStrains");
	my @vf = $q->param("selectedVirulence");
	my @amr = $q->param("selectedAmr");
	
	# Data object
	my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema);
	
	# User
	my $user = $self->authen->username;
	
	
	# Validate inputs
	
	# empty?
	return '' unless(@genomes && (@vf || @amr));
	
	# validate genomes
	my @private_ids = map m/private_(\d+)/ ? $1 : (), @genomes;
	my @public_ids = map m/public_(\d+)/ ? $1 : (), @genomes;
			
	croak "Error: one or more invalid genome parameters." unless ( scalar(@private_ids) + scalar(@public_ids) == scalar(@genomes) );
		
	# check user can view genomes
	my $ok = $data->verifyMultipleAccess($user, @private_ids) if @private_ids;
	
	# visable genomes
	my @lookup_genomes;
	
	foreach my $id (@public_ids) {
		push @lookup_genomes, 'public_' . $id;
	}
	if(@private_ids) {
		foreach my $id (keys %$ok) {
			push @lookup_genomes, 'private_' . $id if $ok->{$id};
		}
	}
	
	unless(@lookup_genomes) {
		# User requested strains that they do not have permission to view
		$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@private_ids) );
		return $self->redirect( $self->home_page );
	}
	
	get_logger->debug('Retrieving alleles for genomes: '.join(', ', @lookup_genomes));
	
	# Get presence/absence
	# Save as mega-hash
	my %results;
	if(@vf) {
		my $vf_matrix = $self->_getResidentGenomes(\@vf, 'vf', \@lookup_genomes, 1, 1);
		
		$results{vf} = $vf_matrix;
	}
	
	if(@amr) {
		my $amr_matrix = $self->_getResidentGenomes(\@amr, 'amr', \@lookup_genomes, 1, 1);
		
		$results{amr} = $amr_matrix;
	}
	
	$results{genome_order} = \@lookup_genomes;
	
	
	return encode_json(\%results);
}

1;
