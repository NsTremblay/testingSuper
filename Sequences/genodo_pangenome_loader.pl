#!/usr/bin/env perl

=head1 NAME

$0 - Processes a fasta file of pangenome sequence fragments and uploads into the feature table of the database specified in the config file.

=head1 SYNOPSIS
	
	% genodo_pangenome_loader.pl [options]

=head1 COMMAND-LINE OPTIONS

	--panseq            Optionally, specify a panseq results output directory. If not provided, script will download genome from DB.
	--config 			Specify a valid config file with db connection params.

=head1 DESCRIPTION



=head1 AUTHOR

Matt Whiteside

=cut

use strict;
use warnings;

use Getopt::Long;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use ExperimentalFeatures;
use Config::Simple;
use Carp qw/croak carp/;
use File::Path qw/remove_tree/;
use Phylogeny::TreeBuilder;
use Phylogeny::Tree;
use IO::CaptureOutput qw(capture_exec);


# Globals (set these to match local values)
my $muscle_exe = '/usr/bin/muscle';
my $mummer_dir = '/home/matt/MUMmer3.23/';
my $blast_dir = '/home/matt/blast/bin/';
my $parallel_exe = '/usr/bin/parallel';
my $nr_location = '/home/matt/blast_databases/gammaproteobacteria_nr';
my $panseq_exe = '/home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl';

$SIG{__DIE__} = $SIG{INT} = 'cleanup_handler';


# Parse command-line
my ($panseq_dir, $config_file,
	$NOLOAD, $RECREATE_CACHE, $SAVE_TMPFILES, $DEBUG,
    $REMOVE_LOCK,
    $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI, $TMPDIR,
    $VACUUM);
GetOptions(
	'panseq=s' => \$panseq_dir,
	'config=s' => \$config_file,
	'noload' => \$NOLOAD,
	'recreate_cache'=> \$RECREATE_CACHE,
	'remove_lock'  => \$REMOVE_LOCK,
	'save_tmpfiles'=>\$SAVE_TMPFILES,
	'debug' => \$DEBUG,
	'vacuum' => \$VACUUM
) or ( system( 'pod2text', $0 ), exit -1 );

croak "[Error] missing argument. You must supply a valid config file\n" . system('pod2text', $0) unless $config_file;


# Connect to DB
my ($dbname, $dbuser, $dbpass, $dbhost, $dbport, $dbi, $tmp_dir);

if(my $db_conf = new Config::Simple($config_file)) {
	$dbname    = $db_conf->param('db.name');
	$dbuser    = $db_conf->param('db.user');
	$dbpass    = $db_conf->param('db.pass');
	$dbhost    = $db_conf->param('db.host');
	$dbport    = $db_conf->param('db.port');
	$dbi       = $db_conf->param('db.dbi');
	$tmp_dir   = $db_conf->param('tmp.dir');
} 
else {
	croak "[Error] unable to read configuration file ( " . Config::Simple->error() . ").\n";
}

croak "[Error] invalid configuration file." unless $dbname;

my $dbsource = 'dbi:' . $dbi . ':dbname=' . $dbname . ';host=' . $dbhost;
$dbsource . ';port=' . $dbport if $dbport;

my $schema = Database::Chado::Schema->connect($dbsource, $dbuser, $dbpass) or croak "Error: could not connect to database ($!).\n";

# Initialize the chado adapter
my %argv;

$argv{dbname}         = $dbname;
$argv{dbuser}         = $dbuser;
$argv{dbpass}         = $dbpass;
$argv{dbhost}         = $dbhost;
$argv{dbport}         = $dbport;
$argv{dbi}            = $dbi;
$argv{tmp_dir}        = $tmp_dir;
$argv{noload}         = $NOLOAD;
$argv{recreate_cache} = $RECREATE_CACHE;
$argv{save_tmpfiles}  = $SAVE_TMPFILES;
$argv{vacuum}         = $VACUUM;
$argv{debug}          = $DEBUG;
$argv{snp_capable}    = 1;

my $chado = Sequences::ExperimentalFeatures->new(%argv);

# Intialize the Tree building module
my $tree_builder = Phylogeny::TreeBuilder->new();
my $tree_io = Phylogeny::Tree->new(dbix_schema => $schema);

# BEGIN
my $now = time();

# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;

# Prepare tmp files for storing upload data
$chado->file_handles();


