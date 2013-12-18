#!/usr/bin/env perl

=pod

=head1 NAME

Modules::FormDataGenerator

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Matt Whiteside, for all their assistance on this project

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::FormDataGenerator;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl qw/get_logger :easy/;
use Carp;
use Time::HiRes qw( gettimeofday tv_interval );
use JSON;

#One time use
use IO::File;
use IO::Dir;
umask 0000;

#object creation
sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->_initialize(@_);
	return $self;
}

=head2 _initialize

Initializes the logger.
Assigns all values to class variables.
Anything else that the _initialize function does.

=cut

sub _initialize {
	my($self)=shift;

    #logging
    $self->logger(Log::Log4perl->get_logger()); 

    $self->logger->info("Logger initialized in Modules::FormDataGenerator");  

    my %params = @_;

    #on object construction set all parameters
    foreach my $key(keys %params){
    	if($self->can($key)){
    		$self->$key($params{$key});
    	}
    	else{
            #logconfess calls the confess of Carp package, as well as logging to Log4perl
            $self->logger->logconfess("$key is not a valid parameter in Modules::FormDataGenerator");
        }
    }   
}

=head2 dbixSchema

A pointer to the dbix::class::schema object used in Application

=cut
sub dbixSchema {
	my $self = shift;
	
	$self->{_dbixSchema} = shift // return $self->{_dbixSchema};
}

=head2 logger

Stores a logger object for the module.

=cut

sub logger {
	my $self=shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}


=head2 getFormData

Queries the database to return list of genomes available to user.

Method is used to populate forms with a list of public and
private genomes.

=cut

sub getFormData {
    my $self = shift;
    my $username = shift;
    
    # Return public genome names as list of hash-refs
    my $publicFormData = $self->publicGenomes();
    
    my $pubEncodedText = $self->_getJSONFormat($publicFormData);
    
    # Get private list (or empty list)
    my $privateFormData = $self->privateGenomes($username);

    #One time use.
    #$self->_getNameMap();
    #$self->_getAccessionMap();
    
    return($publicFormData, $privateFormData , $pubEncodedText);
}

sub publicGenomes {
	my $self = shift;
	my $subset_ids = shift;
	
	my $select_stmt = {
		'type.name' =>  'contig_collection'
	};
	if($subset_ids) {
		croak unless ref($subset_ids) eq 'ARRAY';
		$select_stmt->{feature_id} = { '-in' => $subset_ids };
	}
	
	my $genomes = $self->dbixSchema->resultset('Feature')->search(
		$select_stmt,
		{
			result_class => 'DBIx::Class::ResultClass::HashRefInflator',
			columns => [qw/feature_id uniquename name dbxref.accession/],
			join => ['type' , 'dbxref'],
			order_by    => {-asc => ['me.uniquename']}
	    }
	);

    my @publicFormData = $genomes->all;
    
    return \@publicFormData;
}

sub privateGenomes {
    my $self = shift;
    my $username = shift;
    my $subset_ids = shift;
    
    if($username) {
        # user is logged in
        
        # Return private genome names as list of hash-refs
        # Need to check view permissions for user
        
		my $select_stmt = [
			{
	             'login.username' => $username,
	             'type.name'      => 'contig_collection',
			},
			{
				'upload.category' => 'public',
				'type.name'       => 'contig_collection',
			},
		];
		if($subset_ids) {
			croak unless ref($subset_ids) eq 'ARRAY';
			$select_stmt = [
				{
		             'login.username' => $username,
		             'type.name'      => 'contig_collection',
		             'feature_id'     => { '-in' => $subset_ids }
				},
				{
					'upload.category' => 'public',
					'type.name'       => 'contig_collection',
					'feature_id'     => { '-in' => $subset_ids }
				},
			];
		}
		
        my $genomes = $self->dbixSchema->resultset('PrivateFeature')->search(
			$select_stmt,
			{
				result_class => 'DBIx::Class::ResultClass::HashRefInflator',
				columns => [qw/feature_id uniquename/],
				'+columns' => [qw/upload.category login.username/],
				join => [
					{ 'upload' => { 'permissions' => 'login'} },
					'type'
				]

			}
		);
        
        my @privateFormData = $genomes->all;

        foreach my $row_hash (@privateFormData) {
			my $display_name = $row_hash->{uniquename};
			if($row_hash->{upload}->{category} eq 'public') {
			   $display_name .= ' [Pub]';
			} else {
			     $display_name .= ' [Pri]';
			}
			$row_hash->{displayname} = $display_name;
        }

        return \@privateFormData;

	} else {
		# Return user-uploaded public genome names as list of hash-refs
		my $select_stmt = {
			'upload.category' => 'public',
			'type.name'       => 'contig_collection',
		};
		
		if($subset_ids) {
			croak unless ref($subset_ids) eq 'ARRAY';
			$select_stmt->{feature_id} = { '-in' => $subset_ids };
		}
		
		my $genomes = $self->dbixSchema->resultset('PrivateFeature')->search(
			$select_stmt,
			{
	            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
	            columns => [qw/feature_id uniquename/],
	            join => [
					{ 'upload' => 'permissions' },
					'type'
				]
	
	        }
        );

		my @privateFormData = $genomes->all;

		foreach my $row_hash (@privateFormData) {
			my $display_name = $row_hash->{uniquename};

			$row_hash->{displayname} = $display_name . ' [Pub]';
		}

		return \@privateFormData;
	}
}

