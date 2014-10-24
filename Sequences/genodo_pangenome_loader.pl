#!/usr/bin/env perl

=head1 NAME

$0 - Processes a fasta file of pangenome sequence fragments and uploads into the feature table of the database specified in the config file.

=head1 SYNOPSIS
	
	% genodo_pangenome_loader.pl [options]

=head1 COMMAND-LINE OPTIONS

	--panseq            Optionally, specify a panseq results output directory. If not provided, script will download genomes from DB.
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
use Sequences::ExperimentalFeatures;
use Config::Simple;
use Carp qw/croak carp/;
use File::Path qw/remove_tree/;
use Phylogeny::TreeBuilder;
use Phylogeny::Tree;
use IO::CaptureOutput qw(capture_exec);
use Time::HiRes qw( time );

# Globals (set these to match local values)
my $muscle_exe = '/usr/bin/muscle';
my $mummer_dir = '/home/matt/MUMmer3.23/';
my $blast_dir = '/home/matt/blast/bin/';
my $parallel_exe = '/usr/bin/parallel';
my $nr_location = '/home/matt/blast_databases/nr_gammaproteobacteria';
my $panseq_exe = '/home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl';
my $align_script = "$FindBin::Bin/parallel_tree_builder.pl";

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
$argv{feature_type}   = 'pangenome';

my $chado = Sequences::ExperimentalFeatures->new(%argv);

# Intialize the Tree building module
my $tree_builder = Phylogeny::TreeBuilder->new();
my $tree_io = Phylogeny::Tree->new(dbix_schema => $schema);

# BEGIN
my $now = my $start = time();

# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;

# Prepare tmp files for storing upload data
$chado->file_handles();
elapsed_time("Initialization");

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
	
	my $cmd = "perl $FindBin::Bin/../Database/contig_fasta.pl --config $config_file --output $fasta_file";
	system($cmd) == 0 or croak "[Error] download of contig sequences failed (syscmd: $cmd).\n";
	print "\tcomplete\n";
	
	# Run panseq
	print "\tpreparing panseq input...\n";
	$panseq_dir = $root_dir . 'panseq/';
	if(-e $panseq_dir) {
		remove_tree $panseq_dir or croak "[Error] unable to delete directory $panseq_dir ($!).\n";
	}
	
	my $pan_cfg_file = $root_dir . 'pg.conf';
	my $core_threshold = 1633;
	
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
nameOrId	name
storeAlleles	1
allelesToKeep	1
maxNumberResultsInMemory	500
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
my $anno_file = $panseq_dir . 'anno.txt';
open IN, "<", $anno_file or croak "[Error] unable to read file $anno_file ($!).\n";

while(<IN>) {
	chomp;
	my ($q, $qlen, $s, $slen, $t) = split(/\t/, $_);
	# my ($panseq_name, $locus_id, $desc) = split(/\t/, $_);
	# $anno_functions{$locus_id} = [undef,$desc];
	$anno_functions{$q} = [$s,$t];
}
close IN;
elapsed_time('Annotations');

# Load pangenome
my $core_fasta_file = $panseq_dir . 'coreGenomeFragments.fasta';
my $acc_fasta_file = $panseq_dir . 'accessoryGenomeFragments.fasta';
my @core_status = (1,0);
my $num_pg = 0;

