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
use Log::Log4perl;
use Carp;

use JSON;

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

Qeuries the database for form data and returns a array reference to a list of table row data.

=cut

sub getFormData {
    my $self = shift;
    my $features = $self->dbixSchema->resultset('Feature')->search(
    {
        type_id => '1569'
        },
        {   
            select => [qw/me.uniquename/],
            order_by    => {-asc => ['me.uniquename']}
        }
        );
    my $formDataRef = $self->_hashFormData($features);
    return $formDataRef;
}

# sub getFormData {
#     my $self = shift;
#     my $features = $self->dbixSchema->resultset('Featureprop')->search(
#     {
#         name => 'genome_of'
#         },
#         {   join => ['type'],
#         select => [qw/me.value type.name/],
#         group_by => [qw/me.value type.name/],
#         order_by    => {-asc => ['me.value']}
#     }
#     );
#     my $formDataRef = $self->_hashFormData($features);
#     return $formDataRef;
# }

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
        {'featureprops.value' => "Virulence Factor" , 'type.name' => "gene"},
        {
            join        => ['featureprops' , 'type'],
            # select      => [ qw/me.feature_id me.type_id me.uniquename/],
            # as          => ['feature_id', 'type_id' , 'uniquename'],
            column  => [qw/feature_id type_id uniquename/],
            order_by    => { -asc => ['uniquename'] }
        }
        );
    my $virulenceFormDataRef = $self->_hashVirAmrFormData($_virulenceFactorProperties);
    
    ###Test to return a JSON object###
    my $encodedText = $self->_getJSONFormat($virulenceFormDataRef);
    ####

    return ($virulenceFormDataRef , $encodedText);
}

=cut _getAmrFormData

Queries the database for form data to be filled in the amr factor form.
Returns an array ref to form entry data.

=cut

sub getAmrFormData {
    my $self = shift;
    my $_amrFactorProperties = $self->dbixSchema->resultset('Feature')->search(
        {'featureprops.value' => "Antimicrobial Resistance" , 'type.name' => "gene"},
        {
            join        => ['featureprops' , 'type'],
            # select      => [ qw/me.feature_id me.type_id me.value feature.uniquename/],
            # as          => ['feature_id', 'type_id' , 'value', 'uniquename'],
                        column  => [qw/feature_id type_id uniquename/],
            order_by    => { -asc => ['uniquename'] }
        }
        );
    my $amrFormDataRef = $self->_hashVirAmrFormData($_amrFactorProperties);
    return $amrFormDataRef;
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


sub _getJSONFormat {
    my $self=shift;
    my $dataHashRef = shift;
    ###Test to return a JSON object###
    my $json = JSON::XS->new->pretty(1);
    my %jsonHash;
    $jsonHash{'data'} = $dataHashRef;
    my $_encodedText = $json->encode(\%jsonHash);
    ####
    return $_encodedText;
}


1;