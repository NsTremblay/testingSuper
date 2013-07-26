#!/usr/bin/env perl

=pod

=head1 NAME

Modules::StrainInfo

=head1 SNYNOPSIS

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

package Modules::StrainInfo;

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

use Modules::TreeManipulator;
use IO::File;

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

Run mode for the sinle strain page

=cut

sub strain_info : StartRunmode {
	my $self = shift;

	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	
	my $username;
	$username = $self->authen->username if $self->authen->is_authenticated;
	my ($pubDataRef, $priDataRef , $pubStrainJsonDataRef) = $formDataGenerator->getFormData($username);

	my $q = $self->query();
	my $strainID = $q->param("singleStrainID");
	my $privateStrainID = $q->param("privateSingleStrainID");

	#Code block for trees (may need to be changed later)
	my $publicTreeStrainID;
	my $privateTreeStrainID;
	my $strainInfoTreeRef;
	#Resume rest of code

	my $template;
	if(defined $strainID && $strainID ne "") {
		# User requested information on public strain

		my $strainInfoRef = $self->_getStrainInfo($strainID, 1);
		
		$template = $self->load_tmpl( 'strain_info.tmpl' ,
			associate => HTML::Template::HashWrapper->new( $strainInfoRef ),
			die_on_bad_params=>0 );
		$template->param('strainData' => 1);
		
		my $strainVirDataRef = $self->_getVirulenceData($strainID);
		$template->param(VIRDATA=>$strainVirDataRef);

		my $strainAmrDataRef = $self->_getAmrData($strainID);
		$template->param(AMRDATA=>$strainAmrDataRef);

		#Code block for public trees (may need to change this)
		$publicTreeStrainID = "public_".$strainID;
		$strainInfoTreeRef = $self->_createStrainInfoPhylo($publicTreeStrainID);
		$template->param(PHYLOTREE=>$strainInfoTreeRef);
		#Resume rest of code

		} elsif(defined $privateStrainID && $privateStrainID ne "") {
		# User requested information on private strain
		
		my $confirm_access = 0;
		my $privacy_category;
		foreach my $genome (@$priDataRef) {
			if($genome->{feature_id} eq $privateStrainID) {
				$confirm_access = 1;
				$privacy_category = $genome->{upload}->{category};
			}
		}
		
		unless($confirm_access) {
			# User requested strain that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genome ID: '.$privateStrainID );
			return $self->redirect( $self->home_page );
		}
		
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
			my $strainVirDataRef = $self->_getVirulenceData($privateStrainID);
			$template->param(VIRDATA=>$strainVirDataRef);

			my $strainAmrDataRef = $self->_getAmrData($privateStrainID);
			$template->param(AMRDATA=>$strainAmrDataRef);

			#Code block for private trees (may need to change this)
			$privateTreeStrainID = "private_".$privateStrainID;
			$strainInfoTreeRef = $self->_createStrainInfoPhylo($privateTreeStrainID);
			$template->param(PHYLOTREE=>$strainInfoTreeRef);
			#Resume rest of code

			} else {
				$template = $self->load_tmpl( 'strain_info.tmpl' ,
					die_on_bad_params=>0 );
				$template->param('strainData' => 0);
			}

	# Populate forms
	$template->param(FEATURES => $pubDataRef);
	$template->param(strainJSONData => $pubStrainJsonDataRef);
	
	if(@$priDataRef) {
		# User has private data
		$template->param(PRIVATE_DATA => 1);
		$template->param(PRIVATE_FEATURES => $priDataRef);
		
		} else {
			$template->param(PRIVATE_DATA => 0);
		}
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
	
	# Convert age to proper units
	if(defined $feature_hash{isolation_ages}) {
		foreach my $age_hash (@{$feature_hash{isolation_ages}}) {
			my($age, $unit) = Sequences::GenodoDateTime::ageOut($age_hash->{isolation_age});
			$age_hash->{isolation_age} = "$age $unit";
		}
	}
	
	return(\%feature_hash);
}

sub _getVirulenceData {
	my $self = shift;
	my $strainID = shift;
	my $virulence_table_name = 'RawVirulenceData';

	my @virulenceData;
	my $virCount = 0;

	my $virulenceData = $self->dbixSchema->resultset($virulence_table_name)->search(
		{'me.strain' => "public_".$strainID},
		{
			column => [qw/me.strain me.gene_name me.presence_absence/]
		}
		);

	while (my $virulenceDataRow = $virulenceData->next) {
		my %virRow;
		if ($virulenceDataRow->presence_absence == 1) {
			$virRow{'data'} = $self->dbixSchema->resultset('Feature')->find({feature_id => $virulenceDataRow->gene_name})->uniquename;
			push (@virulenceData, \%virRow);
		}
		else {
		}
		
	}
	return \@virulenceData;
}

