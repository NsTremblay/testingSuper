#!/usr/bin/env perl

=head1 NAME

$0 - Align sequences and build trees in parallel

=head1 SYNOPSIS
	
	% parallel_tree_builder.pl [options]

=head1 COMMAND-LINE OPTIONS

	--dir				Define directory containing fasta files and job list

=head1 DESCRIPTION



=head1 AUTHOR

Matt Whiteside

=cut

use Inline C;
use strict;
use warnings;

use Getopt::Long;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use Carp qw/croak carp/;
use Phylogeny::TreeBuilder;
use Phylogeny::Tree;
use Parallel::ForkManager;
use IO::CaptureOutput qw(capture_exec);
use File::Copy qw/copy/;
use Time::HiRes qw( time );

########
# INIT
########

my $v = 0;

# Globals (set these to match local values)
my $muscle_exe = 'muscle';

# Intialize the Tree building module
my $tree_builder = Phylogeny::TreeBuilder->new();
my $tree_io = Phylogeny::Tree->new(dbix_schema => 'empty');

# Inialize the parallel manager
# Max processes for parallel run
my $pm = new Parallel::ForkManager(20);

# Get config
my ($alndir, $fast_mode) = (0,0);
GetOptions(
	'dir=s' => \$alndir,
	'fast' => \$fast_mode,
	'v' => \$v
) or ( system( 'pod2text', $0 ), exit -1 );
croak "[Error] missing argument. You must supply a valid data directory\n" . system('pod2text', $0) unless $alndir;

my $fastadir = $alndir . '/fasta';
my $treedir = $alndir . '/tree';
my $perldir = $alndir . '/perl_tree';
my $refdir = $alndir . '/refseq';
my $snpdir = $alndir . '/snp_alignments';
my $posdir = $alndir . '/snp_positions';
my $newdir = $alndir . '/new';

# Load jobs
my $job_file = $alndir . '/jobs.txt';
my @jobs;
open my $in, '<', $job_file or croak "Error: unable to read job file $job_file ($!).\n";
while(my $job = <$in>) {
	chomp $job;
	
	my ($pg_id, $do_tree, $do_snp, $add_seq) = split(/\t/,$job);
	push @jobs, [$pg_id, $do_tree, $do_snp, $add_seq] if($do_tree || $do_snp || $add_seq);
}
close $in;

# Logger
my $log_file = "$alndir/parallel_log.txt";
open my $log, '>', $log_file or croak "Error: unable to create log file $log_file ($!).\n";
my $start = time();
print $log "parallel_tree_builder.pl - ".localtime()."\n";

########
# RUN
########

my $num = 0;
my $tot = scalar(@jobs);

foreach my $jarray (@jobs) {
	$num++;
	$pm->start and next; # do the fork

	my $st = time();
	my ($pg_id,$do_tree,$do_snp,$add_seq) = @$jarray;
	build_tree($pg_id,$do_tree,$do_snp,$add_seq);
	my $en = time();
	my $time = $en - $st;
	print $log "\t$pg_id completed (elapsed time $time)\n";

	$pm->finish; # do the exit in the child process
}

$pm->wait_all_children;
my $time = time() - $start;
print $log "complete (runtime: $time)\n";
close $log;
exit(0);

########
# SUBS
########

