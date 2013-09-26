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

$0 - loads multi-fasta file into a genodo's chado database. Fasta file contains genomic or shotgun contig sequences.

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --fastafile       BLAST file to load sequence from
 --configfile      INI style config file containing DB connection parameters
 --noload          Create bulk load files, but don't actually load them.
 --recreate_cache  Causes the uniquename cache to be recreated
 --remove_lock     Remove the lock to allow a new process to run
 --save_tmpfiles   Save the temp files used for loading the database
 --manual          Detailed manual pages
 --webupload       Indicates that genome is user uploaded. Loads to private tables.

=head1 DESCRIPTION

A contig_collection is the parent label used for a set of DNA sequences belonging to a 
single project (which may be a WGS or a completed whole genome sequence). Global properties 
such as strain, host etc are defined at the contig_collection level.  The contig_collection 
properties are defined in a hash that is written to file using Data::Dumper. Multiple values
are permitted for any data type with the exception of name or uniquename.  Multiple values are
passed as an array ref. The first item on the list is assigned rank 0, and so on.

Each sequence in the fasta files is labelled as a contig (whether is its a chromosome or true contig). 
The contig properties are obtained from the fasta file. Names for the contigs are obtained from 
the accessions in the fasta file.  The fasta file header lines are also used to define the mol_type 
as chromosome or plasmid.
  
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
		isolation_source => 'Blood'
		synonym => 'gamma',
		isolation_date => '1999-03-13',
		description => 'Its a genome!!',
		comment => 'infection from someone\'s nasty hot tub',
		owner => 'kermit the frog',
		isolation_age => 123.34,
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
		},
		pmid => [123456, 78901010]
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

=head2 NOTES

=over

=item Transactions

This application will, by default, try to load all of the data at
once as a single transcation.  This is safer from the database's
point of view, since if anything bad happens during the load, the 
transaction will be rolled back and the database will be untouched.

=item The run lock

The loader is not a multiuser application.  If two separate
bulk load processes try to load data into the database at the same
time, at least one and possibly all loads will fail.  To keep this from
happening, the bulk loader places a lock in the database to prevent
other processes from running at the same time.
When the application exits normally, this lock will be removed, but if
it crashes for some reason, the lock will not be removed.  To remove the
lock from the command line, provide the flag --remove_lock.  Note that
if the loader crashed necessitating the removal of the lock, you also
may need to rebuild the uniquename cache (see the next section).

=item The uniquename cache

The loader uses the chado database to create a table that caches
feature_ids, uniquenames, type_ids, and organism_ids of the features
that exist in the database at the time the load starts and the
features that will be added when the load is complete.  If it is possilbe
that new features have been added via some method that is not this
loader (eg, Apollo edits or loads with XORT) or if a previous load using
this loader was aborted, then you should supply
the --recreate_cache option to make sure the cache is fresh.

=back

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Adapted from original package developed by 
Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($CONFIGFILE, $BLASTFILE, $NOLOAD,
    $RECREATE_CACHE, $SAVE_TMPFILES,
    $MANPAGE, $DEBUG,
    $REMOVE_LOCK,
    $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI, $TMPDIR,
    $VACUUM,
    $WEBUPLOAD, $TRACKINGID);

GetOptions(
	'configfile=s'=> \$CONFIGFILE,
    'blastfile=s'=> \$BLASTFILE,
    'noload'     => \$NOLOAD,
    'recreate_cache'=> \$RECREATE_CACHE,
    'remove_lock'   => \$REMOVE_LOCK,
    'save_tmpfiles'=>\$SAVE_TMPFILES,
    'manual'   => \$MANPAGE,
    'debug'   => \$DEBUG,
    'vacuum'  => \$VACUUM,
    'webupload' => \$WEBUPLOAD,
    'tracking_id:s' => \$TRACKINGID
) 

or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $MANPAGE;

$SIG{__DIE__} = $SIG{INT} = 'cleanup_handler';

croak "You must supply an BLAST filename" unless $BLASTFILE;

# Load database connection info from config file
die "You must supply a configuration filename" unless $CONFIGFILE;
if(my $db_conf = new Config::Simple($CONFIGFILE)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
	$TMPDIR    = $db_conf->param('tmp.dir');
} else {
	die Config::Simple->error();
}
croak "Invalid configuration file." unless $DBNAME;

# Initialize the chado adapter
my %argv;

