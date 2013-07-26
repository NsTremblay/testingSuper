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

my %inputDataType = ('virulence' => "raw_virulence_data", 'amr' => "raw_amr_data", 'snp' => "raw_snp_data", 'binary' => "raw_binary_data");

#Specifies the table to upload data to
%inputDataType;

#First thing we need to do is exclude all the columns that are not part of data.
#These usually have no entry in the first row so we can check against that 

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
my $locusCount = 0;
my $strainCount = 0;

#print "There are " . scalar(@firstFileRow) . " strains in this data file\n";
#print "There are " . scalar(@firstFileColumn) . " loci in this data file\n";

my $systemLine  = "mkdir data_out_temp";
system($systemLine) == 0 or croak "$!\n";

my @data;
my $outfolder = "data_out_temp";
my $outfile = "$INPUTDATATYPE" . "_data_out_temp";
open my $data_out, '>>' , "$outfolder/$outfile" or croak "$!";

print "Processing $INPUTFILE and parsing headers\n";

for (my $i = 1 ; $i < scalar(@firstFileRow) ; $i++) {
	#Start at i=1 becuase the first strain starts at index 1 
	for (my $j = 0; $j < scalar(@locusTemp) ; $j++) {
		my @dataRow;
		#Strain Name
		$dataRow[0] = $strainTemp[$i];
		
		#Create a parser to strip off the feature_id or name from the tag
		#AMR feature_ids will be delimited by AMR_#####|
		#VFs feature_ids will be delimited by VF_####|
		#Loci names will be delimited by locus_###
		#Snp names will be delimited by snp_###
		
		my $parsedHeader = parseHeader($locusTemp[$j][0], $INPUTDATATYPE);
		$dataRow[1] = $parsedHeader;
		
		#P/A or SNP or Data
		$dataRow[2] = $locusTemp[$j][$i];
		push (@data , \@dataRow);
	}
}

foreach my $row (@data) {
	print $data_out $row->[0] . "\t";
	print $data_out $row->[1] . "\t";
	print $data_out $row->[2] . "\n";
}

close $data_out;
#sub to load everything into the appropriate table in the db
#unlink $outfolder;

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
		if ($oldHeader =~ /^(locus_)([\w\d]*)/) {
			$newHeader = $2;
		}
		else {
			croak "Not a valid locus name, exiting\n";
		}
	}
	#SNP Data
	else {
		if ($oldHeader =~ /^(snp_)([\w\d]*)/) {
			$newHeader = $2;
		}
		else {
			croak "Not a valid snp name, exiting\n";
		}
	}
	return $newHeader;
}