sub _getAmrData {
	my $self = shift;
	my $strainID = shift;
	my $amr_table_name = 'RawAmrData';

	my @amrData;
	my $amrCount = 0;

	my $amrData = $self->dbixSchema->resultset($amr_table_name)->search(
		{'me.strain' => "public_".$strainID},
		{
			column => [qw/me.strain me.gene_name me.presence_absence/]
		}
		);

	while (my $amrDataRow = $amrData->next) {
		my %amrRow;
		if ($amrDataRow->presence_absence == 1) {
			$amrRow{'data'} = $self->dbixSchema->resultset('Feature')->find({feature_id => $amrDataRow->gene_name})->uniquename;
			push (@amrData , \%amrRow);
		}
		else {
		}
		
	}
	return \@amrData;
}

#These will need to be abstracted to remove redundancy
sub serotype_form : Runmode {
	my $self = shift;
	my $q = $self->query();
	my $publicIdList = $q->param("public_id_list");
	$publicIdList =~ s/"//g;
	my @publicIdList = split(/,/ , $publicIdList);
 	#make a call to the form data generator to populate
 	# the list and return the hash-ref.

 	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $serotypeHashRef = $formDataGenerator->dataViewSerotype(\@publicIdList);

 	return $serotypeHashRef;
 }

 sub host_source_form : Runmode {
 	my $self = shift;
 	my $q = $self->query();
 	my $publicIdList = $q->param("public_id_list");
 	$publicIdList =~ s/"//g;
 	my @publicIdList = split(/,/ , $publicIdList);
 	#make a call to the form data generator to populate
 	# the list and return the hash-ref.

 	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $isolationHostHashRef = $formDataGenerator->dataViewIsolationHost(\@publicIdList);

 	return $isolationHostHashRef;
 }

 sub isolation_source_form : Runmode {
 	my $self = shift;
 	my $q = $self->query();
 	my $publicIdList = $q->param("public_id_list");
 	$publicIdList =~ s/"//g;
 	my @publicIdList = split(/,/ , $publicIdList);
 	#make a call to the form data generator to populate
 	# the list and return the hash-ref.

 	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $isolationSourceHashRef = $formDataGenerator->dataViewIsolationSource(\@publicIdList);

 	return $isolationSourceHashRef;
 }

 sub isolation_date_form : Runmode {
 	my $self = shift;
 	my $q = $self->query();
 	my $publicIdList = $q->param("public_id_list");
 	$publicIdList =~ s/"//g;
 	my @publicIdList = split(/,/ , $publicIdList);
 	#make a call to the form data generator to populate
 	# the list and return the hash-ref.

 	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $isolationDateHashRef = $formDataGenerator->dataViewIsolationDate(\@publicIdList);

 	return $isolationDateHashRef;
 }

 sub isolation_location_form : Runmode {
 	my $self = shift;
 	my $q = $self->query();
 	my $publicIdList = $q->param("public_id_list");
 	$publicIdList =~ s/"//g;
 	my @publicIdList = split(/,/ , $publicIdList);
 	#make a call to the form data generator to populate
 	# the list and return the hash-ref.

 	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $isolationLocationHashRef = $formDataGenerator->dataViewIsolationLocation(\@publicIdList);

 	return $isolationLocationHashRef;
 }

#Methods for getting tree

sub _createStrainInfoPhylo {
	my $self = shift;
	my $strainID = shift;
	my $strainInfoTreeRef;

	#Create a new instance of tree manipulator and call the _getNearestClades function
	my $strainInfoTreeMaker = Modules::TreeManipulator->new();
	$strainInfoTreeMaker->inputDirectory("$FindBin::Bin/../../Phylogeny/NewickTrees/");
	$strainInfoTreeMaker->newickFile("example_tree");
	$strainInfoTreeMaker->_getNearestClades($strainID);
	
	my $strainInfoTreeFile = $strainInfoTreeMaker->outputDirectory() . $strainInfoTreeMaker->outputTree();
	my $strainInfoCssFile = $strainInfoTreeMaker->outputDirectory() . $strainInfoTreeMaker->cssFile();
	open my $in, '<' , $strainInfoTreeFile or die "Cant write to the $strainInfoTreeFile: $!";
	while (<$in>) {
		$strainInfoTreeRef .= $_;
	}
	my $systemLine = 'rm -r ' . $strainInfoTreeFile . ' | rm -r ' . $strainInfoCssFile;
	system($systemLine);

	return $strainInfoTreeRef;
}

1;