foreach my $pan_file ($core_fasta_file, $acc_fasta_file) {
	my $in_core = shift @core_status;
	
	next unless -e $pan_file;
	
	my $fasta = Bio::SeqIO->new(-file   => $pan_file,
							    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $pan_file ($!).";
    
	while (my $entry = $fasta->next_seq) {
		my $id = $entry->display_id;
		my $func = undef;
		my $func_id = undef;
		
		my ($locus_id, $uniquename) = ($id =~ m/^lcl\|(\d+)\|(lcl\|.+)$/);
		croak "Error: unable to parse header $id in pangenome fasta file $pan_file.\n" unless $uniquename && $locus_id;
		
		if($anno_functions{$id}) {
			($func_id, $func) = @{$anno_functions{$id}};
		}
		
		my $seq = $entry->seq;
		$seq =~ tr/-//; # Remove gaps, store only raw sequence
		
		my $pg_feature_id = $chado->handle_pangenome_segment($in_core, $func, $func_id, $seq);
		
		# Cache feature id another info for reference pangenome fragment
		print "$uniquename\n";
		$chado->cache('feature',$uniquename,$pg_feature_id);
	
		$chado->cache('core',$pg_feature_id,$in_core);
		if($in_core) {
			$chado->cache('sequence',$pg_feature_id,$seq);
		}
		$num_pg++;
	}
	
	my $data_type = ($in_core) ? 'Core':'Accessory';
	elapsed_time("$data_type pangenome fragments");
}

# Build alignments and trees in parallel

# Output to file
my $alndir = File::Temp::tempdir(
	"chado-alignments-XXXX",
	CLEANUP  => $SAVE_TMPFILES ? 0 : 1, 
	DIR      => $tmp_dir,
);
chmod 0755, $alndir;

# Make subdirectories for each file type (do #files never grows too large)
my $fastadir = $alndir . '/fasta';
my $treedir = $alndir . '/tree';
my $perldir = $alndir . '/perl_tree';
my $refdir = $alndir . '/refseq';
my $snpdir = $alndir . '/snp_alignments';
my $posdir = $alndir . '/snp_positions';
foreach my $d ($fastadir, $treedir, $perldir, $snpdir, $posdir, $refdir) {
	mkdir $d or croak "[Error] unable to create directory $d ($!).\n";
}
	

# Chop up giant fasta file into parts
my @tasks;
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
		#my ($locus_id, $uniquename) = ($locus =~ m/^lcl\|(\w+)\|(lcl\|.+)$/);
		my ($uniquename) = ($locus =~ m/^(lcl\|.+)$/);
		croak "Error: unable to parse header $locus in the locus alleles fasta file.\n" unless $uniquename;
		
		# pangenome reference region feature ID
		my $query_id = $chado->cache('feature', $uniquename);
		croak "Pangenome reference segment $locus has no assigned feature ID ($uniquename)\n" unless $query_id;
		
		my $num_seqs = ($locus_block =~ tr/>/>/);
		my $do_tree = 0;
		my $do_snps = 0;
	
		$do_tree = 1 if $num_seqs > 2; # only build trees for groups of 3 or more
		$do_snps = 1 if $chado->cache('core',$query_id) && $num_seqs > 1; # need 2 or more sequences for snps
		
		push @tasks, [$query_id, $uniquename, $do_tree, $do_snps, 0];
		
		open my $out1, '>', $fastadir . "/$query_id.ffn" or croak "Error: unable to open file $fastadir/$query_id.ffn ($!).";
	
		while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
			my $header = $1;
			my $seq = $2;
			$seq =~ tr/-//; # Remove gaps
			print $out1 ">$header\n$seq\n";
		}
		close $out1;
		
		if($do_snps) {
			my $refseq = $chado->cache('sequence',$query_id);
			croak "No sequence found for reference pangenome segment $query_id." unless $refseq;
			
			open my $out2, '>', $refdir . "/$query_id\_ref.ffn" or croak "Error: unable to open file $refdir/$query_id\_snps.ffn ($!).";
			my $refheader = "refseq_$query_id";
			print $out2 ">$refheader\n$refseq\n";
			close $out2;
		}
	}
	close $in;
}

# Print tasks to file
my $jobfile = $alndir . "/jobs.txt";
open my $out, '>', $jobfile or croak "Error: unable to open file $jobfile ($!).";
foreach my $t (@tasks) {
	# Only need alignment or tree if do_snps or do_tree is true
	if($t->[2] || $t->[3]) {
		print $out join("\t",$t->[0],$t->[2],$t->[3]),"\n";
	}
}
close $out;
elapsed_time('Fasta file printing');

# Run alignment script
my @loading_args = ('perl', $align_script, "--dir $alndir");
my $cmd = join(' ',@loading_args);
my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
unless($success) {
	croak "Alignment script $cmd failed ($stderr).";
}
elapsed_time('Parallel alignment');


# Load loci positions
my %loci;
my $positions_file = $panseq_dir . 'pan_genome.txt';
open(my $in, "<", $positions_file) or croak "Error: unable to read file $positions_file ($!).\n";
<$in>; # header line
while (my $line = <$in>) {
	chomp $line;
	
	my ($id, $uniquename, $genome, $allele, $start, $end, $header) = split(/\t/,$line);
	
	if($allele > 0) {
		# Hit
		
		# pangenome reference region feature ID
		my $query_id = $chado->cache('feature', $uniquename);
		next unless $query_id;
		#croak "Pangenome reference segement $id has no assigned feature ID\n" unless $query_id;
	
		my ($contig) = $header =~ m/lcl\|\w+\|(\w+)/;
		$loci{$query_id}->{$header}->{$allele} = {
			start => $start,
			end => $end,
			contig => $contig
		};		
	}
}
elapsed_time("Loci locations");


