#!/usr/bin/env perl

=pod

=head1 NAME

Modules::Genes

=head1 DESCRIPTION

For display of Virulence factors, AMR genes and Stx typing data

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)
Matthew Whiteside (matthew.whiteside@phac-aspc.gov.ca)

=cut

package Modules::Genes;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use Modules::GenomeWarden;
use Phylogeny::Tree;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
use Carp;
use JSON;
use Data::Dump qw(dump);

sub setup {
	my $self=shift;

}

=head2 stx

Summary of stx subtypes across genomes

=cut

sub stx : Runmode {
	my $self = shift;
	
	# Params
	my $query = $self->query();
	
	my @genomes = $query->param("genome");

	# Data object
	my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema);
	
	# User
	my $user = $self->authen->username;
	
	# Obtain reference typing sequence
	my @subunits;
	foreach my $uniquename (qw/stx1_subunit stx2_subunit/) {
		my $refseq = $self->dbixSchema->resultset('Feature')->find(
			{
				uniquename => $uniquename
			}
		);
		my $ref_id = $refseq->feature_id;
		push @subunits, $ref_id;
	}
	
	# Validate genomes
	my $warden;
	if(@genomes) {
		
		$warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, genomes => \@genomes, user => $user);
		my ($err, $bad1, $bad2) = $warden->error; 
		if($err) {
			# User requested invalid strains or strains that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@$bad1, @$bad2) );
			return $self->redirect( $self->home_page );
		}
		
	} else {
		
		$warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, user => $user);
	}
	
	# Template
	my $template = $self->load_tmpl('genes_stx.tmpl' , die_on_bad_params => 0);
	
	# Retrieve presence / absence
	my $results = _genomeStx($data, \@subunits, $warden);
	
	my $stx = $results->{stx};
	my $locus_data = $results->{alleles};
	my $stx_json = encode_json($stx);
	my $locus_json = encode_json($locus_data);
	$template->param(stx_json => $stx_json);
	$template->param(locus_json => $locus_json);
	
	# Retrieve meta info
	my ($pub_json, $pvt_json) = $data->genomeInfo($user);
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	# Trees / MSA for each subunit
	my $stx_names = $results->{names};
	get_logger->debug(dump($stx_names));
	foreach my $ref_id (@subunits) {
		my $key = $stx_names->{$ref_id};
		my $num_alleles = $results->{counts}->{$key};
		
		# Retrieve tree
		if($num_alleles > 2) {
			my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
			my $tree_string = $tree->geneTree($ref_id, 1, $warden->genomeLookup());
			my $param = "$key\_tree";
			$template->param($param => $tree_string);
		}
		
		# Retrieve MSA
		if($num_alleles > 1) {
			my $is_typing = 1;
			my $msa = $data->seqAlignment2(
				locus => $ref_id, 
				warden => $warden,
				typing => $is_typing
			);
			if($msa) {
				my $param = "$key\_msa";
				my $msa_json = encode_json($msa);
				$template->param($param => $msa_json);
			}
		}
		
	}
		
	return $template->output();
}

=head2 _genomeStx

Obtain genome feature IDs and subtype
for genomes that contain an Stx typing sequence.

=cut