=head2 _hashFormData

Hashes row entries returned from the database and returns an array ref to a list of these rows.

=cut

sub _hashFormData {
    my $self = shift;
    my $features = shift;
    my @formData;
    while (my $featureRow = $features->next){
        my %formRowData;
        $formRowData{'FEATUREID'}=$featureRow->feature_id;
        $formRowData{'UNIQUENAME'}=$featureRow->uniquename;
        push(@formData, \%formRowData);
    }
    return \@formData;
}

=head2 getGenomeUploadFormData

Queries the database for form data to be filled in the genome uploader form.
Returns an array ref to form entry data.

=cut

sub getGenomeUploadFormData {
    my $self = shift;
    my $cVTerms = $self->dbixSchema->resultset('Cvterm')->search(
        {'cv.name' => 'feature_property'},
        {
            join => ['cv'],
            select => [qw/me.name/]
        }
        );
    my $genomeUploaderRef = $self->_hashGenomeUploadFormData($cVTerms);
    return $genomeUploaderRef;
}

=head2 _hashGenomeUploadFormData

Hashes row entries returnes from the database and returns an array ref to a list of these rows.

=cut

sub _hashGenomeUploadFormData {
    my $self = shift;
    my $cVTerms = shift;
    my @genomeUploadFormData;
    while (my $cVTermRow = $cVTerms->next){
        my %guRowData;
        $guRowData{'TERM'}=$cVTermRow->name;
        push(@genomeUploadFormData, \%guRowData);
    }
    return \@genomeUploadFormData;
}

=cut _getVirulenceFormData

Queries the database for form data to be filled in the virluence factor form.
Returns an array ref to form entry data.

=cut

sub getVirulenceFormData {
    my $self = shift;
    my $_virulenceFactorProperties = $self->dbixSchema->resultset('Feature')->search(
    {
        'featureprops.value' => "Virulence Factor",
        'type.name' => "virulence_factor"
        },
        {
            column  => [qw/feature_id type_id me.name uniquename type.name featureprops.value/],
            join        => ['featureprops' , 'type'],
            order_by    => { -asc => ['name'] }
        }
        );
    my $virulenceFormDataRef = $self->_hashVirAmrFormData($_virulenceFactorProperties);
    my $encodedText = encode_json($virulenceFormDataRef);
    return $encodedText;
}

=cut _getAmrFormData

Queries the database for form data to be filled in the amr factor form.
Returns an array ref to form entry data.

=cut

sub getAmrFormData {
    my $self = shift;
    my $_amrFactorProperties = $self->dbixSchema->resultset('Feature')->search(
    {
        'type.name' => "antimicrobial_resistance_gene"
        },
        {
            column  => [qw/feature_id type_id name uniquename/],
            join        => ['type'],
            order_by    => { -asc => ['name'] }
        }
        );
    my $amrFormDataRef = $self->_hashVirAmrFormData($_amrFactorProperties);
    my $encodedText = encode_json($amrFormDataRef);
    return $encodedText;
}

