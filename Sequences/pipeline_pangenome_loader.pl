#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Sys::Hostname;
use Config::Simple;
use FindBin;
use lib "$FindBin::Bin/..";
use Sequences::ExperimentalFeatures;
use Phylogeny::Tree;
use Phylogeny::TreeBuilder;
use Time::HiRes qw( time );


=head1 NAME

$0 - loads panseq VF / AMR analysis into genodo's chado database. This program is written for use in the genodo_pipeline.pl script.

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --dir             Root directory containing subdirectories with BLAST file to load sequence from, MSA fasta files and Newick tree files.
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

my ($CONFIGFILE, $ROOT, $NOLOAD,
    $RECREATE_CACHE, $SAVE_TMPFILES,
    $MANPAGE, $DEBUG,
    $REMOVE_LOCK,
    $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI, $TMPDIR,
    $VACUUM);

GetOptions(
	'config=s' => \$CONFIGFILE,
    'dir=s' => \$ROOT,
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


croak "You must supply the path to the top-level results directory" unless $ROOT;
$ROOT .= '/' unless $ROOT =~ m/\/$/;

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

$argv{dbname}           = $DBNAME;
$argv{dbuser}           = $DBUSER;
$argv{dbpass}           = $DBPASS;
$argv{dbhost}           = $DBHOST;
$argv{dbport}           = $DBPORT;
$argv{dbi}              = $DBI;
$argv{tmp_dir}          = $TMPDIR;
$argv{noload}           = $NOLOAD;
$argv{recreate_cache}   = $RECREATE_CACHE;
$argv{save_tmpfiles}    = $SAVE_TMPFILES;
$argv{vacuum}           = $VACUUM;
$argv{debug}            = $DEBUG;
$argv{use_cached_names} = 1; # Pull contig names from DB tmp table
$argv{snp_capable}      = 1; # Prepare snp loading methods

my $chado = Sequences::ExperimentalFeatures->new(%argv);

# Intialize the Tree building module
my $tree_builder = Phylogeny::TreeBuilder->new();
my $tree_io = Phylogeny::Tree->new(config => $CONFIGFILE);

# Result files
my $allele_fasta_file = $ROOT . 'panseq_pg_results/locus_alleles.fasta';
my $allele_pos_file = $ROOT . 'panseq_pg_results/pan_genome.txt';
my $function_file = $ROOT . 'panseq_nr_results/anno.txt';
my $msa_dir = $ROOT . 'pg_msa/';
my $tree_dir = $ROOT . 'pg_tree/';


# BEGIN

# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;

# Prepare tmp files for storing upload data
$chado->file_handles();


# Save data for inserting into database

# Load function descriptions for newly detected pan-genome regions
my %func_anno;
open IN, "<", $function_file or croak "[Error] unable to read file $function_file ($!).\n";

while(<IN>) {
	chomp;
	my ($q, $qlen, $s, $slen, $t) = split(/\t/, $_);
	$func_anno{$q} = [$s,$t];
}
close IN;

# Load locus locations
my %loci;
open(my $in, "<", $allele_pos_file) or croak "Error: unable to read file $allele_pos_file ($!).\n";
<$in>; # header line
while (my $line = <$in>) {
	chomp $line;
	
	my ($id, $locus, $genome, $allele, $start, $end, $header) = split(/\t/,$line);
	
	if($allele > 0) {
		# Hit
		my ($contig) = $header =~ m/lcl\|\w+\|(\w+)/;
		$loci{$locus}->{$genome} = {
			allele => $allele,
			start => $start,
			end => $end,
			contig => $contig
		};
	}
	
}

close $in;

# Load loci sequences
my ($new, $replace, $pangenome) = load_msa();


# Create DB entries
foreach my $pgregion (keys %$new) {
	
	my %sequence_group;
	my $allele_hash = $new->{$pgregion};
	
	# pangenome
	my $query_id = $pangenome->{$pgregion}->{id};
	my $in_core = $pangenome->{$pgregion}->{core}; # should be 0
	
	my $tree_file = $query_id;
	
	if($pangenome->{$pgregion}->{novel}) {
		# If the pangenome reference is novel, add it to database
		my $func = undef;
		my $func_id = undef;
		
		if($func_anno{$pgregion}) {
			($func_id, $func) = @{$func_anno{$pgregion}};
		}
		
		my $seq = $pangenome->{$pgregion}->{seq};
		$seq =~ tr/-//; # Remove gaps, store only raw sequence
		
		my $pg_feature_id = $chado->handle_pangenome_segment($in_core, $func, $func_id, $seq);
		
		# Cache feature id info for reference pangenome fragment
		$query_id = $pg_feature_id;
		$tree_file = $pgregion;
		
	}
#	else {
#		# Update pangenome alignment sequence
#		update_reference_fragment($query_id, $pangenome->{$pgregion}->{seq});
#	}
	
	# Create DB entries for each new loci
	foreach my $header (keys %$allele_hash) {
		add_pangenome_loci($pgregion, $query_id, $header, $allele_hash->{$header}, \%sequence_group);
	}
	
	# Update sequences for loci previously loaded in DB (in case alignments have changed).
	my $update_hash = $replace->{$pgregion};
	foreach my $header (keys %$update_hash) {
		update_pangenome_loci($header, $update_hash->{$header}, \%sequence_group);
	}
	
	# Compute and load tree for this segment
	load_tree($tree_file, $query_id, \%sequence_group);
	
	# Compute and load snps for this segment
	if($in_core) {
		compute_snps($query_id, $pangenome->{$pgregion}->{seq}, \%sequence_group, $update_hash);
	}
	
}

# Finalize and load into DB

$chado->end_files();

$chado->flush_caches();

$chado->load_data() unless $NOLOAD;

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

=head2 add_pangenome_loci


=cut

sub add_pangenome_loci {
	my ($pg_key, $pg_id, $header, $seq, $seq_group) = @_;
	
	# Parse input
	
	# Parse allele FASTA header
	my $tmp_label = $header;
	my ($tracker_id) = ($tmp_label =~ m/upl_(\d+)/);
	croak "Invalid loci label: $header\n" unless $tracker_id;
	
	# privacy setting
	my $is_public = 0;
	my $pub_value = 'FALSE';
	
	# location hash
	my $loc_hash = $loci{$pg_key}->{$header};
	croak "Missing location information for pangenome region $pg_key in contig $header.\n" unless defined $loc_hash;
	
	# Retrieve contig_collection and contig feature IDs
	my $contig_num = $loc_hash->{contig};
	my ($contig_collection_id, $contig_id) = $chado->retrieve_contig_info($tracker_id, $contig_num);
	croak "Missing feature IDs in pipeline cache for tracker ID $tracker_id and contig $contig_num.\n" unless $contig_collection_id && $contig_id;
	
	# contig sequence positions
	my $start = $loc_hash->{start};
	my $end = $loc_hash->{end};
	my $allele_num = $loc_hash->{allele};
	
	# sequence
	my ($seqlen, $min, $max, $strand);
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
	
	# type 
	my $type = $chado->feature_types('locus');
	
	# uniquename - based on contig location and so should be unique (can't have duplicate loci at same spot) 
	my $uniquename = "locus:$contig_id.$min.$max.$is_public";
	
	# Check if this allele is already in DB
	my $allele_id = $chado->validate_allele($pg_id,$contig_collection_id,$uniquename,$pub_value);
	
	if($allele_id) {
		# Allele matching properties already exists in table.
		croak "Locus matching properties already exists in DB \n".
			"(query:$pg_id, cc:$contig_collection_id, c:$contig_id, un:$uniquename, public:$pub_value).";
			
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
		my $name = "$pg_id locus";
		my $ok_name = $chado->uniquename_validation($uniquename, $type, $curr_feature_id, $is_public);
		unless($ok_name) {
			die "Duplicate allele $uniquename.";
		}
		
		# Feature relationships
		$chado->handle_parent($curr_feature_id, $contig_collection_id, $contig_id, $is_public);
		$chado->handle_pangenome_loci($curr_feature_id, $pg_id, $is_public);
		
		# Additional Feature Types
		$chado->add_types($curr_feature_id, $is_public);
		
		# Sequence location
		$chado->handle_location($curr_feature_id, $contig_id, $min, $max, $strand, $is_public);
		
		# Print feature
		my $upload_id = $is_public ? undef : $collection_info->{upload};
		$chado->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $seq, $is_public, $upload_id);  
		$chado->nextfeature($is_public, '++');
		
		# Update cache
		$chado->loci_cache(feature_id => $curr_feature_id, uniquename => $uniquename, type_id => $type, genome_id => $contig_collection_id,
			contig_id => $contig_id, query_id => $pg_id, is_public => $pub_value);
			
		$allele_id = $curr_feature_id;
	}
	
	$seq_group->{$header} = {
		genome => $contig_collection_id,
		allele => $allele_id,
		#copy => $allele_num,
		public => $is_public,
		contig => $contig_id,
		is_new => 1,
		seq => $seq
	};
	
}

