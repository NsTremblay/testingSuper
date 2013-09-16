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
 --data_type          Specify type of input (virulence, amr, binary, snp)
 --db_name 			  Specify the database name to upload data to

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

my ($INPUTFILE , $INPUTDATATYPE, $DBNAME);

GetOptions(
	'input_file=s'	=> \$INPUTFILE,
	'data_type=s'	=> \$INPUTDATATYPE,
	'db_name=s'		=> \$DBNAME
	) or ( system( 'pod2text', $0 ), exit -1 );

croak "Missing argument. You must supply an input data file.\n" . system ('pod2text', $0) unless $INPUTFILE;
croak "Missing argument. You must supply an input data type (virulence, amr, binary, snp).\n" . system ('pod2text', $0) unless $INPUTDATATYPE;
croak "Missing argument. You must supply the database name.\n" . system ('pod2text', $0) unless $DBNAME;

my %inputDataType = ('virulence' => "RawVirulenceData", 'amr' => "RawAmrData", 'snp' => "SnpsGenotype", 'binary' => "LociGenotype");

my %inputDataTypeColumnNames = (
	'RawVirulenceData' => 
	{
		column2 => 'genome_id', 
		column3 => 'gene_id',
		column4 => 'presence_absence'
		},
		'RawAmrData' => 
		{
			column2 => 'genome_id', 
			column3 => 'gene_id',
			column4 => 'presence_absence'
			},
			'LociGenotype' => 
			{
				column1 => 'locus_genotype_id',           
				column2 => 'locus_id',
				column3 => 'locus_genotype',
				column4 => 'feature_id',
				table => {
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
					table => {
						tableName => 'Snp',
						column1 => 'snp_id',
						column2 => 'snp_name'
					}
				}
				);

unless ($ENV{USER} eq 'postgres') {
	die "User \'postgres\' must be logged in. You are currently logged in as: " . $ENV{USER} . "\n";
}

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
my $viramrCount = 0000000;

my $lineCount = 0;

print scalar(@genomeTemp) . " genomes \n";
print scalar(@seqFeatureTemp) . " sequence features (Loci, Snp, etc...)\n";

print "Processing $INPUTFILE\n";

#Opens a file handler to write data out to

#This is only for snp and loci data. Virulence and Amr do not need an additional name file
my $outfolder = "$FindBin::Bin/";
open my $outNameFile , '>' , "$INPUTDATATYPE" . "_processed_names.txt" or croak "Can't write to file: $!";
open my $outDataFile , '>' , "$INPUTDATATYPE" . "_processed_data.txt" or croak "Can't write to file: $!";
# Create a different file handle for VIR/AMR
open my $outVirAMrDataFile , '>' , "$INPUTDATATYPE" . "_processed_viramr_data.txt" or croak "Can't write to file: $!";

#Change this method below
if ($INPUTDATATYPE eq 'binary') {
	#Need to store the locus names first in the Loci (loci) table
	for (my $j = 0; $j < scalar(@seqFeatureTemp)-1 ; $j++) {
		$locusCount++;
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		print $outNameFile $locusCount . "\t" . $parsedHeader . "\n";
		writeOutBinaryData($locusCount);
	}
	print "\t...Adding loci to database\n";
	copyLociDataToDb();
}
elsif ($INPUTDATATYPE eq 'snp'){
	#Need to store the snp names first in the Snp (snps) table
	for (my $j = 0; $j < scalar(@seqFeatureTemp)-1 ; $j++) {
		$snpCount++;
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		print $outNameFile $snpCount . "\t" . $parsedHeader . "\n";
		writeOutSnpData($snpCount);
	}
	print "\t...Adding snps to database\n";
	copySnpDataToDb();
}
else {
	#Data is either for virulence or amr genes
	for (my $j = 0 ; $j < scalar(@seqFeatureTemp)-1 ; $j++) {
		$viramrCount++;
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		writeOutVIRAMRData($parsedHeader , $viramrCount);
	}
	print "\t...Adding data to database\n";
	print $lineCount . "\n";
	copyVirAmrDataToDb();
}

close $outNameFile;
close $outDataFile;
close $outVirAMrDataFile;

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
	#Change this method to account for the added cols TODO
	my $_snpCount = shift;
	for (my $i = 1; $i < scalar(@genomeTemp); $i++) {
		print $outDataFile $genomeTemp[$i] . "\t" . $_snpCount . "\t" . $seqFeatureTemp[$_snpCount][$i] . "\n";
	}
	if ($_snpCount % 1000 == 0) {
		print "$_snpCount out of " . scalar(@seqFeatureTemp) . " snps completed\n";
	}
	else {
	}
}