=cut _hashVirAmrFormData

Inputs all column data into a hash table and returns a reference to the hash table.
Note: the Cvterms must be defined when up-loading sequences to the database otherwise you'll get a NULL exception and the page wont load.
i.e. You cannot just upload sequences into the db just into the Feature table without having any terms defined in the Featureprop table.
i.e. Fasta files must have attributes tagged to them before uploading.

=cut

sub _hashVirAmrFormData {
    my $self=shift;
    my $_factorProperties = shift;

    my %factors;

    while (my $fRow = $_factorProperties->next){
        my %fRowData;
        $fRowData{'feature_id'}=$fRow->feature_id;
        $fRowData{'name'}=$fRow->name;
        $fRowData{'uniquename'}=$fRow->uniquename;
        $factors{$fRow->feature_id} = \%fRowData;
    }
    return \%factors;
}

=cut _getJSONFormat 

Takes as input a hash ref and returns a UTF-8 encoded JSON string. 
When passed to the browser this string is atuomatically recognized as JSON structure.

=cut

sub _getJSONFormat {
    my $self=shift;
    my $dataHashRef = shift;
    my $json = JSON::XS->new->pretty(1);
    my %jsonHash;
    $jsonHash{'data'} = $dataHashRef;
    my $_encodedText = $json->encode(\%jsonHash);
    return $_encodedText;
}

sub dataViewSerotype {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = "serotype";
    my $serotypeJson = $self->publicDataViewList($publicIdList,$searchParam);
    return $serotypeJson;
}

sub dataViewIsolationHost {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = "isolation_host";
    my $isolationHostJson = $self->publicDataViewList($publicIdList,$searchParam);
    return $isolationHostJson;
}

sub dataViewIsolationSource {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = "isolation_source";
    my $isolationSourceJson = $self->publicDataViewList($publicIdList,$searchParam);
    return $isolationSourceJson;
}

sub dataViewIsolationDate {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = "isolation_date";
    my $isolationDateJson = $self->publicDataViewList($publicIdList,$searchParam);
    return $isolationDateJson;
}

sub dataViewIsolationLocation {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = "isolation_location";
    my $isolationLocationJson = $self->publicDataViewList($publicIdList,$searchParam);
    return $isolationLocationJson;
}

sub publicDataViewList {
    my $self=shift;
    my $publicIdList=shift;
    my $searchParam = shift;
    my @publicFeautureIds = @{$publicIdList};

    my $genomes = $self->dbixSchema->resultset('Feature')->search(
    {
        'type.name' =>  'contig_collection',
        },
        {
            columns => [qw/feature_id uniquename name dbxref.accession/],
            join => ['type' , 'dbxref'],
            order_by    => {-asc => ['me.uniquename']}
        }
        );

    my @publicDataViewNames;

    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => $searchParam},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %dataView;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $dataView{'value'} = "N/A";
        }
        else {
            #Need to parse out tags for location data
            if ($searchParam eq "isolation_location") {
                my $markedUpLocation = $1 if $dataRow->value =~ /(<location>[\w\d\W\D]*<\/location>)/;
                my $noMarkupLocation = $markedUpLocation;
                $noMarkupLocation =~ s/(<[\/]*location>)//g;
                $noMarkupLocation =~ s/<[\/]+[\w\d]*>//g;
                $noMarkupLocation =~ s/<[\w\d]*>/, /g;
                $noMarkupLocation =~ s/, //;
                $dataView{'value'} = $noMarkupLocation;
            }
            else {
                $dataView{'value'} = $dataRow->value;
            }
        }
        my $featureRow = $genomes->find({'me.feature_id' => "$_pubStrainId"});
        $dataView{'feature_id'} = $featureRow->feature_id;
        $dataView{'common_name'} = $featureRow->uniquename;
        $dataView{'accession'} = $featureRow->dbxref->accession;
        push(@publicDataViewNames , \%dataView);
    }
    my $dataViewJson = $self->_getJSONFormat(\@publicDataViewNames);
    return $dataViewJson;
}

