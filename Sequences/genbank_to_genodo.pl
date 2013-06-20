#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Adapter;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Sys::Hostname;
use Config::Simple;
use POSIX qw(strftime);

=head1 NAME

$0 - Extracts and prints relevent information from genbank file used in genodo application

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --propfile        File name to dump hash of parent genome properties
 --gbfile          Genbank file containing all annotations and info for a genome

=head1 DESCRIPTION

A contig_collection is the parent label used for a set of DNA sequences belonging to a 
single project (which may be a WGS or a completed whole genome sequence). Global properties 
such as strain, host etc are defined at the contig_collection level.  The contig_collection 
properties are defined in a hash that is written to file using Data::Dumper.

The tags used in genbank record are mapped to the tables and cvterms used in Genodo and then
saved in the proper hash format used by genodo_fasta_loader.pl

=head2 Properties

	my %genome_properties = (
		name => 'lambda',
		uniquename => 'beta',
		mol_type => 'dna',
		serotype => 'O157:H3',
		strain => 'K12',
		keywords => 'a, really, bad, strain',
		isolation_host => 'H. sapiens',
		isolation_location => 'Canada',
		synonym => 'gamma',
		isolation_date => '1999-03-13',
		description => 'infection from someone\'s nasty hot tub',
		owner => 'kermit the frog',
		finished => 'yes',
		primary_dbxref => {
			db => 'refseq',
			acc => '12345',
			ver => '1',
			desc => 'Second home'
		},
		secondary_dbxref => {
			db => 'MyNCBI',
			acc => '12345',
			ver => '1',
			desc => 'Its second home'
		}
	);
	
	# upload_params are only needed for a user uploaded sequence
	my %upload_params = (
		category => 'release',
		login_id => 10,
		tag => 'Isolates from Zombie Outbreak',
		release_date => '2013-05-31'
	);
	
	open(OUT,">dump.txt");
	print OUT Data::Dumper->Dump([\%genome_properties, \%upload_params], ['contig_collection_properties', 'upload_parameters']);
	close OUT;

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

$|=1;

my ($GBFILE, $PROPFILE, $DEBUG);

GetOptions(
	'gbfile=s'=> \$GBFILE,
    'propfile=s'=> \$PROPFILE,
    'debug' => \$DEBUG
) || (pod2usage(-verbose => 1) && exit);


## Mapping
## This may change in the future, and should be reviewed periodically

# Genbank tags mapped to genodo cvterm properties

# Priority of tags can be either primary (0) or secondary (1).
# Primary get unshifted on the front resulting in getting assiged a lower rank
# Secondary get pushed on the back and get a higher rank

my %genbank_tags = (
	serotype => {
		cvterm => 'serotype',
		priority => 0
	},
	serovar => {
		cvterm => 'serotype',
		priority => 0
	},
	strain => {
		cvterm => 'strain',
		priority => 0
	},
	strain => {
		cvterm => 'strain',
		priority => 0
	}
);


# Need to construct a master record
# from possibly multiple genbank records

my $io = Bio::SeqIO->new(-file => $GBFILE, -format => "genbank" );

# Some properties will be identical between records
my $seq_obj = $io->next_seq;

my $anno_collection = $seq_obj->annotation;

# Use direct submission reference to fill in owner cvterm
my @annotations = $anno_collection->get_Annotations('reference');
	
for my $value ( @annotations ) {
	
	print $value->title,"\n";
	print $value->authors,"\n";
	print $value->location,"\n";
}

# Comment
@annotations = $anno_collection->get_Annotations('comment');





