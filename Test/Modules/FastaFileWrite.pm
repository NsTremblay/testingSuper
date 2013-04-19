#!/usr/bin/perl

=pod

=head1 NAME

Modules::FastaFileWrite - A class that provides the following functionality:

=head1 SYNOPSIS

	use Modules::FastaFileWrite;
	...

=head1 DESCRIPTION

This module can be called to write out whole genomes to files selected from the multi strain selection form on the website.
The fasta files will then be passed to the Panseq analysis platform for statistical analysis.

=head1 ACKNOWLEDGEMENTS

Thanks.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.html

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::FastaFileWrite;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl;
use Carp;
use Bio::SeqIO;
use IO::File;
use IO::Dir;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';

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

=cut

sub _initialize {
	my ($self) = shift;

	#logging
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::FastaFileWrite");

	my %params = @_;

	#object construction set all parameters
	foreach my $key(keys %params){
		if($self->can($key)){
			$self->key($params{$key});
		}
		else {
		#logconfess calls the confess of Carp package, as well as logging to Log4perl
		$self->logger ->logconfess("$key is not a valid parameter in Modules::FastaFileWrite");
	}
}
}

=head2 logger 

Stores a logger object for the module.

=cut

sub logger {
	my $self = shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}

=head2 writeStrainsToFile

Method which takes in a list of contigs for a single genome and writes it out to a fasta file.

=cut


sub writeStrainsToFile {
	my $self = shift;
	my $strainNames = shift;

	#The contig will have three keys name, residues and description which will be accessed as:
	#contigHash{name}, contigHash{residues}, contigHash{description}

	#We want to append the accessed fields to a file such as:

	#>> "\> . contig{name} . contig{description}. \n"
	#>> "contig{residues} . \n"

	#	Need to store an array of %contig into @contigs where each %contig consists of:
	#	%contig = ('name' => '' , 'residues' => '' , 'description' => '') 

	foreach my $strainName (@{$strainNames}) {
		my %genome;
		my @contigs;

		my $featureProperties = $self->dbixSchema->resultset('Featureprop')->search(
			{value => "$strainName"},
			{
				column => [qw/me.feature_id/]
			}
			);

		while (my $featureRow = $featureProperties->next) {
			my %contig;

			my $contigRowId = $featureRow->feature_id;

			my $contigRow = $self->dbixSchema->resultset('Feature')->find({feature_id => $contigRowId});

			$contig{'name'} = $contigRow->name;
			$contig{'residues'} = $contigRow->residues;

			my $_contigDescription = $self->dbixSchema->resultset('Featureprop')->search(
				{'me.feature_id' => $contigRowId},
				{
					join => ['type'],
					column => [qw/me.value/]
				}
				);

			my $contDesc = "";

			while (my $cont = $_contigDescription->next) {
				$contDesc =  $contDesc . ", " . $cont->value;
			}
			$contig{'description'} = $contDesc;
			push(@contigs , \%contig);
		}

		$genome{'genome_name'} = $strainName;
		$genome{'contigs'} = \@contigs;

		#print STDERR "Genome: " . $genome{'genome_name'} . "\n";
		foreach my $contig (@{$genome{'contigs'}}){
			#print STDERR "Name: " . $contig->{'name'} . "\n";
			#print STDERR "Description: " . $contig->{'description'} . "\n";
			#print STDERR "Residues: " . $contig->{'residues'} . "\n";
		}
	}
}

#The file writeout needs to be able to take in a series of fasta headers and write them out to a fasta file
1;