sub writeOutVIRAMRData {
	my $_parsedHeader = shift;
	my $_viramrCount = shift;
	for (my $i = 1; $i < scalar(@genomeTemp); $i++) {
		print $outVirAMrDataFile $genomeTemp[$i] . "\t" . $_parsedHeader . "\t" . $seqFeatureTemp[$_viramrCount][$i] . "\n";
		$lineCount++;
	}
	if ($_viramrCount % 100 == 0) {
		print "$_viramrCount out of " . scalar(@seqFeatureTemp) . " VF/AMR genes completed\n";
	}
	else {
	}
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
			#croak "Not a valid virulence feature_id, exiting\n";
			print "Emptyheader: " . $oldHeader . "\n";
			next;
		}
	}
	elsif ($_inputDataType eq "amr") {
		if ($oldHeader =~ /^(AMR)(_{1})([\w\d]*)(|)/) {
			$newHeader = $3;
		}
		else {
			#croak "Not a valid amr feature_id, exiting\n";
			print "Emptyheader: " . $oldHeader . "\n";
			next;
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

sub copyLociDataToDb {
	open my $lociSQLFile , '>' , "$INPUTDATATYPE" . "_db.sql" or croak "Can't write to file: $!";
	print $lociSQLFile "BEGIN;\n"."COPY loci (locus_id, locus_name) FROM \'$FindBin::Bin/$INPUTDATATYPE"."_processed_names.txt\';\n"."COMMIT;\n"."BEGIN;\n"."COPY loci_genotypes (feature_id, locus_id, locus_genotype) FROM \'$FindBin::Bin/$INPUTDATATYPE"."_processed_data.txt\';\n"."COMMIT;";
	close $lociSQLFile;
	my $sysline = "psql $DBNAME < $FindBin::Bin/$INPUTDATATYPE"."_db.sql";
	system($sysline) == 0 or croak "$!\n";
	unlink "$INPUTDATATYPE" . "_db.sql";
}

sub copySnpDataToDb {
	open my $snpsSQLFile , '>' , "$INPUTDATATYPE" . "_db.sql" or croak "Can't write to file: $!";
	#print out to the sql file TODO
	close $snpsSQLFile;
	my $sysline = "psql $DBNAME < $FindBin::Bin/$INPUTDATATYPE"."_db.sql";
	system($sysline) == 0 or croak "$!\n";
	unlink "$INPUTDATATYPE" . "_db.sql";	
}

sub copyVirAmrDataToDb {
	open my $viramrSQLFile , '>' , "$INPUTDATATYPE" . "_db.sql" or croak "Can't write to file: $!";
	print $viramrSQLFile "BEGIN;\n"."COPY ".$inputDataType{$INPUTDATATYPE}." (genome_id, gene_id, presence_absence) FROM \'$FindBin::Bin/$INPUTDATATYPE"."_processed_viramr_data.txt\';\n"."COMMIT;";
	close $viramrSQLFile;
	my $sysline = "psql $DBNAME < $FindBin::Bin/$INPUTDATATYPE"."_db.sql";
	system($sysline) == 0 or croak "$!\n";
	unlink "$INPUTDATATYPE" . "_db.sql";	
}

unlink "$INPUTDATATYPE" . "_processed_names.txt";
unlink "$INPUTDATATYPE" . "_processed_data.txt";
unlink "$INPUTDATATYPE" . "_processed_viramr_data.txt";
