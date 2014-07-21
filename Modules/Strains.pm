#!/usr/bin/env perl

=pod

=head1 NAME

Modules::Strains

=head1 SNYNOPSIS

=head1 DESCRIPTION


=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

package Modules::Strains;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
use Sequences::GenodoDateTime;
use Phylogeny::Tree;
use Modules::LocationManager;
use Modules::GenomeWarden;
use IO::File;
use JSON;

# Featureprops
# hash: name => cv
my %fp_types = (
	mol_type => 'feature_property',
	keywords => 'feature_property',
	description => 'feature_property',
	owner => 'feature_property',
	finished => 'feature_property',
	strain => 'local',
	serotype => 'local',
	isolation_host => 'local',
	isolation_location => 'local',
	isolation_date => 'local',
	synonym => 'feature_property',
	comment => 'feature_property',
	isolation_source => 'local',
	isolation_age => 'local',
	isolation_latlng => 'local',
	syndrome => 'local',
	pmid     => 'local',
);

# In addition to the meta-data in the featureprops table
# Also have external accessions (i.e. NCBI genbank ID) 
# found in the feature.dbxref_id column (primary) and
# the feature_dbxref table (secondary)


=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.

=cut

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::StrainInfo");
}

=head2 strain_info

Run mode for the single strain page

=cut

sub info : Runmode {
	my $self = shift;

	#Init the location manager
	my $locationManager = Modules::LocationManager->new();
	$locationManager->dbixSchema($self->dbixSchema);
	
	my $username = $self->authen->username;
		
	# Check if user is requesting genome info
	my $q = $self->query();
	
	# Need to replace these param checks with a single genome request.
	my $strainID;
	my $privateStrainID;
	my $feature = $q->param("genome");
	print STDERR "Genome is $feature\n\n";
	if($feature && $feature ne "") {
		if($feature =~ m/^public_(\d+)/) {
			$strainID = $1;
		} elsif($feature =~ m/^private_(\d+)/) {
			$privateStrainID = $1;
		} else {
			die "Error: invalid genome ID: $feature.";
		}
	}

	#Check if user has access to the particular requested genome
	my $warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, genomes => [$feature], user => $username, cvmemory => $self->cvmemory);

	my ($err, $bad1, $bad2) = $warden->error; 

	if($err) {
 		# User requested invalid strains or strains that they do not have permission to view
  		$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genomes: '.join(', ',@$bad1, @$bad2) );
  		return $self->redirect( $self->home_page );
	}

	# Data object
	my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema, cvmemory => $self->cvmemory);
	
	# Retrieve form data
	my ($pub_json, $pvt_json) = $data->genomeInfo($username);

	my $template;
	if(defined $strainID && $strainID ne "") {
		# User requested information on public strain

		my $strainInfoRef = $self->_getStrainInfo($strainID, 1);
		
		$template = $self->load_tmpl( 'strains_info.tmpl' ,
			associate => HTML::Template::HashWrapper->new( $strainInfoRef ),
			die_on_bad_params=>0 );
		$template->param('strainData' => 1);
		
		# Get phylogenetic tree
		my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
		$template->param(tree_json => $tree->nodeTree($feature));
		
		# Get Virulence and AMR genes for genome
		# Retrieve presence / absence of alleles for query genes
		my %args = (
			warden => $warden
		);

		my $results = $data->getGeneAlleleData(%args);
		get_logger->debug('halt1');
	
		my $gene_list = $results->{genes};
		my $gene_json = encode_json($gene_list);
		$template->param(gene_json => $gene_json);
	
		my $alleles = $results->{alleles};
		my $allele_json = encode_json($alleles);
		$template->param(allele_json => $allele_json);

		get_logger->debug('halt2');
	
		# Get location data for map
		my $strainLocationDataRef = $locationManager->getStrainLocation($strainID, 'public');
		$template->param(LOCATION => $strainLocationDataRef->{'presence'} , strainLocation => 'public_'.$strainID);

	} elsif(defined $privateStrainID && $privateStrainID ne "") {
		# TODO: Change this to use genome Warden
		# User requested information on private strain
		
		# Retrieve list of private genomes user can view (need full list to mask unviewable nodes in tree)
		my ($visable, $has_private) = $data->privateGenomes($username);
		
		unless(defined($visable->{$feature})) {
			# User requested strain that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genome ID: '.$privateStrainID );
			return $self->redirect( $self->home_page );
		}
		
		my $privacy_category = $visable->{$feature}->{access};
		my $strainInfoRef = $self->_getStrainInfo($privateStrainID, 0);
		
		$template = $self->load_tmpl( 'strain_info.tmpl' ,
			associate => HTML::Template::HashWrapper->new( $strainInfoRef ),
			die_on_bad_params=>0 );

		$template->param('strainData' => 1);
		$template->param('privateGenome' => 1);
		$template->param('username' => $username);
		
		if($privacy_category eq 'release') {
			$template->param('privacy' => "delayed public release");
		} else {
			$template->param('privacy' => $privacy_category);
		}
		
		# Get phylogenetic tree
		my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
		if($has_private) {
			# Need to use full tree, with non-visable nodes masked
			$data->publicGenomes(undef, $visable);
			$template->param(tree_json => $tree->nodeTree($feature, $visable));
		} else {
			# Can use public tree
			$template->param(tree_json => $tree->nodeTree($feature));
		}
		
		# Get Virulence and AMR genes for private genome
		# TODO: How should I pass in the pprivate strain id?
		get_logger->debug($privateStrainID);
		#my $result_hashref = $data->getGeneAlleleData(private_genomes => [$privateStrainID]);
		
		# my $results = $data->getGeneAlleleData(%args);
		# get_logger->debug('halt1');
	
		# my $gene_list = $results->{genes};
		# my $gene_json = encode_json($gene_list);
		# $template->param(gene_json => $gene_json);
	
		# my $alleles = $results->{alleles};
		# my $allele_json = encode_json($alleles);
		# $template->param(allele_json => $allele_json);

		# get_logger->debug('halt2');

		# Get private location data for map
		my $strainLocationDataRef = $locationManager->getStrainLocation($privateStrainID, 'private');
		$template->param(LOCATION => $strainLocationDataRef->{'presence'} , strainLocation => 'private_'.$privateStrainID);

	} else {
		$template = $self->load_tmpl( 'strains_info.tmpl' ,
			die_on_bad_params=>0 );
		$template->param('strainData' => 0);
	}

	# Populate forms
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;

	# AMR/VF categores
	my $categoriesRef = $self->categories();
	$template->param(categories => $categoriesRef);

	# AMR/VF Lists
	my $vfRef = $data->getVirulenceFormData();
	my $amrRef = $data->getAmrFormData();

	$template->param(vf => $vfRef);
	$template->param(amr => $amrRef);

	$template->param(title1 => 'GENOME');
	$template->param(title2 => 'INFORMATION');

	return $template->output();
}

