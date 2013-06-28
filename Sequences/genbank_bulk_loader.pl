#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Config::Simple;
use IO::CaptureOutput qw/capture_exec/;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Cwd qw/getcwd/;

=head1 NAME

$0 - Wrapper that calls the scripts needed to load individual genbank files into the Genodo DB

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --fastadir        Directory containing fasta files
 --gbdir           Directry containing genbank files
 --configfile      INI style config file containing DB connection parameters and temp directory
 --save_tmpfiles   Save the temp files used for loading the database
 --logfile         Output error messages to this file

=head1 DESCRIPTION

This program is a wrapper that calls genbank_to_genodo.pl and genbank_fasta_loader.pl to load
individual genomes obtained from Genbank.  It operates on all genbank and fasta files in a 
directory.

A record of the failed and completed jobs is placed in a file called genbank_bulk_loader.log 
in the genbank directory, so that program can be restarted and previously loaded jobs will
not be reloaded.

All warnings and fatal errors will be output to the logfile specified on the command-line.

The temporary directory will contain the intermediate files needed by the called programs.

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($CONFIGFILE, $FASTADIR, $GBDIR, $LOGFILE, $SAVE_TMPFILES, $DEBUG, $TMPDIR);

GetOptions(
	'configfile=s'=> \$CONFIGFILE,
    'fastadir=s'=> \$FASTADIR,
    'gbdir=s'=> \$GBDIR,
    'logfile=s'=> \$LOGFILE,
    'save_tmpfiles'=>\$SAVE_TMPFILES,
    'debug'   => \$DEBUG,
) 
or pod2usage(-verbose => 1, -exitval => 1);

# Get temp directory and db connection params
die "You must supply a configuration filename" unless $CONFIGFILE;
my ($dbsource, $dbpass, $dbuser);
if(my $conf = new Config::Simple($CONFIGFILE)) {
	$TMPDIR    = $conf->param('tmp.dir');
	my $dbname    = $conf->param('db.name');
	$dbuser       = $conf->param('db.user');
	$dbpass       = $conf->param('db.pass');
	my $dbhost    = $conf->param('db.host');
	my $dbport    = $conf->param('db.port');
	my $dbi       = $conf->param('db.dbi');
	
	$dbsource = 'dbi:' . $dbi . ':dbname=' . $dbname . ';host=' . $dbhost;
	$dbsource . ';port=' . $dbport if $dbport;
} else {
	die Config::Simple->error();
}
croak "Invalid configuration file." unless $TMPDIR && $dbsource && $dbuser && $dbpass;

# Connect to DB
my $schema = Database::Chado::Schema->connect($dbsource, $dbuser, $dbpass) or croak "Error: could not connect to database.";

# Obtain list of fasta files
opendir(DIR, $FASTADIR) || die "Error: can't opendir $FASTADIR ($!).\n";
my @fasta_files = grep { -f "$FASTADIR/$_" } readdir(DIR);
closedir DIR;

# Load failed and completed jobs for this directory
croak "Error: $GBDIR is not a valid directory." unless -d $GBDIR;
my $job_file = $GBDIR . 'genbank_bulk_loader.log';

my %completed_jobs;
if(-e $job_file) {
	open(IN, "<$job_file") or croak "Error: unable to open file $job_file ($!).\n";
	while(<IN>) {
		chomp;
		next if m/^#/;
		my ($file,$status) = split(/\t/,$_);
		if($status eq 'completed') {
			$completed_jobs{$file}=1;
		}
	}
	close IN;
}
my $timestamp = localtime(time);
open(my $jobfh, ">$job_file") or croak "Error: unable to open file $job_file ($!).\n";
print $jobfh "# timestamp: $timestamp\n";

# Open log
open(LOG, ">$LOGFILE") or croak "Error: unable to open file $job_file ($!).\n";

print LOG "# script: genbank_bulk_loader.pl\n# time: $timestamp\n\n";

# Iterate through fasta/genbank file pairs loading them into DB
foreach my $fasta_file (@fasta_files) {
	
	my ($filename) = ($fasta_file =~ m/(\w+)(\.fasta)?$/);
	
	print LOG "Loading $filename...\n";
	
	if($completed_jobs{$filename}) {
		print $jobfh "$filename\tcompleted\n";
		print LOG "\tpreviously loaded.\n";
		next;
	}
	
	# Check there is a corresponding genbank file
	my $genbank_file = "$GBDIR$filename\_fixed.gbk";
	unless(-e $genbank_file) {
		print $jobfh "$filename\tfailed\n";
		print LOG "***FATAL ERROR*** missing genbank file\n\n";
		next;
	}
	
	# Create genodo properties file
	my $genodo_file = $TMPDIR ."$filename.genodo";
	my $curr_wd = getcwd;
	my $command = "perl $curr_wd/genbank_to_genodo.pl";
	my @args = ($command,
		"--gbfile $genbank_file",
		"--configfile $CONFIGFILE",
		"--propfile $genodo_file");
		
	my $cmd =  join(" ",@args);
	
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	unless($success) {
		print $jobfh "$filename\tfailed\n";
		print LOG "\terrors:\n$stderr\n$exit_code\n";
		print LOG "\tgenbank file processing failed.\n\n";
		unlink $genodo_file unless $SAVE_TMPFILES;
		next;
	} else {
		print LOG "\twarnings:\n$stderr\n";
		print LOG "\tgenbank to genodo conversion completed.\n\n";
	}
	
	
	
	# Check that this genome is not already in the DB
	
	# Check this by looking for identical primary accession IDs
	my $genome_properties = load_genome_parameters($genodo_file);
	my $accession = $genome_properties->{primary_dbxref}->[0]->{acc};

	my $rs = $schema->resultset('Feature')->search( 
		{
			'dbxref.accession' => $accession	
		},
		{
			join => ['dbxref']
		}
	);

	if($rs->first) {
		print $jobfh "$filename\tfailed\n";
                print LOG "***FATAL ERROR*** appears sequence is already in DB\n\n";
		print LOG "\tDB loading failed.\n\n";
                unlink $genodo_file unless $SAVE_TMPFILES;
                next;	
	}
		
	
	# Call loading script
	my $real_fasta_file = "$FASTADIR$fasta_file";
        $command = "perl $curr_wd/genodo_fasta_loader.pl";
        @args = ($command,
                "--fastafile $real_fasta_file",
                "--configfile $CONFIGFILE",
                "--propfile $genodo_file",
                "--recreate_cache"  # Do this everytime, don't want to screw up names just because we forgot to sync the cache
		);

       $cmd =  join(" ",@args);

        ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);

        unless($success) {
                print $jobfh "$filename\tfailed\n";
                print LOG "\terrors:\n$stderr\n$exit_code\n";
                print LOG "\tDB loading failed.\n\n";
                unlink $genodo_file unless $SAVE_TMPFILES;
                next;
        } else {
                print $jobfh "$filename\tcompleted\n";
                print LOG "\twarnings:\n$stderr\n";
                print LOG "\tDB loading completed.\n\n";
        }

	
	# Clean up
	unlink $genodo_file unless $SAVE_TMPFILES;
}




=head2 load_genome_parameters

loads hash produced by Data::Dumper with genome properties and upload user settings.

=cut

sub load_genome_parameters {
    my $file = shift;

    open(IN, "<$file") or die "Error: unable to read file $file ($!).\n";

    local($/) = "";
    my($str) = <IN>;

    close IN;

    my $contig_collection_properties;
    eval $str;

    return ($contig_collection_properties);
}

