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

my %inputDataType = ('virulence' => "RawVirulenceData", 'amr' => "RawAmrData", 'snp' => "RawSnpData", 'binary' => "RawBinaryData");

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
			'RawBinaryData' => 
			{
				column1 => 'strain',           
				column2 =>'locus_name',
				column3 =>'presence_absence'
				},
				'RawSnpData' => 
				{
					column1 => 'strain',           
					column2 => 'locus_name',
					column3 => 'snp'
				}
				);

open my $datafile , '<' , $INPUTFILE;

my @firstFileRow; #Number of columns with strain data
my @firstFileColumn; # Number of columns with strain data 

while (<$datafile>) {
	if ($. == 1) {
		@firstFileRow = split(/\t/, $_);
		foreach my $strain (@firstFileRow) {
		}
	}
	else {
	}
}

my @strainTemp = @firstFileRow;
my @locusTemp = @firstFileColumn;

open my $datafile2 , '<' , $INPUTFILE;

while (<$datafile2>) {
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

my @rowDelimTable;
my $locusCount = 0000000;
my $strainCount = 0;
my $limit;

my $totalRowCount = scalar(@strainTemp) * scalar(@locusTemp);

#Added a limit for the number of loci to upload strictly for testing purposes
# if (scalar(@locusTemp) > 3000000) {
# 	$limit = 1501;
# }
# else {
# 	$limit = scalar(@locusTemp);
# }

print $totalRowCount . " rows to be inserted\n";

my $outfolder = "data_out_temp";
my $outfile = "$INPUTDATATYPE" . "_data_out_temp";

print "Processing $INPUTFILE and preparing for insert into " . $inputDataType{$INPUTDATATYPE} . "\n";
my $rowCount = 0;
for (my $i = 1 ; $i < scalar(@firstFileRow) ; $i++) {
	#Start at i=1 becuase the first strain starts at index 1 
	for (my $j = 0; $j < scalar(@locusTemp) ; $j++) {
		my $parsedHeader = parseHeader($locusTemp[$j][0], $INPUTDATATYPE);
		my %newRow = ($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column1} => $strainTemp[$i],
			$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column2} => $parsedHeader,
			$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column3} => $locusTemp[$j][$i]);
		my $insertRow = $schema->resultset($inputDataType{$INPUTDATATYPE})->create(\%newRow) or croak "Could not  insert row\n";
		$rowCount++;
		if ($rowCount % 100000 == 0) {
			print "$rowCount out of $totalRowCount rows inserted into table\n";
		}
		else{
		}
	}
}

# for (my $i = 1 ; $i < scalar(@firstFileRow) ; $i++) {
# 	#Start at i=1 becuase the first strain starts at index 1 
# 	for (my $j = 0; $j < $limit ; $j++) {
# 		my $parsedHeader = parseHeader($locusTemp[$j][0], $INPUTDATATYPE);
# 		my %newRow = ($inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column1} => $strainTemp[$i],
# 		$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column2} => $parsedHeader,
# 		$inputDataTypeColumnNames{$inputDataType{$INPUTDATATYPE}}{column3} => $locusTemp[$j][$i]);
# 		my $insertRow = $schema->resultset($inputDataType{$INPUTDATATYPE})->create(\%newRow) or croak "Could not  insert row\n";
# 		$rowCount++;
# 		if ($rowCount % 100000 == 0) {
# 			print "$rowCount out of $totalRowCount rows inserted into table\n";
# 		}
# 		else{
# 		}
# 	}
# }

if ($INPUTDATATYPE eq 'binary') {
	for (my $j = 0; $j < $limit ; $j++) {
		my $parsedHeader = parseHeader($locusTemp[$j][0], $INPUTDATATYPE);
		my %nameRow = ('locus_name' => $parsedHeader);
		my $insertRow = $schema->resultset('DataLociName')->create(\%nameRow) or croak "Could not  insert row\n";
	}
}
elsif ($INPUTDATATYPE eq 'snp'){
	for (my $j = 0; $j < $limit ; $j++) {
		my $parsedHeader = parseHeader($locusTemp[$j][0], $INPUTDATATYPE);
		my %nameRow = ('snp_name' => $parsedHeader);
		my $insertRow = $schema->resultset('DataSnpName')->create(\%nameRow) or croak "Could not  insert row\n";
	}
}
else {
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
	elsif  ($_inputDataType eq "binary") {
		$newHeader = "locus_" . $locusCount++;
		# if ($oldHeader =~ /^(locus_)([\w\d]*)/) {
		# 	$newHeader = $2;
		# }
		# else {
		# 	croak "Not a valid locus name, exiting\n";
		# }
	}
	#SNP Data
	elsif ($_inputDataType eq "snp") {
		if ($oldHeader =~ /^(snp_)([\w\d]*)/) {
			$newHeader = $2;
		}
		else {
			croak "Not a valid snp name, exiting\n";
		}
	}
	else{
	}
	return $newHeader;
}