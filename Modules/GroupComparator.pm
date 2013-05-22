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
use List::MoreUtils qw(indexes);

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
	my @strainIds = (1,2,3,4,5,6,7,8,9,10);
	#foreach my $strainId (@{$strainIds}) {
	#The real strain id's will be passed as array refs;
	
	my @lociData;
	my @locusNames;

	foreach my $strainId (@strainIds) {
		my $rawBinaryData = $self->dbixSchema->resultset('RawBinaryData')->search(
			{strain => "$strainId"},
			{
				column => [qw/me.strain me.locus_name me.presence_absence/]
			}
			);

		while (my $rawBinaryDataRow = $rawBinaryData->next) {
			if (!grep($_ eq $rawBinaryDataRow->locus_name , @locusNames)){
				my %locus;
				my @present;
				my @absent;
				$locus{'locusname'} = $rawBinaryDataRow->locus_name;
				$locus{'present'} = \@present;
				$locus{'absent'} = \@absent;
				if ($rawBinaryDataRow->presence_absence == 1) {
					push (@{$locus{'present'}} , {strain => $rawBinaryDataRow->strain});
				}
				elsif ($rawBinaryDataRow->presence_absence == 0) {
					push (@{$locus{'absent'}} , {strain => $rawBinaryDataRow->strain})
				}
				else {
				}
				push (@lociData , \%locus);
				push (@locusNames , $rawBinaryDataRow->locus_name);
			}
			else {
				#This next block needs to be optimized because its very slow with the extra for loop
				for (my $i = 0; $i < scalar(@lociData); $i++) {
					if (($lociData[$i]{'locusname'} eq $rawBinaryDataRow->locus_name) && ($rawBinaryDataRow->presence_absence == 1)) {
						push (@{$lociData[$i]}{'present'} , {strain => $rawBinaryDataRow->strain});
					}
					elsif (($lociData[$i]{'locusname'} eq $rawBinaryDataRow->locus_name) && ($rawBinaryDataRow->presence_absence == 0)) {
						push (@{$lociData[$i]}{'absent'} , {strain => $rawBinaryDataRow->strain})
					}
					else {
					}
				}
			}
		}
	}
	return \@lociData;
}
1;