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
#use List::MoreUtils qw(indexes);
#use List::MoreUtils qw(natatime);
#use Parallel::ForkManager;
use IO::File;
use File::Temp;
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;

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

sub configLocation {
	my $self = shift;
	$self->{'_configLocation'} = shift // return $self->{'_configLocation'};
}

sub testEmailToUser {
	my $self = shift;
	my $_user_email = shift;
	$self->config_file($self->configLocation);

	#Now just call getBinaryData to return necessary values

	my $transport = Email::Sender::Transport::SMTP::TLS->new(
		host     => 'smtp.gmail.com',
		port     => 587,
		username => $self->config_param('mail.address'),
		password => $self->config_param('mail.pass'),
		);
	
	my $message = Email::Simple->create(
		header => [
		From           => $self->config_param('mail.address'),
		To             => $_user_email,
		Subject        => 'SuperPhy group wise comparison results',
		'Content-Type' => 'text/html'
		],
		body => '<html>'
		. '<br><br>This is a test. Do not reply to this.'
		. '<br><br>SuperPhy Team.'
		. '</html>',
		);
	
	sendmail( $message, {transport => $transport} );
}

sub getBinaryData {
	my $self = shift;
	my $group1GenomeIds = shift;
	my $group2GenomeIds = shift;
	my $group1GenomeNames = shift;
	my $group2GenomeNames = shift;

	my $group1lociDataTable = $self->dbixSchema->resultset('Loci')->search(
		{feature_id => $group1GenomeIds},
		{
			join => ['loci_genotypes'],
			select => ['me.locus_id', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['id', 'locus_count'],
			group_by => [qw/me.locus_id/],
			order_by => [qw/me.locus_id/]
		}
		);

	my $group2lociDataTable = $self->dbixSchema->resultset('Loci')->search(
		{feature_id => $group2GenomeIds},
		{
			join => ['loci_genotypes'],
			select => ['me.locus_id', {sum => 'loci_genotypes.locus_genotype'}],
			as => ['id', 'locus_count'],
			group_by => [qw/me.locus_id/],
			order_by => [qw/me.locus_id/]
		}
		);

	my @group1Loci = $group1lociDataTable->all;
	my @group2Loci = $group2lociDataTable->all;

	my $fet = Modules::FET->new();
	$fet->group1($group1GenomeIds);
	$fet->group2($group2GenomeIds);
	$fet->group1Markers(\@group1Loci);
	$fet->group2Markers(\@group2Loci);
	$fet->testChar('1');
	#Returns hash ref of results
	my $results = $fet->run('locus_count');

	# #Print results to file
	my $tmp = File::Temp->new(	TEMPLATE => 'tempXXXXXXXXXX',
		DIR => '/genodo/group_wise_data_temp/',
		UNLINK => 0);

	print $tmp "Group 1: " . join(", ", @{$group1GenomeNames}) . "\n" . "Group 2: " . join(", ", @{$group2GenomeNames}) . "\n";   

	print $tmp "Locus ID \t Group 1 Present \t Group 1 Absent \t Group 2 Present \t Group 2 Absent \t p-value \n";

	my $allResultArray =  $results->[0]{'all_results'};
	foreach my $allResultRow (@{$allResultArray}) {
		print $tmp $allResultRow->{'marker_id'} . "\t" . $allResultRow->{'group1Present'} . "\t" . $allResultRow->{'group1Absent'} . "\t" . $allResultRow->{'group2Present'} . "\t" . $allResultRow->{'group2Absent'} . "\t" . $allResultRow->{'pvalue'} . "\n";
	}

	my $temp_file_name = $tmp->filename;
	$temp_file_name =~ s/\/genodo\/group_wise_data_temp\///;

	my @group1NameArray;
	foreach my $name (@{$group1GenomeNames}) {
		my %nameHash;
		$nameHash{'name'} = $name;
		push (@group1NameArray , \%nameHash);
	}

	my @group2NameArray;
	foreach my $name (@{$group2GenomeNames}) {
		my %nameHash;
		$nameHash{'name'} = $name;
		push (@group2NameArray , \%nameHash);
	}

	push($results, {'file_name' => $temp_file_name});
	push($results, {'gp1_names' => \@group1NameArray});
	push($results, {'gp2_names' => \@group2NameArray});

	return $results;
}

sub getSnpData {
	my $self = shift;
	my $group1GenomeIds = shift;
	my $group2GenomeIds = shift;
	my $group1GenomeNames = shift;
	my $group2GenomeNames = shift;

	my $group1SnpDataTable = $self->dbixSchema->resultset('Snp')->search(
		{feature_id => $group1GenomeIds},
		{
			join => ['snps_genotypes'],
			select => ['me.snp_id', {sum => 'snps_genotypes.snp_a'}, {sum => 'snps_genotypes.snp_t'}, {sum => 'snps_genotypes.snp_c'}, {sum => 'snps_genotypes.snp_g'}],
			as => ['id', 'a_count', 't_count', 'c_count', 'g_count'],
			group_by => [qw/me.snp_id/],
			order_by => [qw/me.snp_id/]
		}
		);

	my $group2SnpDataTable = $self->dbixSchema->resultset('Snp')->search(
		{feature_id => $group2GenomeIds},
		{
			join => ['snps_genotypes'],
			select => ['me.snp_id', {sum => 'snps_genotypes.snp_a'}, {sum => 'snps_genotypes.snp_t'}, {sum => 'snps_genotypes.snp_c'}, {sum => 'snps_genotypes.snp_g'}],
			as => ['id', 'a_count', 't_count', 'c_count', 'g_count'],
			group_by => [qw/me.snp_id/],
			order_by => [qw/me.snp_id/]
		}
		);

	my @group1Snps = $group1SnpDataTable->all;
	my @group2Snps = $group2SnpDataTable->all;

	my $fet = Modules::FET->new();
	$fet->group1($group1GenomeIds);
	$fet->group2($group2GenomeIds);
	$fet->group1Markers(\@group1Snps);
	$fet->group2Markers(\@group2Snps);

	my @results;
	#Returns hash ref of results
	$fet->testChar('A');
	my $a_results = $fet->run('a_count');
	$fet->testChar('T');
	my $t_results = $fet->run('t_count');
	$fet->testChar('C');
	my $c_results = $fet->run('c_count');
	$fet->testChar('G');
	my $g_results = $fet->run('g_count');

	#Merge all results and resort them
	my @combineAllResults = (@{$a_results->[0]{'all_results'}}, @{$t_results->[0]{'all_results'}}, @{$c_results->[0]{'all_results'}}, @{$g_results->[0]{'all_results'}});
	my @combineSigResults = (@{$a_results->[1]{'sig_results'}}, @{$t_results->[1]{'sig_results'}}, @{$c_results->[1]{'sig_results'}}, @{$g_results->[1]{'sig_results'}});
	my $combineSigCount = $a_results->[2]{'sig_count'} + $t_results->[2]{'sig_count'} + $c_results->[2]{'sig_count'} + $g_results->[2]{'sig_count'};	
	my $combineTotalComparisons = $a_results->[3]{'total_comparisons'} + $t_results->[3]{'total_comparisons'} + $c_results->[3]{'total_comparisons'} + $g_results->[3]{'total_comparisons'};

	my @sortedAllResults = sort({$a->{'pvalue'} <=> $b->{'pvalue'}} @combineAllResults);
	my @sortedSigResults = sort({$a->{'pvalue'} <=> $b->{'pvalue'}} @combineSigResults);

	push(@results, {'all_results' => \@sortedAllResults}, {'sig_results' => \@sortedSigResults}, {'sig_count' => $combineSigCount}, {'total_comparisons' => $combineTotalComparisons});

	# #Print results to file
	my $tmp = File::Temp->new(	TEMPLATE => 'tempXXXXXXXXXX',
		DIR => '/genodo/group_wise_data_temp/',
		UNLINK => 0);

	print $tmp "Group 1: " . join(", ", @{$group1GenomeNames}) . "\n" . "Group 2: " . join(", ", @{$group2GenomeNames}) . "\n";   

	print $tmp "SNP ID \t Nucleotide \t Group 1 Present \t Group 1 Absent \t Group 2 Present \t Group 2 Absent \t p-value \n";

	foreach my $sortedAllResultRow (@sortedAllResults) {
		print $tmp $sortedAllResultRow->{'marker_id'} . "\t" . $sortedAllResultRow->{'test_char'} . "\t" . $sortedAllResultRow->{'group1Present'} . "\t" . $sortedAllResultRow->{'group1Absent'} . "\t" . $sortedAllResultRow->{'group2Present'} . "\t" . $sortedAllResultRow->{'group2Absent'} . "\t" . $sortedAllResultRow->{'pvalue'} . "\n";
	}

	my $temp_file_name = $tmp->filename;
	$temp_file_name =~ s/\/genodo\/group_wise_data_temp\///;

	my @group1NameArray;
	foreach my $name (@{$group1GenomeNames}) {
		my %nameHash;
		$nameHash{'name'} = $name;
		push (@group1NameArray , \%nameHash);
	}

	my @group2NameArray;
	foreach my $name (@{$group2GenomeNames}) {
		my %nameHash;
		$nameHash{'name'} = $name;
		push (@group2NameArray , \%nameHash);
	}

	#push($results, {'file_name' => $temp_file_name});
	push(@results, {'results' => \@results});
	push(@results, {'file_name' => $temp_file_name});
	push(@results, {'gp1_names' => \@group1NameArray});
	push(@results, {'gp2_names' => \@group2NameArray});

	return \@results;
}

1;