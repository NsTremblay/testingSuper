#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use DBI;
use lib "$FindBin::Bin/../";
use Log::Log4perl qw(:easy);
use Config::Simple;

#Updater script for SuperPhy analysis pipeline. 
#This script should basically update the snps_genotypes, loci_genotypes, raw_virulence_data and raw_amr_data tables.

#Updating the virulence and amr tables should be easy, just reformat the binary table and append the results to the appropriate tables.

Log::Log4perl->easy_init({ level   => $DEBUG,
	file    => ">>/home/genodo/logs/update_data_loading.log" });

INFO('Updating datatables from SuperPhy analysis');

#Change this to read in the file with updated data.
my $INPUTFILE = $ARGV[0];
my $DATATYPE = $ARGV[1];

#Config params for connecting to the database. 
my $CONFIGFILE = "$FindBin::Bin/../Modules/genodo.cfg";
die "Exit status recieved " , FATAL("Unable to locate config file, or does not exist at specified location.") unless $CONFIGFILE;

my ($dbname, $dbuser, $dbpass, $dbhost, $dbport, $DBI, $TMPDIR);

if(my $db_conf = new Config::Simple($CONFIGFILE)) {
	$dbname    = $db_conf->param('db.name');
	$dbuser    = $db_conf->param('db.user');
	$dbpass    = $db_conf->param('db.pass');
	$dbhost    = $db_conf->param('db.host');
	$dbport    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
	$TMPDIR    = $db_conf->param('tmp.dir');
} 
else {
	die "Exit status recieved " , FATAL(Config::Simple->error());
}

die "Exit status recieved " , ERROR("Invalid configuration file.") unless $dbname;

my $dbh = DBI->connect(
	"dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
	$dbuser,
	$dbpass,
	{AutoCommit => 0, TraceLevel => 0}
	) or die "Exit status recieved " , FATAL("Unable to connect to database: " . DBI->errstr);

my @genomes; #List of new genomes
my @seqFeatures; #List of presence absence value for each genome

open my $binary_output , '<' , $INPUTFILE or die "Exit status recieved " , ERROR("Can't open data file $INPUTFILE: $!");

while (<$binary_output>) {
	$_ =~ s/\R//g;
	my @tempRow = split(/\t/, $_);
	if ($. == 1) {
		@genomes = @tempRow;
	}
	elsif ($. > 1) {
		push (@seqFeatures , \@tempRow);
	}
	else {
	}
}

my $lineCount = 0;

INFO("Total genomes in file: " . scalar(@genomes)-1);
#INFO(scalar(@seqFeatures) . " sequence features (Loci, Snp, etc...) in curent file");

#Need to have checks in case a new VF/AMR gene/Loci/SNP is added.

