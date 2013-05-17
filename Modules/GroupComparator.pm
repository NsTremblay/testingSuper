#!/usr/bin/perl

=pod

=head1 NAME

Modules::GroupComparator

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

package Modules::GroupComparator;

use strict;
use warnings;
use FindBin;
use lib 'FindBin::Bin/../';
use parent 'Modules::App_Super';
use Log::Log4perl;
use Carp;

sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my ($self) = shift;

	#logging
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::GroupComparator");
	
	my %params = @_;
	#object construction set all parameters
	foreach my $key(keys %params){
		if($self->can($key)){
			$self->key($params{$key});
		}
		else {
			#logconfess calls the confess of Carp package, as well as logging to Log4perl
			$self->logger->logconfess("$key is not a valid parameter in Modules::GroupComparator");
		}
	}
}

sub logger {
	my $self = shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}

sub dbixSchema {
	my $self = shift;
	$self->{'_dbixSchema'} = shift // return $self->{'_dbixSchema'};
}

sub getBinaryData {
	my $self = shift;
	
	#For demo purposes we will query the first three strains from the data tables.
	#my $strainIds = shift;
	my @strainIds = (1,2,3);

	#The real strain id's will be passed as array refs;
	#foreach my $strainId (@{$strainIds}) {
		my @binaryData;
		foreach my $strainId (@strainIds) {
			my @binaryStrain;
			my $strainBinaryData = $self->dbixSchema->('raw_binary_data')->search(
				{strain => "$strainId"},
				{
					column => [qw/me.strain me.locus_name me.presence_absence/]
				}
				);
			while (my $binaryRow = $strainBinaryData->next) {
				my @binaryRowData;
				$binaryRowData[0] = $binaryRow->strain;
				$binaryRowData[1] = $binaryRow->locus_name;
				$binaryRowData[2] = $binaryRow->presence_absence;
				push(@binaryStrain , \@binaryRowData);
			}
			push(@binaryData , \@binaryStrain);
		}
		return \@binaryData;
	}


	1;