# Run pan-seq
unless($panseq_dir) {
	print "Running panseq...\n";
	
	my $root_dir = $tmp_dir . 'panseq_pangenome/';
	unless (-e $root_dir) {
		mkdir $root_dir or croak "[Error] unable to create directory $root_dir ($!).\n";
	}
	
	# Download all genome sequences
	print "\tdownloading genome sequences...\n";
	my $fasta_dir = $root_dir . '/fasta/';
	unless (-e $fasta_dir) {
		mkdir $fasta_dir or croak "[Error] unable to create directory $fasta_dir ($!).\n";
	}
	my $fasta_file = $fasta_dir . 'genomes.ffn';
	
	my $cmd = "perl $FindBin::Bin/../Database/contig_fasta2.pl --config $config_file --output $fasta_file";
	system($cmd) == 0 or croak "[Error] download of contig sequences failed (syscmd: $cmd).\n";
	print "\tcomplete\n";
	
	# Run panseq
	print "\tpreparing panseq input...\n";
	$panseq_dir = $root_dir . 'panseq/';
	if(-e $panseq_dir) {
		remove_tree $panseq_dir or croak "[Error] unable to delete directory $panseq_dir ($!).\n";
	}
	
	my $pan_cfg_file = $root_dir . 'pg.conf';
	my $core_threshold = 3;
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out
qq|queryDirectory	$fasta_dir
baseDirectory	$panseq_dir
numberOfCores	8
mummerDirectory	$mummer_dir
blastDirectory	$blast_dir
minimumNovelRegionSize	1000
novelRegionFinderMode	no_duplicates
muscleExecutable	$muscle_exe
fragmentationSize	1000
percentIdentityCutoff	90
coreGenomeThreshold	$core_threshold
runMode	pan
storeAlleles	1
nameOrId	name
|;
	close $out;
	
	my @loading_args = ($panseq_exe,
	$pan_cfg_file);
	print "\tcomplete\n";
	
	print "\trunning panseq...\n";
	$cmd = join(' ', @loading_args);
	system($cmd) == 0 or croak "[Error] Panseq analysis failed.\n";
	print "\tcomplete\n";
	
	# Blast pangenome regions
	my $input_fasta = $panseq_dir . 'panGenomeFragments.fasta';
	my $blast_file = $panseq_dir . 'anno.txt';
	my $blast_cmd = "$blast_dir/blastx -evalue 0.0001 -outfmt ".'\"6 qseqid qlen sseqid slen stitle\" '."-db $nr_location -max_target_seqs 1 -query -";
	my $num_cores = 8;
	my $filesize = -s $input_fasta;
	my $blocksize = int($filesize/$num_cores);
	#my $parallel_cmd = "cat $input_fasta | $parallel_exe --gnu -j $num_cores --block $blocksize --recstart '>' --pipe $blast_cmd > $blast_file";
	my $parallel_cmd = "grep \">\" -m 64 -A 1 $input_fasta | $parallel_exe --gnu -j $num_cores --block $blocksize --recstart '>' --pipe $blast_cmd > $blast_file";
	
	print "\trunning blast on pangenome fragments...\n";
	system($parallel_cmd) == 0 or croak "[Error] BLAST failed.\n";
	print "\tcomplete\n";
	
}

# Finalize and load into DB

# Load functions
my %anno_functions;
#my $anno_file = $panseq_dir . 'anno.txt';
#open IN, "<", $anno_file or croak "[Error] unable to read file $anno_file ($!).\n";
#
#while(<IN>) {
#	chomp;
#	my ($q, $qlen, $s, $slen, $t) = split(/\t/, $_);
#	$anno_functions{$q} = [$s,$t];
#}
#close IN;


# Load pangenome
my $core_fasta_file = $panseq_dir . 'coreGenomeFragments.fasta';
my $acc_fasta_file = $panseq_dir . 'accessoryGenomeFragments.fasta';
my @core_status = (1,0);
my $num_pg = 0;