=head2 search

=cut

sub search : StartRunmode {
	my $self = shift;
	
	my $fdg = Modules::FormDataGenerator->new();
	$fdg->dbixSchema($self->dbixSchema);
	
	my $username = $self->authen->username;
	my ($pub_json, $pvt_json) = $fdg->genomeInfo($username);
	
	my $template = $self->load_tmpl( 'strains_search.tmpl' , die_on_bad_params => 0);
	
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	# Phylogenetic tree
	my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
	
	# find visable nodes for user
	my $visable_nodes;
	$fdg->publicGenomes($visable_nodes);
	my $has_private = $fdg->privateGenomes($username, $visable_nodes);
	
	if($has_private) {
		my $tree_string = $tree->fullTree($visable_nodes);
		$template->param(tree_json => $tree_string);
	} else {
		my $tree_string = $tree->fullTree();
		$template->param(tree_json => $tree_string);
	}

	$template->param(title1 => 'GENOME');
	$template->param(title2 => 'SEARCH');
	
	return $template->output();
} 

=head2 _getStrainInfo

Takes in a strain name paramer and queries it against the appropriate table.
Returns an array reference to the strain metainfo.

=cut

sub _getStrainInfo {
	my $self = shift;
	my $strainID = shift;
	my $public = shift;
	
	my $feature_table_name = 'Feature';
	my $featureprop_rel_name = 'featureprops';
	my $dbxref_table_name = "FeatureDbxref";
	my $order_name = 'featureprops.rank';
	
	# Data is in private tables
	unless($public) {
		$feature_table_name = 'PrivateFeature';
		$featureprop_rel_name = 'private_featureprops';
		$dbxref_table_name = "PrivateFeatureDbxref";
		$order_name = 'private_featureprops.rank';
	}

	my $feature_rs = $self->dbixSchema->resultset($feature_table_name)->search(
		{
			"me.feature_id" => $strainID
		},
		{
			prefetch => [
				{ 'dbxref' => 'db' },
				{ $featureprop_rel_name => 'type' },
			],
			order_by => $order_name
		}
	);
	
	# Create hash
	my %feature_hash;
	my $feature = $feature_rs->first;
	
	# Feature data
	$feature_hash{uniquename} = $feature->uniquename;
	if($feature->dbxref) {
		my $version = $feature->dbxref->version;
		$feature_hash{primary_dbxref} = $feature->dbxref->db->name . ': ' . $feature->dbxref->accession;
		$feature_hash{primary_dbxref} .= '.' . $version if $version && $version ne '';
		if($feature->dbxref->db->urlprefix) {
			$feature_hash{primary_dbxref_link} = $feature->dbxref->db->urlprefix . $feature->dbxref->accession;
			$feature_hash{primary_dbxref_link} .= '.' . $version if $version && $version ne '';
		}
	}
	
	# Secondary Dbxrefs
	# Separate query to prevent unwanted join behavior
	my $feature_dbxrefs = $self->dbixSchema->resultset($dbxref_table_name)->search(
		{
			feature_id => $feature->feature_id
		},
		{
			prefetch => {'dbxref' => 'db'},
			order_by => 'db.name'
		}
	);
	
	$feature_hash{secondary_dbxrefs} = [] if $feature_dbxrefs->count;
	while(my $dx = $feature_dbxrefs->next) {
		my $version = $dx->dbxref->version;
		my $dx_hashref = { secondary_dbxref => $dx->dbxref->db->name . ': ' . $dx->dbxref->accession };
		$dx_hashref->{secondary_dbxref} .= '.' . $version if $version && $version ne '';
		if($dx->dbxref->db->urlprefix) {
			$dx_hashref->{secondary_dbxref_link} = $dx->dbxref->db->urlprefix . $dx->dbxref->accession;
			$dx_hashref->{secondary_dbxref_link} .= '.' . $version if $version && $version ne '';
		}
		push @{$feature_hash{secondary_dbxrefs}}, $dx_hashref;
	}
	
	
	# Featureprop data
	my $featureprops = $feature->$featureprop_rel_name;
	
	while(my $fp = $featureprops->next) {
		my $type = $fp->type->name;
		my $plural_types = $type.'s';
		$feature_hash{$plural_types} = [] unless defined $feature_hash{$plural_types};
		push @{$feature_hash{$plural_types}}, { $type => $fp->value };
	}
	
	$feature_hash{references} = 1 if defined($feature_hash{owners}) || defined($feature_hash{pmids});
	
	if(defined($feature_hash{pmids})) {
		my $pmid_list = '"'.join(',', (map {$_->{pmid}} @{$feature_hash{pmids}})).'"';
		#get_logger->debug("<$pmid_list>");
		$feature_hash{pmid_list} = $pmid_list;
		delete $feature_hash{pmids};
	}
	
	# Convert age to proper units
	if(defined $feature_hash{isolation_ages}) {
		foreach my $age_hash (@{$feature_hash{isolation_ages}}) {
			my($age, $unit) = Sequences::GenodoDateTime::ageOut($age_hash->{isolation_age});
			$age_hash->{isolation_age} = "$age $unit";
		}
	}
	
	return(\%feature_hash);
}