# Iterate through each pangenome segment and load it
foreach my $tarray (@tasks) {
	my ($pg_id, $locus_id, $do_tree, $do_snps) = @$tarray;
	
	# Load sequences from file
	my $num_ok = 0;  # Some locus sequences fail checks, so the overall number of sequences can drop making trees/snps irrelevant
	my @sequence_group;
	my $fasta_file = $fastadir . "/$pg_id.ffn";
	my $fasta = Bio::SeqIO->new(-file   => $fasta_file,
								-format => 'fasta') or die "Unable to open Bio::SeqIO stream to $fasta_file ($!).";
	while(my $entry = $fasta->next_seq()) {
		my $header = $entry->display_id;
		my $seq = $entry->seq;
		$num_ok++ if pangenome_locus($pg_id,$locus_id,$header,$seq,\@sequence_group);
	}
	
	if($do_tree && $num_ok > 2) {
		my $tree_file = $perldir . "/$pg_id\_tree.perl";
		open my $in, '<', $tree_file or croak "Error: tree file not found $tree_file ($!).\n";
		my $tree = <$in>;
		chomp $tree;
		close $in;
		
		# Swap the headers in the tree with consistent tree names
		# Assumes headers are unique
		my %conversions;
		foreach my $allele_hash (@sequence_group) {
			
			my $header = $allele_hash->{header};
			my $displayId = $allele_hash->{public} ? 'public_':'private_';
			$displayId .= $allele_hash->{genome} . '|' . $allele_hash->{allele};
			
			# Many updated sequences will have the correct headers,
			# but just in case, update the tree if they do not match
			next if $header eq $displayId; 
			
			if($conversions{$header}) {
				warn "Duplicate headers $header. Headers must be unique in locus_alleles.fasta.";  # Already looked up new Id
				next;
			}
		
			$conversions{$header} = $displayId;
		}
		
		foreach my $old (keys %conversions) {
			my $new = $conversions{$old};
			my $num_repl = $tree =~ s/$old/$new/g;
			warn "No replacements made in phylogenetic tree. $old not found." unless $num_repl;
			warn "Multiple replacements made in phylogenetic tree. $old is not unique." unless $num_repl;
		}
		
		$chado->handle_phylogeny($tree, $pg_id, \@sequence_group);
	}
	
	if($do_snps && $num_ok > 1) {		
		# Compute snps relative to the reference alignment for all new loci
		# Performed by parallel script, load data for each genome
		foreach my $ghash (@sequence_group) {
			if($ghash->{is_new}) {
				find_snps($posdir, $pg_id, $ghash);
			}
		}
		
		# Load snp positions in each sequence
		# Must be run after all snps loaded into memory
		foreach my $ghash (@sequence_group) {
			if($ghash->{is_new}) {
				locate_snps($posdir, $pg_id, $ghash);
			}
		}
	}
	
}
elapsed_time("Data parsed");

unless ($NOLOAD) {
	$chado->load_data();
	build_genome_tree();
}

$chado->remove_lock();
elapsed_time("Data loaded");

my $rt = time() - $start;
printf("Full runtime: %.2f\n", $rt);

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
        
        if ($lock) {
            warn "Trying to remove the run lock (so that --remove_lock won't be needed)...\n";
            $chado->remove_lock; #remove the lock only if we've set it
        }
        
        print STDERR "Exiting...\n";
    }
    exit(1);
}

=head2 pangenome_locus


=cut