sub build_tree {
	my ($pg_id, $do_tree, $do_snp, $add_seqs) = @_;
	
	local *STDOUT = $log;
	local *STDERR = $log;
	my $time = time();
	
	my $fasta_file = "$fastadir/$pg_id.ffn";
	
	if($add_seqs) {
		# Iteratively add new sequences to existing alignment
		
		my $new_file = "$newdir/$pg_id.ffn";
		my $tmp_file = "$newdir/$pg_id\_tmp.ffn";
		
		my $fasta = Bio::SeqIO->new(-file   => $new_file,
									-format => 'fasta') or croak "Unable to open Bio::SeqIO stream to $new_file ($!).";
									
		while (my $entry = $fasta->next_seq) {
			
			open(my $tmpfh, '>', $tmp_file) or croak "Unable to write to tmp file $tmp_file ($!).";
			print $tmpfh '>'.$entry->display_id."\n".$entry->seq."\n";
			close $tmpfh;
			
			my @loading_args = ($muscle_exe, "-profile -in1 $tmp_file -in2 $fasta_file -out $fasta_file");
			my $cmd = join(' ',@loading_args);
			
			my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
		
			unless($success) {
				croak "Muscle profile alignment failed for pangenome $pg_id ($stderr).";
			}
		}
		
	} else {
		# Generate new alignment
		
		my @loading_args = ($muscle_exe, '-diags -maxiters 2', "-in $fasta_file -out $fasta_file");
		my $cmd = join(' ',@loading_args);
		
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
		unless($success) {
			croak "Muscle profile alignment failed for pangenome $pg_id ($stderr).";
		}
		
	}
	$time = elapsed_time("\talignment ", $time);
	
	if($do_tree) {
		my $tree_file = "$treedir/$pg_id\_tree.phy";
		my $perl_file = "$perldir/$pg_id\_tree.perl";
		
		# build newick tree
		$tree_builder->build_tree($fasta_file, $tree_file, $fast_mode) or croak;
		
		# slurp tree and convert to perl format
		my $tree = $tree_io->newickToPerlString($tree_file);
		open my $out, ">", $perl_file or croak "Error: unable to write to file $perl_file ($!).\n";
		print $out $tree;
		close $out;
	}
	$time = elapsed_time("\ttree ", $time);
	
	if($do_snp) {
		
		# Align reference sequence to already aligned alleles
		my $ref_file = "$refdir/$pg_id\_ref.ffn";
		my $aln_file = "$snpdir/$pg_id\_snp.ffn";
		my $ref_aln_file = "$refdir/$pg_id\_aln.ffn";
		my @loading_args = ($muscle_exe, "-profile -in1 $fasta_file -in2 $ref_file -out $aln_file");
		my $cmd = join(' ',@loading_args);
		
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
		unless($success) {
			croak "Muscle profile alignment failed for pangenome $pg_id ($stderr).";
		}
		
		# Find snp positions
		my $pos_fileroot = "$posdir/$pg_id";
		my $refheader = "refseq_$pg_id";
		my $refseq;
		my @comp_seqs;
		my @comp_names;
		my $fasta = Bio::SeqIO->new(-file   => $aln_file,
									-format => 'fasta') or croak "Unable to open Bio::SeqIO stream to $aln_file ($!).";
		while (my $entry = $fasta->next_seq) {
			my $id = $entry->display_id;
			
			if($id eq $refheader) {
				$refseq = $entry->seq;
				open(my $afh, '>', $ref_aln_file) or croak "Error: unable to write to file $ref_aln_file ($!).\n";
				print $afh ">$refheader\n$refseq\n";
				close $afh;
			} else {
				push @comp_seqs, $entry->seq;
				push @comp_names, $id;
			}
		}
		
		croak "Missing reference sequence in SNP alignment for set $pg_id\n" unless $refseq;
		# Create output directory
		croak "Filepath will overflow C char[] buffers. Need to extend buffer length." if length($pos_fileroot) > 150;
		mkdir $pos_fileroot or croak "Error: unable to make directory $pos_fileroot ($!).\n";
		snp_positions(\@comp_seqs, \@comp_names, $refseq, $pos_fileroot);
	}
	elapsed_time("\tsnp ", $time);
	
}

sub elapsed_time {
	my ($mes, $prev) = @_;
	
	my $now = time();
	printf("$mes: %.2f\n", $now - $prev) if $v;
	
	return $now;
}

__END__
__C__

