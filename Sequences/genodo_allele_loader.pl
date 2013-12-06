#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Sys::Hostname;
use Config::Simple;
use ExperimentalFeatures;
use FindBin;
use lib "$FindBin::Bin/..";
use Phylogeny::TreeBuilder;
use Phylogeny::Tree;
use Time::HiRes qw( time );

=head1 NAME

$0 - loads multi-fasta file into a genodo's chado database. Fasta file contains genomic or shotgun contig sequences.

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --fasta           BLAST file to load sequence from
 --config          INI style config file containing DB connection parameters
 --noload          Create bulk load files, but don't actually load them.
 --recreate_cache  Causes the uniquename cache to be recreated
 --remove_lock     Remove the lock to allow a new process to run
 --save_tmpfiles   Save the temp files used for loading the database
 --manual          Detailed manual pages

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

=item single allele per genome

There is no way to map information in the pan_genome.txt file to the sequences
in the locus_alleles.fasta if there are multiple alleles per genome for a single
locus. Allele sequences in the fasta file are labelled by genome ID only, they need
a allele copy # to distinguish between multiple copies in one genome or contig.

The code relies on this assumption and in several places, caches allele information
such as start, stop coords by genome ID and locus ID. This would need to change
if multiple alleles per genome are allowed.

=back

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Adapted from original package developed by 
Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($CONFIGFILE, $FASTAFILE, $PANFILE, $NOLOAD,
    $RECREATE_CACHE, $SAVE_TMPFILES,
    $MANPAGE, $DEBUG,
    $REMOVE_LOCK,
    $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI, $TMPDIR,
    $VACUUM);

GetOptions(
	'config=s' => \$CONFIGFILE,
    'fasta=s' => \$FASTAFILE,
    'pan=s' => \$PANFILE,
    'noload' => \$NOLOAD,
    'recreate_cache'=> \$RECREATE_CACHE,
    'remove_lock'  => \$REMOVE_LOCK,
    'save_tmpfiles'=>\$SAVE_TMPFILES,
    'manual' => \$MANPAGE,
    'debug' => \$DEBUG,
    'vacuum' => \$VACUUM
) 
or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $MANPAGE;


$SIG{__DIE__} = $SIG{INT} = 'cleanup_handler';


croak "You must supply an FASTA filename" unless $FASTAFILE;
croak "You must supply an Panseq pan-genome filename" unless $PANFILE;


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
$argv{vacuum}         = $VACUUM;
$argv{debug}          = $DEBUG;

my $chado = Sequences::ExperimentalFeatures->new(%argv);

# Intialize the Tree building module
my $tree_builder = Phylogeny::TreeBuilder->new();
my $tree_io = Phylogeny::Tree->new(config => $CONFIGFILE);


# BEGIN
my $now = time();

# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;

# Prepare tmp files for storing upload data
$chado->file_handles();

# Save data for inserting into database
elapsed_time('db init');

# Load locus locations
my %loci;
open(my $in, "<", $PANFILE) or croak "Error: unable to read file $PANFILE ($!).\n";
<$in>; # header line
while (my $line = <$in>) {
	chomp $line;
	
	my ($id, $locus, $genome, $allele, $start, $end, $header) = split(/\t/,$line);
	
	if($allele > 0) {
		# Hit
		
		# query gene
		my ($query_id, $query_name) = ($locus =~ m/(\d+)\|(.+)/);
		croak "Missing query gene ID in locus line: $locus\n" unless $query_id && $query_name;
	
		my ($contig) = $header =~ m/lcl\|\w+\|(\w+)/;
		$loci{$query_id}->{$genome} = {
			allele => $allele,
			start => $start,
			end => $end,
			contig => $contig
		};
	}
	
}

close $in;
elapsed_time('positions loaded');

# Load allele sequences

{
	# Slurp a group of fasta sequences for each locus.
	# This could be disasterous if the memory req'd is large (swap-thrashing yikes!)
	# otherwise, this should be faster than line-by-line.
	# Also assumes specific FASTA format (i.e. sequence and header contain no line breaks or spaces)
	open (my $in, "<", $FASTAFILE) or croak "Error: unable to read file $FASTAFILE ($!).\n";
	local $/ = "\nLocus ";
	
	while(my $locus_block = <$in>) {
		$locus_block =~ s/^Locus //;
		my ($locus) = ($locus_block =~ m/^(\S+)/);
		my %sequence_group;
		
		# query gene
		my ($query_id, $query_name) = ($locus =~ m/(\d+)\|(.+)/);
		croak "Missing query gene ID in locus line: $locus\n" unless $query_id && $query_name;
		
		while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
			my $header = $1;
			my $seq = $2;
		
			# Load the sequence
			allele($query_id,$query_name,$header,$seq,\%sequence_group);
			
		}
		
		# Build tree
		build_tree($query_id, \%sequence_group);
	}
	close $in;
	
}

elapsed_time("sequences parsed");

# Finalize and load into DB

$chado->end_files();

$chado->flush_caches();

$chado->load_data() unless $NOLOAD;

$chado->remove_lock();

