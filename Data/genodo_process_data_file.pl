#!/usr/bin/perl

use strict;
use warnings;
use IO::File;


use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Carp qw/croak carp/;
use Config::Simple;
use DBIx::Class::ResultSet;
use DBIx::Class::Row;


use IO::File;
use IO::Dir;
umask 0000;

=head1 NAME

$0 - Processes teb delmited output files from analysis for uploading to the db.
=head1 SYNOPSIS

  % genodo_process_data.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --input_file         Specify a tab delimited input file.
 --data_type         Specify type of input (virulence, amr, binary, snp)

=head1 DESCRIPTION

Script to process tab delimited files for uploading data to the database.

=head1 AUTHOR

Akiff Manji

=cut

#Files will be processed to have the layout: 

#StrainNumber 		LocusNumber			Presence/Absence
#============		===========			================
#	1					1						1/0
#	2					1						1/0
#	3					1						1/0
#	.					.						.
#	.					.						.
#	1					2						1/0
#	2					2						1/0
#	3					2						1/0

my ($INPUTFILE , $INPUTDATATYPE);

GetOptions(
	'input_file=s'	=> \$INPUTFILE,
	'data_type=s'	=> \$INPUTDATATYPE,
	) or ( system( 'pod2text', $0 ), exit -1 );

croak "Missing argument. You must supply an input data file.\n" . system ('pod2text', $0) unless $INPUTFILE;
croak "Missing argument. You must supply an input data type (virulence, amr, binary, snp).\n" . system ('pod2text', $0) unless $INPUTDATATYPE;

my %inputDataType = ('virulence' => "RawVirulenceData", 'amr' => "RawAmrData", 'snp' => "SnpsGenotype", 'binary' => "LociGenotype");

my %inputDataTypeColumnNames = (
	'RawVirulenceData' => 
	{
		column1 => 'strain', 
		column2 => 'gene_name',
		column3 => 'presence_absence'
		},
		'RawAmrData' => 
		{
			column1 => 'strain', 
			column2 => 'gene_name',
			column3 => 'presence_absence'
			},
			'LociGenotype' => 
			{
				column1 => 'locus_genotype_id',           
				column2 => 'locus_id',
				column3 => 'locus_genotype',
				column4 => 'feature_id',
				loci => {
					tableName => 'Loci',
					column1 => 'locus_id',
					column2 => 'locus_name'
				}
				},
				'SnpsGenotype' => 
				{
					column1 => 'snp_genotype_id',           
					column2 => 'snp_id',
					A => 'snp_a',
					T => 'snp_t',
					C => 'snp_c',
					G => 'snp_g',
					column3 => 'feature_id',
					snps => {
						tableName => 'Snp',
						column1 => 'snp_id',
						column2 => 'snp_name'
					}
				}
				);

open my $datafile , '<' , $INPUTFILE;

#The first row contains all the genome names/id
my @firstFileRow; #Number of columns with genome data

#The first column will contain gene/snp/locus names/id
my @firstFileColumn; # Number of columns with gene/snp/locus data (referred to as a seqFeature)

while (<$datafile>) {
	if ($. == 1) {
		@firstFileRow = split(/\t/, $_);
		foreach my $strain (@firstFileRow) {
		}
	}
	else {
	}
}

my @genomeTemp = @firstFileRow;
my @seqFeatureTemp = @firstFileColumn;

open my $datafile2 , '<' , $INPUTFILE;

while (<$datafile2>) {
	$_ =~ s/\R//g;
	my @tempRow = split(/\t/, $_);
	if ($. == 1) {
		@genomeTemp = @tempRow;
	}
	elsif ($. > 1) {
		push (@seqFeatureTemp , \@tempRow);
	}
	else {
	}
}

my @rowDelimTable;
my $locusCount = 0000000;
my $snpCount = 0000000;

print scalar(@genomeTemp) . " genomes \n";
print scalar(@seqFeatureTemp) . " sequence features (Loci, Snp, etc...)\n";

print "Processing $INPUTFILE\n";

#Opens a file handler to write data out to
my $outfolder = "$FindBin::Bin/";
open my $outNameFile , '>' , "$INPUTDATATYPE" . "_processed_names.txt";
open my $outDataFile , '>' , "$INPUTDATATYPE" . "_processed_data.txt";


#Change this method below
if ($INPUTDATATYPE eq 'binary') {
	#Need to store the locus names first in the Loci (loci) table
	for (my $j = 0; $j < scalar(@seqFeatureTemp)-1 ; $j++) {
		$locusCount++;
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		print $outNameFile $locusCount . "\t" . $parsedHeader . "\n";
		writeOutBinaryData($locusCount);
	}
	print "/t...DONE\n";
}
elsif ($INPUTDATATYPE eq 'snp'){
	#Need to store the snp names first in the Snp (snps) table
	$snpCount++;
	for (my $j = 0; $j < scalar(@seqFeatureTemp)-1 ; $j++) {
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		print $outNameFile $snpCount . "\t" . $parsedHeader . "\n";
		#writeOutSnpData($snpCount);
	}
		print "/t...DONE\n";
}
else {
	#Data is either for virulence or amr genes
	print "/t...DONE\n";
}

close $outNameFile;
close $outDataFile;

sub writeOutBinaryData {
	my $_locusCount = shift;
	for (my $i = 1; $i < scalar(@genomeTemp); $i++) {
		print $outDataFile $genomeTemp[$i] . "\t" . $_locusCount . "\t" . $seqFeatureTemp[$_locusCount][$i] . "\n";
	}
	if ($_locusCount % 1000 == 0) {
		print "$_locusCount out of " . scalar(@seqFeatureTemp) . " loci completed\n";
	}
	else {
	}
}

sub writeOutSnpData {
	my $_snpCount = shift;
}

sub parseHeader {
	my $oldHeader = shift;
	my $_inputDataType = shift;
	my $newHeader;
	if ($_inputDataType eq "virulence") {
		if ($oldHeader =~ /^(VF)(_{1})([\w\d]*)(|)/) {
			$newHeader = $3;
		}
		else{
			croak "Not a valid virulence feature_id, exiting\n";
		}
	}
	elsif ($_inputDataType eq "amr") {
		if ($oldHeader =~ /^(AMR)(_{1})([\w\d]*)(|)/) {
			$newHeader = $3;
		}
		else {
			croak "Not a valid amr feature_id, exiting\n";
		}
	}
	#Locus ID
	elsif  ($_inputDataType eq "binary") {
		$newHeader = $oldHeader;
		# if ($oldHeader =~ /^(locus_)([\w\d]*)/) {
		# 	$newHeader = $2;
		# }
		# else {
		# 	croak "Not a valid locus name, exiting\n";
		# }
	}
	#SNP Data
	elsif ($_inputDataType eq "snp") {
		$newHeader = $oldHeader;
		# if ($oldHeader =~ /^(snp_)([\w\d]*)/) {
		# 	$newHeader = $2;
		# }
		# else {
		# 	croak "Not a valid snp name, exiting\n";
		# }
	}
	else{
	}
	return $newHeader;
}