sub _getNameMap {
    my $self=shift;
    my $genomes = $self->dbixSchema->resultset('Feature')->search(
    {
        'type.name' =>  'contig_collection',
        },
        {
            columns => [qw/feature_id uniquename name dbxref.accession/],
            join => ['type' , 'dbxref'],
            order_by    => {-asc => ['me.uniquename']}
        }
        );

    my $outDirectoryName = "../../Phylogeny/NewickTrees/";
    my $outFile = "pub_common_names.map";
    open(OUT, '>' . "$outDirectoryName" . "$outFile") or die "$!";

    while (my $featureRow = $genomes->next) {
        my $editedFeatureName = $featureRow->name;  
        $editedFeatureName =~ s/:/_/g;
        $editedFeatureName =~ s/\(/_/g;
            $editedFeatureName =~ s/\)/_/g;
$editedFeatureName =~ s/ /_/g;
print (OUT "public_" . $featureRow->feature_id . "\t" . $editedFeatureName . "\n");
}
close(OUT);
}

sub _getAccessionMap {
    my $self=shift;

    my $genomes = $self->dbixSchema->resultset('Feature')->search(
    {
        'type.name' =>  'contig_collection',
        },
        {
            columns => [qw/feature_id uniquename name dbxref.accession/],
            join => ['type' , 'dbxref'],
            order_by    => {-asc => ['me.uniquename']}
        }
        );

    my $outDirectoryName = "../../Phylogeny/NewickTrees/";
    my $outFile = "pub_accession.map";
    open(OUT, '>' . "$outDirectoryName" . "$outFile") or die "$!";

    while (my $featureRow = $genomes->next) {
        my $editedFeatureName = $featureRow->dbxref->accession;  
        $editedFeatureName =~ s/:/_/g;
        $editedFeatureName =~ s/\(/_/g;
            $editedFeatureName =~ s/\)/_/g;
$editedFeatureName =~ s/ /_/g;
print (OUT "public_" . $featureRow->feature_id . "\t" . $editedFeatureName . "\n");
}
close(OUT);
}


=head2 genomeInfo

Returns list of ALL genomes (and associated meta-data) for
a given user. If user is undef, returns all genomes in Feature 
table and genomes in PrivateFeature table visable to public.

Returns as json string.

=cut

sub genomeInfo {
	my $self = shift;
	my $username = shift;
	
	# Get pre-queried public feature table data
	my $meta_rs = $self->dbixSchema->resultset("Meta")->search(
		{
			name => 'public'	
		},
		{
		    columns => ['data_string']
		}
	);
		
	my $public_json;
	if(my $row = $meta_rs->first) {
		$public_json = $row->data_string;
	} else {
		my $public_genome_info = $self->_runGenomeQuery(1);
		$public_json = encode_json($public_genome_info);
	}

	my $private_json;
	if($username) {
		# Get user private genomes
	
		my $private_genome_info = $self->_runGenomeQuery(0, $username);
		$private_json = encode_json($private_genome_info);
	
   } else {
		# Get user public genomes
		
		my $meta_rs = $self->dbixSchema->resultset("Meta")->search(
			{
				name => 'upublic'	
			},
			{
				columns => ['data_string']
			}
		);
		
		if(my $row = $meta_rs->first) {
			$private_json = $row->data_string;
		} else {
			my $private_genome_info = $self->_runGenomeQuery(0);
			$private_json = encode_json($private_genome_info);	
		}
   }

   return($public_json, $private_json);
}