foreach my $pan_file ($core_fasta_file, $acc_fasta_file) {
	my $in_core = shift @core_status;
	
	my $fasta = Bio::SeqIO->new(-file   => $pan_file,
							    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $pan_file ($!).";
    
	while (my $entry = $fasta->next_seq) {
		my $id = $entry->display_id;
		my $func = undef;
		my $func_id = undef;
		
		if($anno_functions{$id}) {
			($func_id, $func) = @{$anno_functions{$id}};
		}
		
		my ($locus_id, $uniquename) = ($id =~ m/^lcl\|(\d+)\|(lcl\|.+)$/);
		croak "Error: unable to parse header $id in pangenome fasta file $pan_file.\n" unless $uniquename && $locus_id;
		
		my $seq = $entry->seq;
		$seq =~ tr/-//; # Remove gaps, store only raw sequence
		
		my $pg_feature_id = $chado->handle_pangenome_segment($in_core, $func, $func_id, $seq);
		
		# Cache feature id another info for reference pangenome fragment
		$chado->cache('feature',$locus_id,$pg_feature_id);
	
		$chado->cache('core',$pg_feature_id,$in_core);
		if($in_core) {
			$chado->cache('sequence',$pg_feature_id,$seq);
		}
		$num_pg++;
	}
	
	my $data_type = ($in_core) ? 'Core':'Accessory';
	print "$data_type pangenome fragments loaded.\n";
}


# Load loci positions
my %loci;
my $positions_file = $panseq_dir . 'pan_genome.txt';
open(my $in, "<", $positions_file) or croak "Error: unable to read file $positions_file ($!).\n";
<$in>; # header line
while (my $line = <$in>) {
	chomp $line;
	
	my ($id, $genome, $allele, $start, $end, $header) = split(/\t/,$line);
	
	if($allele > 0) {
		# Hit
		
		# pangenome reference region feature ID
		my $query_id = $chado->cache('feature', $id);
		croak "Pangenome reference segement $id has no assigned feature ID\n" unless $query_id;
	
		my ($contig) = $header =~ m/lcl\|\w+\|(\w+)/;
		$loci{$query_id}->{$genome} = {
			start => $start,
			end => $end,
			contig => $contig
		};		
	}
}
print "Loci locations loaded.\n";

# Initialize / verify

my $num_done = 0;
# Load loci
{
	# Slurp a group of fasta sequences for each locus.
	# This could be disasterous if the memory req'd is large (swap-thrashing yikes!)
	# otherwise, this should be faster than line-by-line.
	# Also assumes specific FASTA format (i.e. sequence and header contain no line breaks or spaces)
	my $fasta_file = $panseq_dir . 'locus_alleles.fasta';
	open (my $in, "<", $fasta_file) or croak "Error: unable to read file $fasta_file ($!).\n";
	local $/ = "\nLocus ";
	
	while(my $locus_block = <$in>) {
		
		$locus_block =~ s/^Locus //;
		my ($locus) = ($locus_block =~ m/^(\S+)/);
		my ($locus_id, $uniquename) = ($locus =~ m/^lcl\|(\d+)\|(lcl\|.+)$/);
		croak "Error: unable to parse header $locus in the locus alleles fasta file.\n" unless $uniquename && $locus_id;
		my %sequence_group;
		
		# pangenome reference region feature ID
		my $query_id = $chado->cache('feature', $locus_id);
		croak "Pangenome reference segment $locus has no assigned feature ID\n" unless $query_id;
		
		while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
			my $header = $1;
			my $seq = $2;
		
			# Load the sequence
			pangenome_locus($query_id,$header,$seq,\%sequence_group);
			
		}
		
		# Build tree and calculate the snps
		snps_and_trees($query_id, \%sequence_group);
		
		$num_done++;
		print "Pangenome segments $num_done of $num_pg loaded.\n" if $num_done % 1000 == 0;
	}
	
	close $in;
	
}

$chado->end_files();

$chado->flush_caches();

unless ($NOLOAD) {
	$chado->load_data();
	build_genome_tree();
}

$chado->remove_lock();

$chado->elapsed_time("data loaded");

exit(0);


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

sub pangenome_locus {
	my ($query_id, $locus_id, $header, $seq, $seq_group) = @_;
	
	# Parse input
	
	# contig_collection
	my $contig_collection = $header;
	my ($access, $contig_collection_id) = ($contig_collection =~ m/(public|private)_(\d+)/);
	croak "Invalid contig_collection ID format: $contig_collection\n" unless $access;
	
	# privacy setting
	my $is_public = $access eq 'public' ? 1 : 0;
	my $pub_value = $is_public ? 'TRUE' : 'FALSE';
	
	# location hash
	my $loc_hash = $loci{$query_id}->{$header};
	croak "Missing location information for locus allele $locus_id ($query_id) in contig $header.\n" unless defined $loc_hash;
	
	# contig
	my $contig = $loc_hash->{contig};
	my ($access2, $contig_id) = ($contig =~ m/(public|private)_(\d+)/);
	
	# contig sequence positions
	my $start = $loc_hash->{start};
	my $end = $loc_hash->{end};
	
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
	my $type = $chado->feature_types('locus');
	
	# uniquename - based on contig location and so should be unique (can't have duplicate pangenome loci at same spot) 
	my $uniquename = "locus:$contig_id.$min.$max.$is_public";
	
	# Check if this allele is already in DB
	my $allele_id = $chado->validate_allele($query_id,$contig_collection_id,$uniquename,$pub_value);
	my $is_new = 1;
	
	if($allele_id) {
		# Loci was created in previous analysis
		$is_new = 0;
		
		# update feature sequence
		$chado->print_uf($allele_id,$uniquename,$type,$seqlen,$residues,$is_public);
		
		# update feature location
		$chado->print_ufloc($allele_id,$min,$max,$strand,0,0,$is_public);
		
	} else {
		# NEW
		# Create loci feature
		
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
		my $name = "$query_id locus";
		my $ok_name = $chado->uniquename_validation($uniquename, $type, $curr_feature_id, $is_public);
		unless($ok_name) {
			warn "Dropping duplicate of pangenome region $uniquename.";
			return 0;
		}
		
		# Feature relationships
		$chado->handle_parent($curr_feature_id, $contig_collection_id, $contig_id, $is_public);
		$chado->handle_pangenome_loci($curr_feature_id, $query_id, $is_public);
		
		# Additional Feature Types
		$chado->add_types($curr_feature_id, $is_public);
		
		# Sequence location
		$chado->handle_location($curr_feature_id, $contig_id, $min, $max, $strand, $is_public);
		
		# Print feature
		my $upload_id = $is_public ? undef : $collection_info->{upload};
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
		contig => $contig_id,
		public => $is_public,
		is_new => $is_new,
		seq => $seq
	};
	
}