sub load_msa {
	
	# Hashes to store sequences for new and previously loaded genomes
	my %new;
	my %replace;
	my %pangenome;
	
	# Load allele sequences into memory
	my $loci_file = $msa_dir . "loci.txt";
	open($in, "<", $loci_file) or die "Unable to read file $loci_file containing list of loci ($!).\n";
	while(my $locus = <$in>) {
		chomp $locus;
		my ($ftype, $query_id) = ($locus =~ m/(\w+_)(\d+)/);
		croak "Missing query gene ID in locus line: $_\n" unless $query_id && $ftype;
		
		# Process locus tag to determine situation: new pangenome region, old pangenome region in core/accessory
		my $in_core;
		my $novel;
		if($ftype eq 'nr_') {
			$query_id = "nr_$query_id";
			$in_core = 0;
			$novel = 1;
		} elsif($ftype eq 'pgacc_') {
			$in_core = 0;
			$novel = 0;
		} elsif($ftype eq 'pgcor_') {
			$in_core = 1;
			$novel = 0;
		} else {
			croak "Invalid locus tag $locus in pangenome loci list loci.txt.";
		}
		
		my $msa_file = $msa_dir . "$query_id.aln";
		my $has_new = 0;
		my $has_ref = 0;
		
		my $fasta = Bio::SeqIO->new(-file   => $msa_file,
                                    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $msa_file ($!).";
    
		while (my $entry = $fasta->next_seq) {
			my $id = $entry->display_id;
			
			if($id =~ m/^upl_/) {
				# New
				$new{$locus}{$id} = $entry->seq;
				$has_new = 1;
				
			} elsif($id =~ m/^pg_(\d+)/) {
				# Reference sequence, new/old, in/out core determined from locus tag in loci.txt
				
				$pangenome{$locus} = {
					id => $1,
					seq => $entry->seq,
					novel => $novel,
					core => $in_core
				};
				die "Multiple reference pangenome sequences in alignment file $msa_file." if $has_ref;
				die "Conflicting loci names $id and $locus in fasta file and loci.txt" if $novel;
				$has_ref = 1;
				
			} elsif($id =~ m/^nr_(\d+)/) {
				# Reference sequence, new/old, in/out core determined from locus tag in loci.txt
				
				$pangenome{$locus} = {
					id => $1,
					seq => $entry->seq,
					novel => $novel,
					core => $in_core
				};
				die "Multiple reference pangenome sequences in alignment file $msa_file." if $has_ref;
				die "Conflicting loci names $id and $locus in fasta file and loci.txt" unless $novel;
				$has_ref = 1;
				
			} else {
				# Other genome loci already in DB
				$replace{$locus}{$id} = $entry->seq;
			}
		}
		
		die "Locus $locus alignment contains no new genome sequences. Why was it run then? (likely indicates error)." unless $has_new;
		die "Locus $locus alignment contains no reference pangenome sequences." unless $has_ref;
	}
	
	close $in;
	
	return(\%new, \%replace, \%pangenome);
}


sub update_pangenome_loci {
	my ($header, $seq, $seq_group) = @_;
	
	# IDs
	my ($access, $contig_collection_id, $locus_id) = ($header =~ m/(public|private)_(\d+)\|(\d+)/);
	croak "Invalid contig_collection ID format: $header\n" unless $access && $locus_id;
	
	# privacy setting
	my $is_public = $access eq 'public' ? 1 : 0;
	my $pub_value = $is_public ? 'TRUE' : 'FALSE';
	
	# alignment sequence
	my $residues = $seq;
	$seq =~ tr/-//;
	my $seqlen = length($seq);
	
	# type 
	my $type = $chado->feature_types('locus');
	
	# Only residues and seqlen get updated, the other values are non-null placeholders in the tmp table
	$chado->print_uf($locus_id,$locus_id,$type,$seqlen,$residues,$is_public);
		
	$seq_group->{$header} = {
		genome => $contig_collection_id,
		allele => $locus_id,
		#copy => 1,
		public => $is_public,
		is_new => 0
	};
}

#sub update_reference_fragment {
#	my ($pg_id, $seq) = @_;
#	
#	# privacy setting
#	my $is_public = 1; # Pangenome regions are always in public table
#	my $pub_value = 'TRUE';
#	
#	# alignment sequence
#	my $residues = $seq;
#	$seq =~ tr/-//;
#	my $seqlen = length($seq);
#	
#	# type 
#	my $type = $chado->feature_types('pangenome');
#	
#	# Only residues and seqlen get updated, the other values are non-null placeholders in the tmp table
#	$chado->print_uf($pg_id,$pg_id,$type,$seqlen,$residues,$is_public);
#}


sub load_tree {
	my ($tname, $query_id, $seq_group) = @_;
	
	return unless scalar keys %$seq_group > 2; # need 3 or more sequences for trees
	
	my $tree_file = $tree_dir . "$tname.phy";
	
	# slurp tree and convert to perl format
	my $tree = $tree_io->newickToPerlString($tree_file);
	
	# store tree in tables
	$chado->handle_phylogeny($tree, $query_id, $seq_group);
	
}


sub compute_snps {
	my ($query_id, $refseq, $seq_group, $db_snp_alignments) = @_;
	
	return unless scalar keys %$seq_group > 1; # need 2 or more sequences for snps
	
	my $ambiguous_regions = $chado->snp_audit($query_id,$refseq);
	$chado->handle_insert_blocks($ambiguous_regions, $query_id, $refseq, $db_snp_alignments) if @$ambiguous_regions;
	
	# Compute snps for each sequence relative to the reference
	foreach my $genome (keys %$seq_group) {
		
		if($seq_group->{$genome}->{is_new}) {
			my $ghash = $seq_group->{$genome};
			find_snps($refseq, $query_id, $ghash);
		}
	}
}

sub find_snps {
	my $ref_seq = shift;
	my $ref_id = shift;
	my $genome_info = shift;
	
	my $comp_seq = $genome_info->{seq};
	my $contig_collection = $genome_info->{genome};
	my $contig = $genome_info->{contig};
	my $locus = $genome_info->{allele};
	my $is_public = $genome_info->{public};
	
	# Add row in SNP alignment table for genome, if it doesn't exist
	$chado->add_snp_row($contig_collection,$is_public);
	
	# Iterate through each aligned sequence, identifying mismatches
	my $l = length($ref_seq)-1;
	my $rpos = 0;
	my $rgap_offset = 0;
	
	my $l2 = length($comp_seq)-1;
	croak "Error: alignment lengths do not match for reference sequence $ref_id and locus sequence $locus ($l vs $l2).\n" if $l != $l2;
	
	for my $i (0 .. $l) {
        my $c1 = substr($comp_seq, $i, 1);
        my $c2 = substr($ref_seq, $i, 1);
        
        # Advance position counters     
        if($c2 eq '-') {
        	$rgap_offset++;
        } else {
        	$rpos++;
        	$rgap_offset = 0 if $rgap_offset;
        }
       
        if($c1 ne $c2) {
        	# Found snp or indel
        	$chado->handle_snp($ref_id, $c2, $rpos, $rgap_offset, $contig_collection, $contig, $locus, $c1, $is_public);
        }
	}
}

sub build_genome_tree {
	
	# write alignment file
	my $tmp_file = $TMPDIR . 'genodo_genome_aln.txt';
	$tree_io->writeSnpAlignment($tmp_file);
	
	# clear output file for safety
	my $tree_file = $TMPDIR . 'genodo_genome_tree.txt';
	open(my $out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
	close $out;
	
	# build newick tree
	$tree_builder->build_tree($tmp_file, $tree_file) or croak "Error: genome tree build failed.\n";
	
	# Load tree into database
	my $tree = $tree_io->loadTree($tree_file);
	
}