sub _genomeStx {
	my $fdg         = shift;
	my $subunit_ids = shift;
	my $warden      = shift;
	
	my %args;
	$args{warden} = $warden;
	$args{markers} = $subunit_ids;
	
	my $result_hash = $fdg->getStxData(%args);

	# List format
	my %stx_lists;
	my %stx_counts;
	my %stx_alleles;
	my $stx_hash = $result_hash->{stx};
	my $stx_names = $result_hash->{names};
	my @genome_list;
	
	foreach my $g (keys %$stx_hash) {
		push @genome_list, $g;
		
		foreach my $r_id (@$subunit_ids) {
			
			my $subu = $stx_names->{$r_id};
			my $num = 0;
				
			if(defined($stx_hash->{$g})) {
				# genome has some subtypes
				if(defined($stx_hash->{$g}->{$r_id})) {
					# genome has subtype for this ref gene
					my @subt;
					my $copy = 1;
					foreach my $hr (sort @{$stx_hash->{$g}->{$r_id}}) {
						push @subt, $hr->{subtype};
						my $h = "$g|".$hr->{allele};
						my $allele_data = "";
						$allele_data .= "(copy $copy)" if $copy > 1;
						my $st = $hr->{subtype};
						if($st eq 'multiple') {
							$st = 'multiple subtypes predicted'
						} else {
							$st = " - Stx".$st;
						}
						$allele_data .= $st;
						$stx_alleles{$h} = $allele_data;
						$copy++;
					}
					$num = @subt;
					
					for(my $i=0; $i < @subt; $i++) {
						if($subt[$i] eq 'multiple') {
							$subt[$i] = 'multiple subtypes predicted'
						} else {
							$subt[$i] = 'Stx'.$subt[$i]
						}
					}
					
					$stx_lists{$subu}->{$g} = ' - '.join(', ',@subt);
				} else {
					# genome does not have stx for this ref gene
					$stx_lists{$subu}->{$g} = ' - NA';
				}
			} else {
				# genome has no stx
				$stx_lists{$subu}->{$g} = ' - NA';
			}
			
			$stx_counts{$subu} += $num;
		}
	}
		
	return { stx => \%stx_lists, genome_list => \@genome_list, counts => \%stx_counts, names => $stx_names, alleles => \%stx_alleles };
}


# NOTHING BEYOND THIS POINT HAS BEEN UPDATED

=head2 virulenceFactors

Run mode for the virulence factor page

=cut