sub snps_and_trees {
	my ($query_id, $seq_grp) = @_;
	
	my $do_tree = 0;
	my $do_snps = 0;
	my $num_seqs = scalar keys %$seq_grp;
	
	$do_tree = 1 if $num_seqs > 2; # only build trees for groups of 3 or more
	$do_snps = 1 if $chado->cache('core',$query_id) && $num_seqs > 1; # need 2 or more sequences for snps
	
	# write alignment file
	my $tmp_file = $tmp_dir . 'genodo_allele_aln.txt';
	if($do_tree || $do_snps) {
		
		open(my $out, ">", $tmp_file) or croak "Error: unable to write to file $tmp_file ($!).\n";
		foreach my $id (keys %$seq_grp) {
			print $out join("\n",">".$id,$seq_grp->{$id}->{seq}),"\n";
		}
		close $out;
	}
	
	if($do_tree) {
		
		# clear output file for safety
		my $tree_file = $tmp_dir . 'genodo_allele_tree.txt';
		open(my $out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
		close $out;
		
		# build newick tree
		$tree_builder->build_tree($tmp_file, $tree_file) or croak;
		
		# slurp tree and convert to perl format
		my $tree = $tree_io->newickToPerlString($tree_file);
		
		# store tree in tables
		$chado->handle_phylogeny($tree, $query_id, $seq_grp);
	}
	
	if($do_snps) {
		
		# Align reference sequence to already aligned alleles
		my $refseq = $chado->cache('sequence',$query_id);
		croak "No sequence found for reference pangenome segment $query_id." unless $refseq;
		
		my $refheader = "refseq_$query_id";
		my $tmp_file2 = $tmp_dir . 'genodo_reference_sequence.txt';
		open(my $out, ">", $tmp_file2) or croak "Error: unable to write to file $tmp_file2 ($!).\n";
		print $out ">$refheader\n$refseq\n";
		close $out;
		
		my $aln_file = $tmp_dir . 'genodo_pangenome_aln.txt';
		my @loading_args = ($muscle_exe, "-profile -in1 $tmp_file -in2 $tmp_file2 -out $aln_file");
		my $cmd = join(' ',@loading_args);
		
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
		unless($success) {
			die "Muscle profile alignment failed for pangenome $query_id ($stderr).";
		}
		
		# Load alignments into memory
		my $fasta = Bio::SeqIO->new(-file   => $aln_file,
							        -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $aln_file ($!).";
    
    	my $new_refseq;
    	my %new_seqs;
		while (my $entry = $fasta->next_seq) {
			my $id = $entry->display_id;
			
			if($id eq $refheader) {
				$new_refseq = $entry->seq;
			} else {
				$seq_grp->{$id}->{seq} = $entry->seq;
			}
		}
		croak "Error: aligned reference pangenome sequence not found in muscle output file.\n" unless $new_refseq;
		
		# Compute snps for each sequence relative to the reference
		my $total_snps = 0;
		foreach my $id (keys %$seq_grp) {
			
			if($seq_grp->{$id}->{is_new}) {
				my $ghash = $seq_grp->{$id};
				$total_snps++ if find_snps($new_refseq, $query_id, $ghash);
			}
			
		}
		
		if($total_snps == $num_seqs) {
			# 
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
	croak "Error: alignment lengths do not match for reference sequence $ref_id and locus sequence $contig_collection|$contig ($l vs $l2).\n$ref_seq\n$comp_seq\n" if $l != $l2;
	
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
        	
        	#$chado->print_alignment_lengths();
        	#exit(0);
        }
	}
}

sub build_genome_tree {
	
	# write alignment file
	my $tmp_file = $tmp_dir . 'genodo_genome_aln.txt';
	$tree_io->writeSnpAlignment($tmp_file);
	
	# clear output file for safety
	my $tree_file = $tmp_dir . 'genodo_genome_tree.txt';
	open(my $out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
	close $out;
	
	# build newick tree
	$tree_builder->build_tree($tmp_file, $tree_file) or croak "Error: genome tree build failed.\n";
	
	# Load tree into database
	my $tree = $tree_io->loadTree($tree_file);
	
}