elapsed_time("data loaded");

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
	my ($query_id, $query_name, $header, $seq, $seq_group) = @_;
	
	# Parse input
	
	# contig_collection
	my $contig_collection = $header;
	my ($access, $contig_collection_id) = ($contig_collection =~ m/lcl\|(public|private)_(\d+)/);
	croak "Invalid contig_collection ID format: $contig_collection\n" unless $access;
	
	# privacy setting
	my $is_public = $access eq 'public' ? 1 : 0;
	my $pub_value = $is_public ? 'TRUE' : 'FALSE';
	
	# location hash
	my $loc_hash = $loci{$query_id}->{$header};
	croak "Missing location information for locus allele $query_id in contig $header.\n" unless defined $loc_hash;
	
	# contig
	my $contig = $loc_hash->{contig};
	my ($access2, $contig_id) = ($contig =~ m/\|(public|private)_(\d+)$/);
	
	# contig sequence positions
	my $start = $loc_hash->{start};
	my $end = $loc_hash->{end};
	my $allele_num = $loc_hash->{allele};
	
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
	
	$seqlen = $max - $min;
	$residues = $seq;
	
	# type 
	my $type = $chado->feature_types('allele');
	
	# uniquename - based on contig location and so should be unique (can't have duplicate alleles at same spot) 
	my $uniquename = "allele:$contig_id.$min.$max.$is_public";
	
	# Check if this allele is already in DB
	my $allele_id = $chado->validate_allele($query_id,$contig_collection_id,$uniquename,$pub_value);
	my $is_new = 1;
	
	if($allele_id) {
		# UPDATE
		# allele was created in previous analysis
		$is_new = 0;
		
		# update feature sequence
		$chado->print_uf($allele_id,$uniquename,$type,$seqlen,$residues,$is_public);
		
		# update feature location
		$chado->print_ufloc($allele_id,$min,$max,$strand,0,0,$is_public);
		
		# update feature properties
		$chado->print_ufprop($allele_id,$chado->featureprop_types('copy_number_increase'),$allele_num,0,$is_public);
		
	} else {
		# NEW
		# Create allele feature
		
		# ID
		my $curr_feature_id = $chado->nextfeature($is_public);
	
		# retrieve genome data
		my $collection_info = $chado->collection($contig_collection_id, $is_public);
		#my $contig_info = $chado->contig($contig_id, $is_public);
		
		# organism
		my $organism = $collection_info->{organism};
		
		# external accessions
		my $dbxref = '\N';
		
		# uniquename & name
		my $name = "$query_name allele";
		$chado->uniquename_validation($uniquename, $type, $curr_feature_id, $is_public);
		
		# Feature relationships
		$chado->handle_parent($curr_feature_id, $contig_collection_id, $contig_id, $is_public);
		$chado->handle_query_hit($curr_feature_id, $query_id, $is_public);
		
		# Additional Feature Types
		$chado->add_types($curr_feature_id, $is_public);
		
		# Sequence location
		$chado->handle_location($curr_feature_id, $contig_id, $min, $max, $strand, $is_public);
		
		# Feature properties
		my $upload_id = $is_public ? undef : $collection_info->{upload};
		$chado->handle_allele_properties($curr_feature_id, $allele_num, $is_public, $upload_id);
		
		# Print feature
		$chado->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues, $is_public, $upload_id);  
		$chado->nextfeature($is_public, '++');
		
		# Update cache
		$chado->loci_cache(feature_id => $curr_feature_id, uniquename => $uniquename, type_id => $type, genome_id => $contig_collection_id,
			contig_id => $contig_id, query_id => $query_id, is_public => $pub_value);
			
		$allele_id = $curr_feature_id;
	}
	
	$seq_group->{$contig_collection} = {
		genome => $contig_collection_id,
		allele => $allele_id,
		#copy => $allele_num,
		public => $is_public,
		is_new => $is_new,
		seq => $seq
	};
	
}

sub build_tree {
	my ($query_id, $seq_grp) = @_;
	
	return unless scalar keys %$seq_grp > 2; # only build trees for groups of 3 or more 
	
	# write alignment file
	my $tmp_file = '/tmp/genodo_allele_aln.txt';
	open(my $out, ">", $tmp_file) or croak "Error: unable to write to file $tmp_file ($!).\n";
	foreach my $id (keys %$seq_grp) {
		print $out join("\n",">".$id,$seq_grp->{$id}->{seq}),"\n";
	}
	close $out;
	
	# clear output file for safety
	my $tree_file = '/tmp/genodo_allele_tree.txt';
	open($out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
	close $out;
	
	# build newick tree
	$tree_builder->build_tree($tmp_file, $tree_file) or croak;
	
	# slurp tree and convert to perl format
	my $tree = $tree_io->newickToPerlString($tree_file);
	
	# store tree in tables
	$chado->handle_phylogeny($tree, $query_id, $seq_grp);
	
	return($tmp_file);
}

sub elapsed_time {
	my ($mes) = @_;
	
	my $time = $now;
	$now = time();
	printf("$mes: %.2f\n", $now - $time);
	
}