sub virulence_factors : StartRunmode {
	my $self = shift;
	
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	
	
	#my ($pubDataRef, $priDataRef , $pubStrainJsonDataRef) = $formDataGenerator->getFormData();

	my $template = $self->load_tmpl( 'virulence_amr.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();

	my $username = $self->authen->username;

	# Retrieve form data
	my ($pub_json, $pvt_json) = $formDataGenerator->genomeInfo($username);
	my $vFactorsRef = $formDataGenerator->getVirulenceFormData();
	my $amrFactorsRef = $formDataGenerator->getAmrFormData();
	
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	$template->param(vFACTORS=>$vFactorsRef);
	$template->param(amrFACTORS=>$amrFactorsRef);
	
	my $amrCategoriesRef = $self->categories();
	$template->param(Categories=>$amrCategoriesRef);
	
	return $template->output();
}

=head2 virulenceAmrByStrain

Run mode for selected virulence and amr by strain



sub virulence_amr_by_strain : Runmode {
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);

	my $q = $self->query();
	my @selectedStrainNames = $q->param("selectedPubGenomesList");
	my @selectedVirulenceFactors = $q->param("selectedVirList");
	my @selectedAmrGenes = $q->param("selectedAmrList");

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
=cut


sub categories : Runmode {
	#Testing out categories
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	my $q = $self->query();

	# my @wantedCategories = (
	# 	'pathogenesis'
	# 	);

	# my $vfCategoryResults = $self->dbixSchema->resultset('Cvterm')->search(
	# 	{'me.name' => \@wantedCategories},
	# 	{
	# 		join => [{'cvterm_relationship_objects' => {'subject' => {'cvterm_relationship_objects' => 'subject'}}}],
	# 		select => ['me.cvterm_id', 'me.name', 'subject.cvterm_id', 'subject.name', 'subject_2.cvterm_id', 'subject_2.name'],
	# 		as => ['matriarch_category_id', 'matriarch_category_name', 'broad_category_id', 'broad_category_name', 'refined_category_id', 'refined_category_name']
	# 	}
	# 	);

	# my @wantedCategories = (
	# 'antibiotic molecule',
	# 'determinant of antibiotic resistance',
	# 'antibiotic target',
	# );

	# my $categoryResults = $self->dbixSchema->resultset('Cvterm')->search(
	# 	{'dbxref.accession' => '1000001', 'subject.name' => \@wantedCategories},
	# 	{
	# 		join => [
	# 		'dbxref',
	# 		{'cvterm_relationship_objects' => {'subject' => [{'cvterm_relationship_objects' => 'subject'}, 'dbxref']}}
	# 		],
	# 		select => ['me.dbxref_id', 'subject.cvterm_id', 'subject.name', 'subject_2.cvterm_id', 'subject_2.name', 'dbxref_2.accession'],
	# 		as => ['parent_dbxref_id', 'broad_category_id', 'broad_category_name', 'refined_category_id', 'refined_category_name', 'accession']
	# 	}
	# 	);

	# my %categories;
	# while (my $row = $categoryResults->next) {
	# 	my %category;
	# 	$category{'parent_id'} = $row->get_column('broad_category_id');
	# 	$category{'parent_name'} = $row->get_column('broad_category_name');
	# 	$categories{$category{'parent_name'}} = [] unless exists $categories{$category{'parent_name'}};
	# 	$category{'cvterm_id'} = $row->get_column('refined_category_id');
	# 	$category{'name'} = $row->get_column('refined_category_name');
	# 	push($categories{$category{'parent_name'}},\%category);
	# }

	#The implementation above is no longer necessary since we have direct term mappings in the amr_category table.

	my $amrCategoryResults = $self->dbixSchema->resultset('AmrCategory')->search(
		{},
		{
			join => ['parent_category', 'gene_cvterm', 'category', 'feature'],
			select => [
			'parent_category.cvterm_id',
			'parent_category.name',
			'parent_category.definition',
			'gene_cvterm.cvterm_id',
			'gene_cvterm.name',
			'gene_cvterm.definition',
			'category.cvterm_id',
			'category.name',
			'category.definition',
			'feature.feature_id'],
			as => [
			'parent_id',
			'parent_name',
			'parent_definition',
			'gene_id',
			'gene_name',
			'gene_definition',
			'category_id',
			'category_name',
			'category_definition',
			'feature_id']
		}
		);

	#Need to account for the fact that sub categories can have many cvterms which in turn have multiple feature ids associated with them
	# Note: 
	# A parent_category (category) has multiple subcategories.
	# A category has multiple gene cvterm_ids which in turn have multiple feature_ids

	# %amrCategories = (
	# 		parent_id* => {
	#						parent_name => parent_name,
	#						parent_definition = parent_definition,
	# 						subcategories => {
	# 											category_id => {
	#															category_name => category_name,
	#															category_definition => category_definition,
	#															parent_id => 'parent_id'*
	# 															gene_id => [feature_ids..]
	#		 													}..
	#		 								 }..
	#		 			  }..
	# ); 

my %amrCategories;
while (my $row = $amrCategoryResults->next) {
	my $parent_id = $row->get_column('parent_id');
	my $category_id = $row->get_column('category_id');
	$amrCategories{$parent_id} = {} unless exists $amrCategories{$parent_id};
	$amrCategories{$parent_id}->{'parent_name'} = $row->get_column('parent_name');
	$amrCategories{$parent_id}->{'parent_definition'} = $row->get_column('parent_definition');
	$amrCategories{$parent_id}->{'subcategories'} = {} unless exists $amrCategories{$parent_id}->{'subcategories'};
	$amrCategories{$parent_id}->{'subcategories'}->{$category_id} = {} unless exists $amrCategories{$parent_id}->{'subcategories'}->{$category_id};
	$amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'parent_id'} = $parent_id;
	$amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'category_name'} = $row->get_column('category_name');
	$amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'category_definition'} = $row->get_column('category_definition');
	$amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'} = [] unless exists $amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'};
	push(@{$amrCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'}}, $row->get_column('feature_id'));
}

my $vfCategoryResults = $self->dbixSchema->resultset('VfCategory')->search(
		{},
		{
			join => ['parent_category', 'gene_cvterm', 'category', 'feature'],
			select => [
			'parent_category.cvterm_id',
			'parent_category.name',
			'parent_category.definition',
			'gene_cvterm.cvterm_id',
			'gene_cvterm.name',
			'gene_cvterm.definition',
			'category.cvterm_id',
			'category.name',
			'category.definition',
			'feature.feature_id'],
			as => [
			'parent_id',
			'parent_name',
			'parent_definition',
			'gene_id',
			'gene_name',
			'gene_definition',
			'category_id',
			'category_name',
			'category_definition',
			'feature_id']
		}
		);

	#Need to account for the fact that sub categories can have many cvterms which in turn have multiple feature ids associated with them
	# Note: 
	# A parent_category (category) has multiple subcategories.
	# A category has multiple gene cvterm_ids which in turn have multiple feature_ids

	# %vfCategories = (
	# 		parent_id* => {
	#						parent_name => parent_name,
	#						parent_definition = parent_definition,
	# 						subcategories => {
	# 											category_id => {
	#															category_name => category_name,
	#															category_definition => category_definition,
	#															parent_id => 'parent_id'*
	# 															gene_id => [feature_ids..]
	#		 													}..
	#		 								 }..
	#		 			  }..
	# ); 

my %vfCategories;
while (my $row = $vfCategoryResults->next) {
	my $parent_id = $row->get_column('parent_id');
	my $category_id = $row->get_column('category_id');
	$vfCategories{$parent_id} = {} unless exists $vfCategories{$parent_id};
	$vfCategories{$parent_id}->{'parent_name'} = $row->get_column('parent_name');
	$vfCategories{$parent_id}->{'parent_definition'} = $row->get_column('parent_definition');
	$vfCategories{$parent_id}->{'subcategories'} = {} unless exists $vfCategories{$parent_id}->{'subcategories'};
	$vfCategories{$parent_id}->{'subcategories'}->{$category_id} = {} unless exists $vfCategories{$parent_id}->{'subcategories'}->{$category_id};
	$vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'parent_id'} = $parent_id;
	$vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'category_name'} = $row->get_column('category_name');
	$vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'category_definition'} = $row->get_column('category_definition');
	$vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'} = [] unless exists $vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'};
	push(@{$vfCategories{$parent_id}->{'subcategories'}->{$category_id}->{'gene_ids'}}, $row->get_column('feature_id'));
}

