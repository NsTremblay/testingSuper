#!/usr/bin/env perl

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
use Modules::FET;
use Log::Log4perl;
use Carp;
use List::MoreUtils qw(indexes);
use List::MoreUtils qw(natatime);
use Parallel::ForkManager;
use Time::HiRes;

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
	my $start = Time::HiRes::gettimeofday();
	my $self = shift;
	my $group1GenomeIds = shift;
	my $group2GenomeIds = shift;

	my $group1lociDataTable = $self->dbixSchema->resultset('Loci')->search(
		{feature_id => $group1GenomeIds},
		{
			join => ['loci_genotypes'],
			select => ['me.locus_id', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['id', 'loci_count'],
			group_by => [qw/me.locus_id/],
			order_by => [qw/me.locus_id/]
		}
		);

	my $group2lociDataTable = $self->dbixSchema->resultset('Loci')->search(
		{feature_id => $group2GenomeIds},
		{
			join => ['loci_genotypes'],
			select => ['me.locus_id', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['id', 'loci_count'],
			group_by => [qw/me.locus_id/],
			order_by => [qw/me.locus_id/]
		}
		);

	my @group1Loci = $group1lociDataTable->all;
	my @group2Loci = $group2lociDataTable->all;

	my $fet = Modules::FET->new();
	$fet->group1($group1GenomeIds);
	$fet->group2($group2GenomeIds);
	$fet->group1Loci(\@group1Loci);
	$fet->group2Loci(\@group2Loci);
	$fet->testChar('1');
	my ($binaryData , $numSig) = $fet->run();

	my $end = Time::HiRes::gettimeofday();
	my $run_time = $end - $start;
	#print STDERR "Job took $run_time seconds\n"

	return ($binaryData, $numSig , $run_time);
}

sub getSnpData {
	my $self = shift;
	#For demo purposes we will query the first three strains from the data tables.
	my $strainIds = shift;
	#my @strainIds = (1,2,3,4,5,6,7,8,9,10);
	#foreach my $strainId (@{$strainIds}) {
	#The real strain id's will be passed as array refs;
	my @lociData;
	my @locusNames;

	my $locusNameTable = $self->dbixSchema->resultset('DataSnpName')->search(
		{},
		{
			column => [qw/me.locus_name/]
		}
		);
	
	while (my $locusNameRow = $locusNameTable->next) {
		my %locus;
		my @adenine;
		my @thymidine;
		my @cytosine;
		my @guanine;
		$locus{'locusname'} = $locusNameRow->locus_name;
		$locus{'adenine'} = \@adenine;
		$locus{'adenine_count'} = 0;
		$locus{'thymidine'} = \@thymidine;
		$locus{'thymidine_count'} = 0;
		$locus{'cytosine'} = \@cytosine;
		$locus{'cytosine_count'} = 0;
		$locus{'guanine'} = \@guanine;
		$locus{'guanine_count'} = 0;
		push (@lociData , \%locus); 
	}

	foreach my $strainId (@{$strainIds}) {
		my $rawBinaryData = $self->dbixSchema->resultset('RawSnpData')->search(
			{strain => "public_".$strainId},
			{
				column => [qw/me.strain me.locus_name me.presence_absence/]
			}
			);
		while (my $rawBinaryDataRow = $rawBinaryData->next) {
			my @locus = (grep($_->{'locusname'} eq $rawBinaryDataRow->locus_name , @lociData));
			if ($rawBinaryDataRow->snp eq 'A') {
				push (@{$locus[0]->{'adenine'}} , {strain => $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainId})->name});
				$locus[0]->{'adenine_count'}++;
			}
			elsif ($rawBinaryDataRow->snp eq 'T') {
				push (@{$locus[0]->{'thymidine'}} , {strain => $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainId})->name});
				$locus[0]->{'thymidine_count'}++;
			}
			elsif ($rawBinaryDataRow->snp eq 'C') {
				push (@{$locus[0]->{'cytosine'}} , {strain => $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainId})->name});
				$locus[0]->{'cytosine_count'}++;
			}
			elsif ($rawBinaryDataRow->snp eq 'G') {
				push (@{$locus[0]->{'guanine'}} , {strain => $self->dbixSchema->resultset('Feature')->find({'feature_id' => $strainId})->name});
				$locus[0]->{'guanine_count'}++;
			}
			else {
			}
			#push (@locusNames , $rawBinaryDataRow->locus_name);
		}
	}
	return \@lociData;
}

1;