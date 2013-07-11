#!/usr/bin/perl

=pod

=head1 NAME

Modules::FormDataGenerator

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

package Modules::FormDataGenerator;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl qw/get_logger/;
use Carp;

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
    my $genomes = $self->dbixSchema->resultset('Feature')->search(
    {
        'type.name' =>  'contig_collection',
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns => [qw/feature_id uniquename name dbxref.accession/],
            join => ['type' , 'dbxref'],
            order_by    => {-asc => ['me.uniquename']}
        }
        );
    
    my @publicFormData = $genomes->all;
    
    my $pubEncodedText = $self->_getJSONFormat(\@publicFormData);
    
    # Get private list (or empty list)
    my $privateFormData = $self->privateGenomes($username);

    #One time use.
    $self->_getNameMap();
    $self->_getAccessionMap();
    
    return(\@publicFormData, $privateFormData , $pubEncodedText);
}

sub privateGenomes {
    my $self = shift;
    my $username = shift;
    
    if($username) {
        # user is logged in
        
        # Return private genome names as list of hash-refs
        # Need to check view permissions for user
        my $genomes = $self->dbixSchema->resultset('PrivateFeature')->search(
           [
           {
             'login.username' => $username,
             'type.name'      => 'contig_collection',
             },
             {
                 'upload.category'    => 'public',
                 'type.name'      => 'contig_collection',
                 },
                 ],
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
           return [];
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
        'type.name' => "gene"
        },
        {
            #result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            column  => [qw/feature_id type_id uniquename type.name featureprops.value/],
            join        => ['featureprops' , 'type'],
            # select      => [ qw/me.feature_id me.type_id me.uniquename/],
            # as          => ['feature_id', 'type_id' , 'uniquename'],
            order_by    => { -asc => ['uniquename'] }
        }
        );
    my $virulenceFormDataRef = $self->_hashVirAmrFormData($_virulenceFactorProperties);
    #my $virulenceFormDataRef = $_virulenceFactorProperties->all;
    my $encodedText = $self->_getJSONFormat($virulenceFormDataRef);
    
    return ($virulenceFormDataRef , $encodedText);
}

=cut _getAmrFormData

Queries the database for form data to be filled in the amr factor form.
Returns an array ref to form entry data.

=cut

sub getAmrFormData {
    my $self = shift;
    my $_amrFactorProperties = $self->dbixSchema->resultset('Feature')->search(
    {
        'featureprops.value' => "Antimicrobial Resistance",
        'type.name' => "gene"
        },
        {
            #result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            column  => [qw/feature_id type_id uniquename/],
            join        => ['featureprops' , 'type'],
            # select      => [ qw/me.feature_id me.type_id me.value feature.uniquename/],
            # as          => ['feature_id', 'type_id' , 'value', 'uniquename'],
            order_by    => { -asc => ['uniquename'] }
        }
        );
    my $amrFormDataRef = $self->_hashVirAmrFormData($_amrFactorProperties);
    #my $amrFormDataRef = $_amrFactorProperties->all;
    my $encodedText = $self->_getJSONFormat($amrFormDataRef);
    return ($amrFormDataRef , $encodedText);
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

    my @factors;
    
    while (my $fRow = $_factorProperties->next){
        my %fRowData;
        $fRowData{'FEATUREID'}=$fRow->feature_id;
        $fRowData{'UNIQUENAME'}=$fRow->uniquename;
        push(@factors, \%fRowData);
    }
    return \@factors;
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
    my @publicFeautureIds = @{$publicIdList};

    my @serotypeNames;
    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => "serotype"},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %serotypeName;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $serotypeName{'value'} = "N/A";
        }
        else {
            $serotypeName{'value'} = $dataRow->value;
        }
        $serotypeName{'feature_id'} = $_pubStrainId;
        push(@serotypeNames , \%serotypeName);
    }
    my $serotypeJson = $self->_getJSONFormat(\@serotypeNames);
    return $serotypeJson;
}


=cut dataViewHostSource

Returns a list of the Host Sources for the 'Host Source' data view

=cut

sub dataViewIsolationHost {
    my $self=shift;
    my $publicIdList=shift;
    my @publicFeautureIds = @{$publicIdList};

    my @isolationHostNames;
    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => "isolation_host"},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %isolationHostName;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $isolationHostName{'value'} = "N/A";
        }
        else {
            $isolationHostName{'value'} = $dataRow->value;
        }
        $isolationHostName{'feature_id'} = $_pubStrainId;
        push(@isolationHostNames , \%isolationHostName);
    }
    my $isolationHostJson = $self->_getJSONFormat(\@isolationHostNames);
    return $isolationHostJson;
}

sub dataViewIsolationSource {
    my $self=shift;
    my $publicIdList=shift;
    my @publicFeautureIds = @{$publicIdList};

    my @isolationSourceNames;
    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => "isolation_source"},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %isolationSourceName;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $isolationSourceName{'value'} = "N/A";
        }
        else {
            $isolationSourceName{'value'} = $dataRow->value;
        }
        $isolationSourceName{'feature_id'} = $_pubStrainId;
        push(@isolationSourceNames , \%isolationSourceName);
    }
    my $isolationSourceJson = $self->_getJSONFormat(\@isolationSourceNames);
    return $isolationSourceJson;
}

sub dataViewIsolationDate {
    my $self=shift;
    my $publicIdList=shift;
    my @publicFeautureIds = @{$publicIdList};

    my @isolationDateNames;
    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => "isolation_date"},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %isolationDate;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $isolationDate{'value'} = "N/A";
        }
        else {
            $isolationDate{'value'} = $dataRow->value;
        }
        $isolationDate{'feature_id'} = $_pubStrainId;
        push(@isolationDateNames , \%isolationDate);
    }
    my $isolationDateJson = $self->_getJSONFormat(\@isolationDateNames);
    return $isolationDateJson;
}


sub dataViewIsolationLocation {
    my $self=shift;
    my $publicIdList=shift;
    my @publicFeautureIds = @{$publicIdList};

    my @isolationLocationNames;
    my $publicFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
        {'type.name' => "isolation_location"},
        {
            column  => [qw/me.feature_id me.value type.name/],
            join        => ['type']
        }
        );

    foreach my $_pubStrainId (@publicFeautureIds) {
        my %isolationLocation;
        my $dataRow = $publicFeatureProps->find({'me.feature_id' => "$_pubStrainId"});
        if (!$dataRow) {
            $isolationLocation{'value'} = "N/A";
        }
        else {
            $isolationLocation{'value'} = $dataRow->value;
        }
        $isolationLocation{'feature_id'} = $_pubStrainId;
        push(@isolationLocationNames , \%isolationLocation);
    }
    my $isolationLocationJson = $self->_getJSONFormat(\@isolationLocationNames);
    return $isolationLocationJson;
}

sub _getNameMap {
    my $self=shift;
    #my $timestamp = localtime(time);
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

1;