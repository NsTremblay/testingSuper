#!/usr/bin/perl

use strict;
use warnings;
use IO::File;

my $inputFile  = $ARGV[0];


#Want to end up with a file like:

#StrainNumber 		LocusNumber			Presence/Absence
#============		===========			================
#	1					1						1/0
#	1					2						1/0
#	1					3						1/0
#	.					.						.
#	.					.						.
#	2					1						1/0
#	2					2						1/0
#	2					3						1/0

#The first line contains the strain numbers. All sequential lines are the loci and the data.

#Ex.
#		1		2		3		4		5		6
#L1		1/0		1/0		1/0		1/0		1/0		1/0
#L2		1/0		1/0		1/0		1/0		1/0		1/0

open my $file , '<' , $inputFile;
open my $outFile , '>' , 'data_output.txt';
open my $outLocusFile , '>' , 'locus_names.txt';

my @rowDelimTable;

my @locusTemp;
my @strainTemp;
my $locusCount = 0;
while (<$file>) {
	$_ =~ s/\R//g;
	my @tempRow = split(/\t/, $_);
	if ($. == 1) {
		@strainTemp = @tempRow;
	}
	elsif ($. > 1) {
		push (@locusTemp , \@tempRow);
	}
	else {
	}
}

my @data;

for (my $i = 1 ; $i < scalar(@strainTemp) ; $i++) {
	for (my $j = 0; $j < scalar(@locusTemp) ; $j++) {
		my @dataRow;
		
		#Strain Name
		$dataRow[0] = $strainTemp[$i];
		
		#Locus or Gene Name
		#Create a parser to strip off the meta info if its a virulence factor or an amr gene
		#Virulence factors start with an R######_ . Amr genes have AB######.#.gene#_ or just AB######.gene_
		#The "_" delimits the remainder of the tag which we dont need
		my $parsedHeader = parseHeader($locusTemp[$j][0]);
		$dataRow[1] = $parsedHeader;
		
		#P/A or SNP or Data
		$dataRow[2] = $locusTemp[$j][$i];
		push (@data , \@dataRow);
	}
}

foreach my $row (@data) {
	print $outFile $row->[0] . "\t";
	print $outFile $row->[1] . "\t";
	print $outFile $row->[2] . "\n";
}

foreach my $locus (@locusTemp) {
	print $outLocusFile $locus->[0] . "\n";
}

close $outFile;
close $outLocusFile;

sub parseHeader {
	#First check if virulence factor, elsif its an AMR gene, else it is a locus
	my $oldHeader = shift;
	my $newHeader;
	if ($oldHeader =~ /^(R\d{6})(_{1})./) {
		$newHeader = $1;
	}
	elsif ($oldHeader =~ /^(\w\w?\d{5}\d?\.)([^_]*)(_{1})./){
		$newHeader = $1 . $2;
	}
	elsif ($oldHeader =~ /^(NC_)([^_]*)(_{1})./) {
		$newHeader = $1 . $2;
	}
	else {
		$newHeader = $oldHeader;
	}
	return $newHeader;
}