$argv{dbname}         = $DBNAME;
$argv{dbuser}         = $DBUSER;
$argv{dbpass}         = $DBPASS;
$argv{dbhost}         = $DBHOST;
$argv{dbport}         = $DBPORT;
$argv{dbi}            = $DBI;
$argv{tmp_dir}        = $TMPDIR;
$argv{noload}         = $NOLOAD;
$argv{recreate_cache} = $RECREATE_CACHE;
$argv{save_tmpfiles}  = $SAVE_TMPFILES;
$argv{web_upload}     = $WEBUPLOAD;
$argv{vacuum}         = $VACUUM;
$argv{debug}          = $DEBUG;
  
my $chado = Sequences::Adapter->new(%argv);


# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;


# Prepare tmp files for storing upload data
$chado->file_handles();


# Save data for inserting into database
warn "Preparing data for inserting into the $DBNAME database\n";
warn "(This may take a while ...)\n";




# Create parent feature: contig_collection
contig_collection($f, $fp, $dx);


# Create child features from FASTA file (i.e. contigs)
my $in = Bio::SeqIO->new(-file   => $FASTAFILE,
                         -format => 'fasta');
                              
while (my $entry = $in->next_seq) {
	
	contig($entry);
}


# Finalize and load into DB

$chado->end_files();

$chado->flush_caches();

$chado->load_data() unless $NOLOAD;

if($WEBUPLOAD && $TRACKINGID && !$NOLOAD) {
	$chado->update_tracker($TRACKINGID, $upload_id);
}

$chado->remove_lock();

exit(0);

=cut

=head2 cleanup_handler

=over

=item Usage

  cleanup_handler

=item Function

Removes table lock and any entries added to the uniquename change in tmp table.

=item Returns

void

=item Arguments

filename of Data::Dumper file containing data hash.

=back

=cut

sub cleanup_handler {
    warn "@_\nAbnormal termination, trying to clean up...\n\n" if @_;  #gets the message that the die signal sent if there is one
    if ($chado && $chado->dbh->ping) {
        
        $chado->cleanup_tmp_table;
        if ($lock) {
            warn "Trying to remove the run lock (so that --remove_lock won't be needed)...\n";
            $chado->remove_lock; #remove the lock only if we've set it
        }
        
        print STDERR "Exiting...\n";
    }
    exit(1);
}

=head2 allele


=cut

sub allele {
	my $blastline = @_;
	
	# Parse blast line
	
	# contig / contig_collection
	my @blast_values = split(/\t/, $blastline);
	
	my ($contig, $contig_collection) = ($blast_values[0] =~ m/(\w+)\|(\w+)/);
	
	croak "Missing contig/contig collection ID on line: $blastline\n" unless $contig && $contig_collection;
	
	my ($access, $contig_id) = ($contig =~ m/(public|private)_(\d+)/);
	my ($tmp, $contig_collection_id) = ($contig_collection =~ m/(public|private)_(\d+)/);
	
	croak "Invalid contig ID format: $contig\n" unless $access && $contig_id;
	croak "Invalid contig_collection ID format: $contig_collection\n" unless $tmp && $contig_collection_id;
	croak "contig and contig_collection IDs are invalid.\n" unless $access eq $tmp;
	
	my $is_public = $access eq 'public' ? 1 : 0;
	
	# query gene
	my ($query_id, $query_name) = ($blast_values[1] =~ m/(\d+)\|(.+)/);
	croak "Missing query gene ID on line: $blastline\n" unless $query_id && $query_name;
	
	# contig sequence positions
	my $start = $blast_values[2];
	my $end = $blast_values[3];
	
	# percent identity
	my $perc_id = $blast_values[8];
	
	# Create allele feature
	
	# from parent
	my $collection_info = $chado->collection($contig_collection_id, $is_public);
	my $contig_info = $chado->contig($contig, $is_public);
	
	# ID
	my $curr_feature_id = $chado->nextfeature($is_public);
	
	# organism
	my $organism = $collection_info->{organism};
	
	# type 
	my $type = $chado->feature_type('allele');
	
	# sequence
	my ($seqlen, $residues, $min, $max, $strand);
	if($start > $end) {
		# rev strand
		$max = $start+1; #interbase numbering
		$min = $end;
		$strand = -1;
	} else {
		# forward strand
		$max = $end+1; #interbase numbering
		$min = $start;
		$strand = 1;
		
	}
	croak "Invalid contig BLAST hit positions (HSP end beyond end of sequence).\n" if($max > $contig_info->{len});
	$seqlen = $max - $min;
	$residues = substr($contig_info->{sequence}, $min, $seqlen);
	$residues = $chado->reverse_complement($residues) if $strand == -1;
	
	
	# External accessions
	my $dbxref = '\N';
	
	# uniquename
	my $uniquename = $collection_info->{name} . " allele_of $query_name";
	my $name = "$query_name allele";
	$uniquename = $chado->uniquename_validation($uniquename, $type, $curr_feature_id);
	
	# Feature relationships
	$chado->handle_parent($curr_feature_id, $contig_collection_id, $contig_id, $is_public);
	
	$chado->handle_query_hit($curr_feature_id, $query_id, $is_public);
	
	# Additional Feature Types
	$chado->add_types($curr_feature_id, $is_public);
	
	# Sequence location
	$chado->handle_location($curr_feature_id, $contig_id, $min, $max, $strand, $is_public);
	
	# Blast results
	my $upload_id;
	
	if(!$is_public) {
		$upload_id = $collection_info->{upload};
	}
	
	$chado->handle_properties($curr_feature_id, $perc_id, $is_public, $upload_id);
	
	# Print feature
	$chado->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues, $is_public, $upload_id);  
	$chado->nextfeature($is_public, '++');
	
	
	
	
}