sub _runGenomeQuery {
 my ($self, $public, $username) = @_;

 my %fp_types = (
  serotype            => 1,
  strain              => 1,
  isolation_host      => 1,
  isolation_source    => 1,
  isolation_location  => 1,
  isolation_latlng    => 1,
  isolation_date      => 1,
  );

	# Table and relationship names
	my $feature_table_name = 'Feature';
	my $featureprop_rel_name = 'featureprops';
	my $order_name = { '-asc' => ['featureprops.rank'] };
	unless($public) {
		$feature_table_name = 'PrivateFeature';
		$featureprop_rel_name = 'private_featureprops';
		$order_name = { '-asc' => ['private_featureprops.rank'] };
	}
	
	# Query
	my $query = {
		'type.name'      => 'contig_collection',
		'type_2.name'      => { '-in' => [ keys %fp_types ] }
    };
    my $join = ['type'];
    my $prefetch = [
    { 'dbxref' => 'db' },
    { $featureprop_rel_name => 'type' },
    ];

	# Query data in private tables
	unless($public) {
		
		if($username) {
			$query = [
            {
             'login.username'     => $username,
             'type.name'          => 'contig_collection',
             'type_2.name'        => { '-in' => [ keys %fp_types ] }
             },
             {
                 'upload.category'    => 'public',
                 'type.name'          => 'contig_collection',
                 'type_2.name'        => { '-in' => [ keys %fp_types ] }
             }
             ];

             push @$prefetch, 'upload';
             } else {
               $query = {
                'upload.category'    => 'public',
                'type.name'          => 'contig_collection',
                'type_2.name'        => { '-in' => [ keys %fp_types ] }
            };
        }

        push @$join, { 'upload' => { 'permissions' => 'login'} };
    }

    my $feature_rs = $self->dbixSchema->resultset($feature_table_name)->search(
      $query,	
      {
       join => $join,
       prefetch => $prefetch,
			#order_by => $order_name
		}
     );

	# Create hash from all results
	my %genome_info;
	
	while(my $feature = $feature_rs->next) {
		my %feature_hash;
		
		# Feature data
		$feature_hash{uniquename} = $feature->uniquename;
		if($feature->dbxref) {
			my $version = $feature->dbxref->version;
			$feature_hash{primary_dbxref} = $feature->dbxref->db->name . ': ' . $feature->dbxref->accession;
			$feature_hash{primary_dbxref} .= '.' . $version if $version && $version ne '';
		}
		
		unless($public) {
			# Display name
			
			if($username) {
				# User logged in and may have some private genomes
				my $displayname = $feature_hash{uniquename};
				
				if($feature->upload->category eq 'public') {
					$feature_hash{displayname} = $displayname . ' [Pub]';
                    } else {
                     $feature_hash{displayname} = ' [Pri]';
                 }

                 } else {
				# User not logged in, all user genomes must be public
				my $displayname = $feature_hash{uniquename};
				$feature_hash{displayname} = $displayname . ' [Pub]';
			}
		}
		
		# Featureprop data
		my $featureprops = $feature->$featureprop_rel_name;
		
		while(my $fp = $featureprops->next) {
			my $type = $fp->type->name;

			$feature_hash{$type} = [] unless defined $feature_hash{$type};
			push @{$feature_hash{$type}}, $fp->value;
		}
		
		my $k = ($public) ? 'public_' : 'private_';
		
		$k .= $feature->feature_id;
		
		$genome_info{$k} = \%feature_hash;
	}
	
	return(\%genome_info);
}

=head2 loadMetaData

To save time, all public meta data (which is fairly static)
is queried once and then converted to json.  This json string 
is stored in the meta table.

=cut

sub loadMetaData {
	my $self = shift;
	
	my $public_genomes = $self->_runGenomeQuery(1);	
	my $user_public_genomes = $self->_runGenomeQuery(0);
	
	my $pub_json = encode_json($public_genomes);
	my $usr_json = encode_json($user_public_genomes);
	
	$self->dbixSchema->resultset('Meta')->update_or_create(
  {
   name             => 'public',
   format           => 'json',
   data_string      => $pub_json,
   timelastmodified => \'now()'
   },
   {
       key => 'meta_c1'
   }
   );
	
	$self->dbixSchema->resultset('Meta')->update_or_create(
  {
   name             => 'upublic',
   format           => 'json',
   data_string      => $usr_json,
   timelastmodified => \'now()'
   },
   {
       key => 'meta_c1'
   }
   );
	
}

=cut verifyAccess

Confirm that user can view provided user-uploaded genome.

Returns false if user does not have view access or returns the genome
privacy setting if true (i.e. public, private or release).

=cut

sub verifyAccess {
	my ($self, $username, $feature_id) = @_;
	
	my $results = $self->verifyMultipleAcess($username, [$feature_id]);
	
	return $results->{$feature_id};
}

