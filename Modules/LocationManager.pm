#!/usr/bin/env perl

=pod

=head1 NAME

Modules::LocationManager

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=cut

package Modules::LocationManager;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl qw/get_logger :easy/;
use Carp;
use JSON;

# Object creation
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
    my ($self) = shift;

    #logging
    $self->logger(Log::Log4perl->get_logger());
    $self->logger->info("Logger initialized in Modules::LocationManager");
    
    my %params = @_;
    #object construction set all parameters
    foreach my $key(keys %params){
        if($self->can($key)){
            $self->key($params{$key});
        }
        else {
            #logconfess calls the confess of Carp package, as well as logging to Log4perl
            $self->logger->logconfess("$key is not a valid parameter in Modules::LocationManager");
        }
    }
}

=head2 dbixSchema

A pointer to the dbix::class::schema object used in Application

=cut
sub dbixSchema {
    my $self = shift;
    $self->{'_dbixSchema'} = shift // return $self->{'_dbixSchema'};
}

=head2 logger

Stores a logger object for the module.

=cut

sub logger {
    my $self = shift;
    $self->{'_logger'} = shift // return $self->{'_logger'};
}

=head2 getStrainLocaion

# TODO:

=cut

sub getStrainLocation {
    my ($self, $genomeId, $genomePrivacy) = @_;
    
    my $searchTable = $genomePrivacy eq 'private' ? 'PrivateGenomeLocation' : 'GenomeLocation';
    die "genome privacy could not be determined" unless $searchTable;
    my $locationResult = $self->dbixSchema->resultset($searchTable)->search(
        {'me.feature_id' => "$genomeId"},
        {
            column => [qw/me.feature_id me.geocode_id geocode.location/],
            join => ['geocode']
        }
        );
    my %strainLocation = ('presence' => 0);
    while (my $location = $locationResult->next) {
        $strainLocation{'presence'} = 1;
        $strainLocation{'location'} = $location->geocode->location;
    }
    return \%strainLocation;
}

sub geocodeAddress {
    # TODO: Change the schema to take in JSON
    my $markedUpLocation = shift;
    my $noMarkupLocation = $markedUpLocation;
    $noMarkupLocation =~ s/(<[\/]*location>)//g;
    $noMarkupLocation =~ s/<[\/]+[\w\d]*>//g;
    $noMarkupLocation =~ s/<[\w\d]*>/, /g;
    $noMarkupLocation =~ s/, //;

    my $googleGeocoder = Geo::Coder::Google->new(apiver => 3);

    my $latlong = $googleGeocoder->geocode($noMarkupLocation) or die "$!";

    my %location;
    $location{'coordinates'} = $latlong;
    
    my @_coordinates;
    push(@_coordinates, \%location);
    
    $markedUpLocation .= "<coordinates><center><lat>".%{$_coordinates[0]->{coordinates}->{geometry}->{location}}->{lat}."</lat><lng>".%{$_coordinates[0]->{coordinates}->{geometry}->{location}}->{lng}."</lng></center><viewport><southwest><lat>".%{$_coordinates[0]->{coordinates}->{geometry}->{viewport}->{southwest}}->{lat}."</lat><lng>".%{$_coordinates[0]->{coordinates}->{geometry}->{viewport}->{southwest}}->{lng}."</lng></southwest><northeast><lat>".%{$_coordinates[0]->{coordinates}->{geometry}->{viewport}->{northeast}}->{lat}."</lat><lng>".%{$_coordinates[0]->{coordinates}->{geometry}->{viewport}->{northeast}}->{lng}."</lng></northeast></viewport></coordinates>";

    return $markedUpLocation;
}

1;