=head2 contig_collection


=cut

sub contig_collection {
	my ($f, $fp, $dx) = @_;
	
	# Make sure organism is one of the permitted Organisms
	$chado->organism('common_name' => $f->{organism});
	
	# Feature type of parent: contig_collection
	my $type = $chado->feature_types('contig_collection');
	
	# Feature_id 
	my $curr_feature_id = $chado->nextfeature();
	
	# Uniquename
	my $uniquename = $f->{'uniquename'};
	
	# Verifies if name is unique, otherwise modify uniquename so that it is unique.
	$uniquename = $chado->uniquename_validation($uniquename,
		$type,
	    $curr_feature_id);
	    
	## Note uniquename may have changed and changed name will have been cached. Do we need to know original?
	
	# Name
	my $name = $f->{name};
	
	# Sequence Length
	my $seqlen = '\N';
	# Residues
	my $residues = '\N';
	
	
	# Properties
	if(%$fp) {
		$chado->handle_reserved_properties($curr_feature_id, $fp);
	}
	
	
	# Dbxref
	if(%$dx) {
		$chado->handle_dbxref($curr_feature_id, $dx);
	}
	
	
	# Save as parent
	$chado->cache('const', 'contig_collection_id', $curr_feature_id);
	$chado->cache('const', 'contig_collection_uniquename', $uniquename);
	
	# Print  
	$chado->print_f($curr_feature_id, $chado->organism, $name, $uniquename, $type, $seqlen, $chado->cache('source', $curr_feature_id), $residues);  
	$chado->nextfeature('++');
	
}

=head2 contig


=cut

sub contig {
	my ($contig) = @_;
	
	# Feature type of child: contig
	my $type = $chado->feature_types('contig');
	
	
	# Feature_id 
	my $curr_feature_id = $chado->nextfeature();
	
	
	# Uniquename and name
	my $uniquename = $contig->display_id;
	my $name = $uniquename;
	
	# Create unique contig name derived from contig_collection uniquename
	# Since contig_collection uniquename is guaranteed unique, contig name should be unique.
	# Saves us from doing a DB query on the many contigs that could be in the fasta file.
	my $cc_name = $chado->cache('const','contig_collection_uniquename');
	$uniquename .= "- part_of:$cc_name";
	

	# Sequence Length
	my $seqlen = $contig->length;
	# Residues
	my $residues = $contig->seq();
	
	
	# DBxref
	my $dbxref = '\N';
	
	
	# Contig properties
	my %contig_fp;
	
	# mol_type
	# if plasmid or chromosome is in header, change default
	my $mol_type = 'dna';
	
	# description
	if(my $desc = $contig->description) {
		# if plasmid or chromosome is in header, change default
		if($desc =~ m/plasmid/i || $name =~ m/plasmid/i) {
			$mol_type = 'plasmid';
		} elsif($desc =~ m/chromosome/i || $name =~ m/chromosome/i) {
			$mol_type = 'chromosome';
		}
	
		$contig_fp{description} = $desc;
	} else {
		if($name =~ m/plasmid/i) {
			$mol_type = 'plasmid';
		} elsif($name =~ m/chromosome/i) {
			$mol_type = 'chromosome';
		}
	}
	$contig_fp{mol_type} = $mol_type;
	
	$chado->handle_reserved_properties($curr_feature_id, \%contig_fp);
	
	
	# Feature relationships
	$chado->handle_parent($curr_feature_id);
	
	
	# Print  
	$chado->print_f($curr_feature_id, $chado->organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues);  
	$chado->nextfeature('++');
}
