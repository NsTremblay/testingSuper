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

$0 - Processes teb delmited output files from analysis and uploads the data to the db.
=head1 SYNOPSIS

  % genodo_data_uploader.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --config         Specify a .conf containing DB connection parameters.
 --input_file         Specify a tab delimited input file.
 --data_type         Specify type of input (virulence, amr, binary, snp)

=head1 DESCRIPTION

Script to process tab delimited files and upload data to the database to a single multi-fasta file, 
to use for generating vir/amr data and the phylogenetic tree, etc.

=head1 AUTHOR

Akiff Manji

=cut

#Files will be processed to have the layout: 

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

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI, $INPUTFILE , $INPUTDATATYPE);

GetOptions(
	'config=s'      => \$CONFIG,
	'input_file=s'	=> \$INPUTFILE,
	'data_type=s'	=> \$INPUTDATATYPE,
	) or ( system( 'pod2text', $0 ), exit -1 );

# Connect to DB
croak "Missing argument. You must supply a configuration filename.\n" . system ('pod2text', $0) unless $CONFIG;
croak "Missing argument. You must supply an input data file.\n" . system ('pod2text', $0) unless $INPUTFILE;
croak "Missing argument. You must supply an input data type (virulence, amr, binary, snp).\n" . system ('pod2text', $0) unless $INPUTDATATYPE;
if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
} 
else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . ':dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS) or croak "Could not connect to database.";

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
my $strainCount = 0;

#The following provides a total count of rows to be inserted (Not very necessary, but good to have to inform the user)

my $totalRowCount = scalar(@genomeTemp) * scalar(@seqFeatureTemp);

print $totalRowCount . " rows to be inserted\n";

my $outfolder = "data_out_temp";
my $outfile = "$INPUTDATATYPE" . "_data_out_temp";

print "Processing $INPUTFILE and preparing for database insert\n";

if ($INPUTDATATYPE eq 'binary') {
	#Need to store the locus names first in the Loci (loci) table
	for (my $j = 0; $j < scalar(@seqFeatureTemp) ; $j++) {
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		my %nameRow = ($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{loci}->{column2} => $parsedHeader);
		my $insertRow = $schema->resultset($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{loci}{tableName})->create(\%nameRow) or croak "Could not  insert row\n";
		$locusCount++;
	}
	print $locusCount . " loci have been entered into " . $inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{loci}->{tableName} . "\n";
	print "Preparing to insert data into " . $inputDataType{$INPUTDATATYPE} . "\n";
	addBinaryData();
}
elsif ($INPUTDATATYPE eq 'snp'){
	#Need to store the snp names first in the Snp (snps) table
	for (my $j = 0; $j < scalar(@seqFeatureTemp) ; $j++) {
		my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
		my %nameRow = ($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{snps}->{column2} => $parsedHeader);
		my $insertRow = $schema->resultset($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{snps}->{tableName})->create(\%nameRow) or croak "Could not  insert row\n";
		$snpCount++;
	}
	print $snpCount . " snps have been entered into " . $inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{snps}->{tableName} . "\n";
	print "Preparing to insert data into " . $inputDataType{$INPUTDATATYPE} . "\n";
	addData();
}
else {
	#Data is either for virulence or amr genes
	addData();
}

sub addBinaryData {
	my $rowCount = 0;
	for (my $i = 1 ; $i < scalar(@firstFileRow) ; $i++) {
		#Start at i=1 becuase the first strain starts at index 1 
		for (my $j = 0; $j < scalar(@seqFeatureTemp) ; $j++) {
			my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
			my %newRow = (
				$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column2} => $schema->resultset('Loci')->find({'locus_name' => $parsedHeader})->locus_id,
				$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column3} => $seqFeatureTemp[$j][$i], #presence/absence value
				$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column4} => $genomeTemp[$i], #genome name
				);
			my $insertRow = $schema->resultset($inputDataType{$INPUTDATATYPE})->create(\%newRow) or croak "Could not  insert row\n";
			$rowCount++;
			if ($rowCount % 100000 == 0) {
				print "$rowCount out of $totalRowCount rows inserted into table\n";
			}
			else{
			}
		}
	}
}

sub addData {
	my $rowCount = 0;
	for (my $i = 1 ; $i < scalar(@firstFileRow) ; $i++) {
		#Start at i=1 becuase the first strain starts at index 1 
		for (my $j = 0; $j < scalar(@seqFeatureTemp) ; $j++) {
			my $parsedHeader = parseHeader($seqFeatureTemp[$j][0], $INPUTDATATYPE);
			my %newRow = ($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column1} => $genomeTemp[$i],
				$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column2} => $parsedHeader,
				$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}->{column3} => $seqFeatureTemp[$j][$i]);
			my $insertRow = $schema->resultset($inputDataType{$INPUTDATATYPE})->create(\%newRow) or croak "Could not  insert row\n";
			$rowCount++;
			if ($rowCount % 100000 == 0) {
				print "$rowCount out of $totalRowCount rows inserted into table\n";
			}
			else{
			}
		}
	}
}

print "All rows successfully updated\n";

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