sub verifyMultipleAccess {
	my ($self, $username, $feature_ids) = @_;
	
	croak unless ref($feature_ids) eq 'ARRAY';
	
	my $genomes_rs = $self->dbixSchema->resultset('PrivateFeature')->search(
		[
			{
				'login.username' => $username,
				'feature_id' => { '-in' => $feature_ids }
        	},
			{
				'upload.category'    => 'public',
				'feature_id' => { '-in' => $feature_ids }
			},
		],
        {     
        	columns => [qw/feature_id/],
            '+columns' => [qw/upload.category/],
            join => { 'upload' => { 'permissions' => 'login'} },
		}
	);
	
	my %results;
	foreach my $id (@$feature_ids) {
		if(my $feature = $genomes_rs->find( { 'feature_id' => $id })) {
			$results{$id} = $feature->upload->category;	
		} else {
			$results{$id} = 0;	
		}
	}
	
	return \%results;
}

=head2 seqAlignment

seqAlignent(feature_id, visable_hash)

Inputs:
 -feature_id       A query gene feature_id. 
                    Must be 'query_gene' type.
 -visable_hash     Hash containing
	                 public_/private_feature_ids => uniquename
	                                
MAKE SURE THE USER CAN ACCESS THESE GENOMES
DO NOT RELEASE PRIVATE SEQUENCES!	                                

Returns: 
  a JSON string representing a multiple
  sequence alignment of gene alleles.

=cut
sub seqAlignment {
	my ($self, $locus, $visable) = @_;
	
	get_logger->debug("multiple sequence alignment");  
	
	my @private_ids = map m/private_(\d+)/ ? $1 : (), keys %$visable;
	my @public_ids = map m/public_(\d+)/ ? $1 : (), keys %$visable;
	
	my %alignment;
	
	if(@private_ids) {
		my $feature_rs = $self->dbixSchema->resultset('PrivateFeature')->search(
			{
				'private_feature_relationship_subjects.object_id' => $locus,
				'type.name' => 'similar_to', 
				'private_feature_relationship_subjects_2.object_id' => { '-in' => \@private_ids },
				'type_2.name' => 'part_of'
			},
			{
				join => [
					{ 'private_feature_relationship_subjects' => 'type' },
					{ 'private_feature_relationship_subjects' => 'type' }
				],
				'+select' => ['private_feature_relationship_subjects_2.object_id'],
				'+as' => 'collection_id'
			}
		);
		
		while(my $feature = $feature_rs->next) {
			$alignment{$visable->{'private_'.$feature->get_column('collection_id')}} = $feature->residues;
		}
	}
	
	if(@public_ids) {
		my $feature_rs = $self->dbixSchema->resultset('Feature')->search(
			{
				'feature_relationship_subjects.object_id' => $locus,
				'type.name' => 'similar_to', 
				'feature_relationship_subjects_2.object_id' => { '-in' => \@public_ids },
				'type_2.name' => 'part_of'
			},
			{
				join => [
					{ 'feature_relationship_subjects' => 'type' },
					{ 'feature_relationship_subjects' => 'type' }
				],
				'+select' => ['feature_relationship_subjects_2.object_id'],
				'+as' => 'collection_id'
			}
		);
		
		while(my $feature = $feature_rs->next) {
			$alignment{$visable->{'public_'.$feature->get_column('collection_id')}} = $feature->residues;
		}
	}
	
	my @sequences = values(%alignment);
	return 0 unless @sequences > 1 && @sequences < 21;
	
	# Compute conservation line
	
	my $len = length($sequences[0]);
	map { croak "Error: sequence alignment lengths are not equal." unless length($_) == $len } @sequences[1..$#sequences];
	
	my $cons;
	for(my $i = 0; $i < $len; $i++) {
		my $m = 1;
		my $symbol = substr($sequences[0], $i, 1);
		
		foreach my $s (@sequences[1..$#sequences]) {
			if($symbol ne substr($s,$i,1)) {
				# mismatch
				$cons .= ' ';
				$m = 0;
				last;
			}
			
		}
		
		# match
		$cons .= '*' if $m;
	}
	
	$alignment{conservation_line} = $cons;
	
	return encode_json(\%alignment);
	
}

1;