my %categories = ('vfCats' => \%vfCategories,
				  'amrCats' => \%amrCategories);

#my $categories_json = $formDataGenerator->_getJSONFormat(\%categories);
my $categories_json = encode_json(\%categories);
return $categories_json;
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

	$vFMetaFirst{'feature_id'} = $_vFFeatureId;
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
#my $formDataGenerator = Modules::FormDataGenerator->new();
#my $vfMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\@virMetaData);
#return $vfMetaInfoJsonRef;
	return encode_json(\@virMetaData);

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

#		my $formDataGenerator = Modules::FormDataGenerator->new();
#		my $amrMetaInfoJsonRef = $formDataGenerator->_getJSONFormat(\%data_hash);
#		return $amrMetaInfoJsonRef;

	return encode_json(\%data_hash);
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
	my @amr;
	my @vf;
	if($q->param('amr')) {
		$qtype='amr';
		$qgene = $q->param('amr');
		push @amr, $qgene;
	} elsif($q->param('vf')) {
		$qtype='vf';
		$qgene = $q->param('vf');
		push @vf, $qgene;
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
	my %public_genomes;
	my %private_genomes;
	my $subset_genomes = 0;
	my $public_ref;
	if(@genomes) {
		$subset_genomes = 1;
		my @private_ids = map m/private_(\d+)/ ? $1 : (), @genomes;
		my @public_ids = map m/public_(\d+)/ ? $1 : (), @genomes;
		
		croak "Error: one or more invalid genome parameters." unless ( scalar(@private_ids) + scalar(@public_ids) == scalar(@genomes) );
		
		# Retrieve genome names accessible to user
		
		$data->publicGenomes(\%public_genomes, \@public_ids);
		$data->privateGenomes($user, \%private_genomes, \@private_ids);
		
		%visable_genomes = (%public_genomes, %private_genomes);
		
		unless(keys %visable_genomes) {
			# User requested strains that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@private_ids) );
			return $self->redirect( $self->home_page );
		}
		
		$public_ref = \%public_genomes;
		
	} else {
		# Default is to show all viewable genomes
		$data->publicGenomes(\%public_genomes);
		$data->privateGenomes($user, \%private_genomes);
		
		%visable_genomes = (%public_genomes, %private_genomes);
		
		$public_ref = 'all';
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
	my $all_alleles = _getResidentGenomes($data, \@amr, \@vf, $subset_genomes, \%private_genomes, $public_ref);
	my $gene_alleles = $all_alleles->{$qtype}->{$qgene};
	
	my $num_alleles = 0;
	if($gene_alleles) {
		my $allele_json = encode_json($gene_alleles); # Only encode the lists for the gene we need
		$template->param(allele_json => $allele_json);
		map { $num_alleles += $_ } values %$gene_alleles;
	}
	
	get_logger->debug('Number of alleles found:'.$num_alleles);
	
	# Retrieve tree
	if($num_alleles > 2) {
		my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
		foreach my $g (keys %visable_genomes) {
			get_logger->debug("$g - ".$visable_genomes{$g});
		}
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

Changes are needed with amr/vf tables
to handle private/public

=cut

sub _getResidentGenomes {
	my $fdg         = shift;
	my $amr_ref     = shift;
	my $vf_ref      = shift;
	my $incl_absent = shift;
	my $pvt_ref     = shift;
	my $pub_ref     = shift;
	
	my @markers;
	@markers = @$amr_ref if $amr_ref;
	push @markers, @$vf_ref if $vf_ref;
	
	my %args = (
		markers => \@markers
	);
	
	my @genome_order;
	if($pub_ref) {
		unless(ref($pub_ref) eq 'HASH') {
			$args{public_genomes} = $pub_ref;
		} else {
			my @tmp = map { $pub_ref->{$_}->{feature_id}} keys %$pub_ref;
			$args{public_genomes} = \@tmp;
			@genome_order = keys %$pub_ref;
		}
		
	}
	if($pvt_ref) {
		my @tmp = map { $pvt_ref->{$_}->{feature_id}} keys %$pvt_ref;
		$args{private_genomes} = \@tmp;
		push @genome_order, keys %$pvt_ref;
	}
	
	my $result_hash = $fdg->getGeneAlleleData(%args);

	# List format
	my %allele_lists;
	
	foreach my $marker_type (qw/vf amr/) {
		my %alleles;
		my $allele_hash = $result_hash->{$marker_type};
		my $markers_ref;
		if($marker_type eq 'vf') {
			$markers_ref = $vf_ref;
		} else {
			$markers_ref = $amr_ref;
		}
		
		next unless $markers_ref;
		
		foreach my $g (@genome_order) {
			
			foreach my $qid (@$markers_ref) {
				
				if(defined($allele_hash->{$g})) {
					# genome has some alleles
					if(defined($allele_hash->{$g}->{$qid})) {
						# genome has allele for this query gene
						$alleles{$qid}->{$g} = scalar(@{$allele_hash->{$g}->{$qid}});
					} else {
						# genome does not have allele for this query gene
						$alleles{$qid}->{$g} = 0;
					}
				} else {
					# genome has no alleles
					$alleles{$qid}->{$g} = 0;
		
				}
			}
		}
		
		$allele_lists{$marker_type} = \%alleles;
	}
	
	$allele_lists{genome_order} = \@genome_order;
	
	foreach my $k (keys %allele_lists) {
		get_logger->debug("$k - " );
	}
		
	return \%allele_lists;
}

=head2 binaryMatrix


=cut

sub binaryMatrix : RunMode {
	my $self = shift;
	
	# Params
	my $q = $self->query();
	my @genomes = $q->param("selectedPubGenomesList");
	my @vf = $q->param("selectedVirList");
	my @amr = $q->param("selectedAmrList");
	
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
	my %public_genomes;
	my %private_genomes;
	$data->publicGenomes(\%public_genomes, \@public_ids);
	$data->privateGenomes($user, \%private_genomes, \@private_ids);
		
	my %visable_genomes = (%public_genomes, %private_genomes);
	
	unless(keys %visable_genomes) {
		# User requested strains that they do not have permission to view
		$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@private_ids) );
		return $self->redirect( $self->home_page );
	}
	
	# Get presence/absence
	my $results = _getResidentGenomes($data, \@amr, \@vf,  1, \%private_genomes, \%public_genomes);
	
	my $json =  encode_json($results);
	get_logger->debug($json);
	return($json);
}

1;