sub test : Runmode {
	my $self = shift;
	
	my $fdg = Modules::FormDataGenerator->new();
	$fdg->dbixSchema($self->dbixSchema);
	
	my $template = $self->load_tmpl( 'coffeescript_playground.tmpl' ,
		die_on_bad_params=>0 );
	
	my $username = $self->authen->username;
	my ($pub_json, $pvt_json) = $fdg->genomeInfo($username);
	
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	
	#$template->param('strainData' => 0);
	
	return $template->output();
}

=head2 geocode

=cut

sub geocode : Runmode {
	my $self = shift;
	my $q = $self->query();
	my $address = $q->param("address");

	#Init the location manager
	my $locationManager = Modules::LocationManager->new();
	$locationManager->dbixSchema($self->dbixSchema);

	my $queryResult = $locationManager->geocodeAddress($address);

	return $queryResult;
}


=head2 categories

Duplicate from Genes module - may consider merging into FormDataGenerator

=cut
sub categories {
	my $self = shift;
	
	my $amrCategoryResults = $self->dbixSchema->resultset('AmrCategory')->search(
		{},
		{
			join => ['parent_category', 'gene_cvterm', 'category'],
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
				'feature_id'],
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
			join => ['parent_category', 'gene_cvterm', 'category'],
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
				'feature_id'],
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

	my $categories_json = encode_json(\%categories);
	return $categories_json;
}

1;