void write_positions(char* refseq, char* seq, char* filename, char* filename2) {
	
	FILE* fh = fopen(filename, "w");
	FILE* fh2 = fopen(filename2, "w");
	int i;
	int g = 0; // gap
	int p = 0; // current position
	int s = 0; // start of alignment block
	int g2 = 0;
	int p2 = 0;
	int s2 = 0;
	
	// Alignment blocks are interupted by gaps
	// Gap columns are ignored
	// Alignment blocks are printed as
	// ref_start, seq_start, ref_end, seq_end, ref_gap_offset, seq_gap_offset
		
	if (fh == NULL) {
		fprintf(stderr, "Can't open output file %s!\n",
			filename);
		exit(1);
	}
	
	if (fh2 == NULL) {
		fprintf(stderr, "Can't open output file %s!\n",
			filename2);
		exit(1);
	}
	                                         
	for(i=0; refseq[i] && seq[i]; ++i) {
		
		if(refseq[i] == '-') {
			// Gap col in ref
			
			if(seq[i] != '-') {
				// Nt position in comp
				// Record block transition
				if(i != 0) {
					fprintf(fh2, "%i\t%i\t%i\t%i\t%i\t%i\n", s, s2, p, p2, g, g2);
				}
				
				// Reset block counters
				s = p;
				s2 = p2;
				
				// Advance counters
				g2 = 0;
				p2++;
				
			} else {
				// Gap column at start of new block
				// Could be continuation of gap
				// Record block transition
				if(s == p && s2 == p) {
					fprintf(fh2, "%i\t%i\t%i\t%i\t%i\t%i\n", s, s2, p, p2, g, g2);
					
					// Reset block counters
					s = p;
					s2 = p2;
				}
				
				// Advance counters
				g2++;
			}
			
			// Advance counters
			g++;
			
		} else {
			// Nt position in ref
			
			if(seq[i] == '-') {
				// Gap position in comp
				// Record block transition
				if(i != 0) {
					fprintf(fh2, "%i\t%i\t%i\t%i\t%i\t%i\n", s, s2, p, p2, g, g2);
				}
				
				
				// Reset block counters
				s = p;
				s2 = p2;
				
				// Advance counters
				g2++;
				
			} else {
				// Nt position in comp
				
				if((g != 0 && g2 == 0) || (g == 0 && g2 != 0) || (g != 0 && g2 != 0 && s == p && s2 == p2)) {
					// Termination of gap in one sequence
					// Or gap column at start of block
					// Ignores embedded gap columns (these can be easily derived)
					// Record block transition
					fprintf(fh2, "%i\t%i\t%i\t%i\t%i\t%i\n", s, s2, p, p2, g, g2);
					
					// Reset block counters
					s = p;
					s2 = p2;
				}
				
				// Advance counters
				p2++;
				g2 = 0;
			}
	
			// Advance counters
			p++;
			g = 0;
		}
		
		
		// Print SNP                                        
		if(refseq[i] != seq[i]) {
			fprintf(fh, "%i\t%i\t%c\t%c\n", p, g, refseq[i], seq[i]);
		}
		                                                                     
	}
	
	// Print last block
	fprintf(fh2, "%i\t%i\t%i\t%i\t%i\t%i\n", s, s2, p, p2, g, g2);
	
	fclose(fh);
	fclose(fh2);                                                                           

}

void snp_positions(SV* seqs_arrayref, SV* names_arrayref, char* refseq, char* fileroot) {
	
	AV* names;
	AV* seqs;
	
	names = (AV*)SvRV(names_arrayref);
	seqs = (AV*)SvRV(seqs_arrayref);
	int n = av_len(seqs);
	int i;
	
	// compare each seq to ref
	// write snps to file for genome
	for(i=0; i <= n; ++i) {
		SV* name = av_shift(names);
		SV* seq = av_shift(seqs);
		char filename[200];
		char filename2[200];
		char* basename;
		basename = SvPV_nolen(name);
		sprintf(filename, "%s/%s__snp_variations.txt", fileroot, basename);
		sprintf(filename2, "%s/%s__snp_positions.txt", fileroot, basename);
		
		write_positions(refseq, (char*)SvPV_nolen(seq), filename, filename2);
		
	}
	
}