sub pangenome_locus {
	my ($query_id, $locus_id, $header, $seq, $seq_group) = @_;
	
	# Parse input
	my $genome_ids = parse_loci_header($header);
	
	# privacy setting
	my $is_public = $genome_ids->{access} eq 'public' ? 1 : 0;
	my $pub_value = $is_public ? 'TRUE' : 'FALSE';
	
	# location hash
	my $loc_hash = $loci{$query_id}->{$genome_ids->{position_file_header}}->{$genome_ids->{allele}};
	unless(defined $loc_hash) {
		warn "Missing location information for locus allele $locus_id ($query_id) in contig $header (lookup details: ".
			$genome_ids->{position_file_header}.",".
			$genome_ids->{allele}.").\n" unless defined $loc_hash;
		return;
	}
	
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
	my ($result, $allele_id) = $chado->validate_feature($query_id,$genome_ids->{genome},$uniquename,$pub_value);
	
	if($result eq 'new_conflict') {
		warn "Attempt to add new region multiple times. Dropping duplicate of pangenome region $uniquename.";
		return 0;
	}
	if($result eq 'db_conflict') {
		warn "Attempt to update existing region multiple times. Skipping duplicate pangenome region $uniquename.";
		return 0;
	}
	
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
	
		# retrieve genome data - most importantedly upload_id
		my $collection_info = $chado->collection($genome_ids->{genome}, $is_public) unless $is_public;
		
		#my $contig_info = $chado->contig($contig_id, $is_public);
		
		# organism - assume ecoli
		my $organism = $chado->organism_id();
		
		# external accessions
		my $dbxref = '\N';
		
		#  name
		my $name = $locus_id;
		
		# Add entry in core pangenome alignment table for genome, if it doesn't exist
		$chado->add_core_row($genome_ids->{genome}, $is_public);
		
		# Feature relationships
		$chado->handle_parent($curr_feature_id, $genome_ids->{genome}, $contig_id, $is_public);
		$chado->handle_pangenome_loci($curr_feature_id, $query_id, $is_public, $genome_ids->{genome});
		
		# Additional Feature Types
		$chado->add_types($curr_feature_id, $is_public);
		
		# Sequence location
		$chado->handle_location($curr_feature_id, $contig_id, $min, $max, $strand, $is_public);
		
		# Print feature
		my $upload_id = $is_public ? undef : $collection_info->{upload};
		$chado->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues, $is_public, $upload_id);  
		$chado->nextfeature($is_public, '++');
			
		$allele_id = $curr_feature_id;
	}
	
	# Record event in cache
	my $event = $is_new ? 'insert' : 'update';
	$chado->loci_cache($event => 1, feature_id => $allele_id, uniquename => $uniquename, genome_id => $genome_ids->{genome},
		query_id => $query_id, is_public => $pub_value);
	
	push @$seq_group, {
		genome => $genome_ids->{genome},
		header => $header,
		allele => $allele_id,
		#copy => $allele_num,
		contig => $contig_id,
		public => $is_public,
		is_new => $is_new,
	};
	
	return 1;
}

sub find_snps {
	my $data_dir = shift;
	my $ref_id = shift;
	my $genome_info = shift;
	
	my $genome = $genome_info->{header};
	my $contig_collection = $genome_info->{genome};
	my $contig = $genome_info->{contig};
	my $locus = $genome_info->{allele};
	my $is_public = $genome_info->{public};
	
	# Add row in SNP alignment table for genome, if it doesn't exist
	$chado->add_snp_row($contig_collection,$is_public);
	
	# Load snp variations from file
	my $var_file = $data_dir . "/$ref_id\__$genome\__snp_variations.txt";
	open(my $in, "<", $var_file) or croak "Error: unable to read file $var_file ($!).\n";
	
	while(my $snp_line = <$in>) {
		chomp $snp_line;
		my ($pos, $gap, $refc, $seqc) = split(/\t/, $snp_line);
		croak "Error: invalid snp variation format on line $snp_line." unless $seqc;
		
		$chado->handle_snp($ref_id, $refc, $pos, $gap, $contig_collection, $contig, $locus, $seqc, $is_public);
	}
	
	close $in;
}

sub locate_snps {
	my $data_dir = shift;
	my $ref_id = shift;
	my $genome_info = shift;
	
	my $genome = $genome_info->{header};
	my $contig_collection = $genome_info->{genome};
	my $contig = $genome_info->{contig};
	my $locus = $genome_info->{allele};
	my $is_public = $genome_info->{public};
	
	# Load snp alignment positions from file
	my $pos_file = $data_dir . "/$ref_id\__$genome\__snp_positions.txt";
	open($in, "<", $pos_file) or croak "Error: unable to read file $pos_file ($!).\n";
	
	while(my $snp_line = <$in>) {
		chomp $snp_line;
		my ($start1, $start2, $end1, $end2, $gap1, $gap2) = split(/\t/, $snp_line);

		croak "Error: invalid snp position format on line $snp_line." unless defined $gap2;
		$chado->handle_snp_alignment_block($contig_collection, $contig, $ref_id, $locus, $start1, $start2, $end1, $end2, $gap1, $gap2, $is_public);
	}
	
	close $in;
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

sub elapsed_time {
	my ($mes) = @_;
	
	my $time = $now;
	$now = time();
	printf("$mes: %.2f\n", $now - $time);
	
}

sub parse_loci_header {
	my $header = shift;
	
	my ($access, $contig_collection_id, $access2, $contig_id, $allele_num) = ($header =~ m/^lcl\|(public|private)_(\d+)\|(public|private)_(\d+)_\-a(\d+)$/);
	croak "Invalid contig_collection ID format: $header\n" unless $access;
	croak "Invalid contig ID format: $header\n" unless $access2;
	croak "Invalid allele number format: $header\n" unless $allele_num;
	croak "Invalid header: $header" unless $access eq $access2;
	
	$header =~ s/_\-a\d+$//;
	
	return {
		access => $access,
		genome => $contig_collection_id,
		contig => $contig_id,
		allele => $allele_num,
		position_file_header => $header
	};
}


