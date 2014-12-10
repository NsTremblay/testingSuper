#!/usr/bin/env perl

# Quick script to update the VF csv with new genes to be annotated (based on a fasta file input).
# The script looks for genes already annotated in the csv and adds any new ones while skipping those already present.
# The script also converts the first letter of every gene to a lowercase for consistency in naming.


use strict;
use warnings;

use Bio::SeqIO;
use IO::File;
use POSIX qw(strftime);

# Global Variables
my $timestamp = strftime "%d:%m:%Y %H:%M", localtime;
my $filetimestamp = strftime "%d_%m_%Y", localtime;

my $path_to_vf_fasta = $ARGV[0];
my $path_to_csv = $ARGV[1];
my ($csv_header, $max_tabs, @annotations, %annotated_ids, %unannotated_ids);

my (%ontology_categories, %ontology_genes, %ontology_unclassified);

my $ontology_category_count = 1000000;
my $ontology_subcategory_count = 2000000;
my $ontology_gene_count = 3000000;
my $unclassified_id = 9000000;

$ontology_categories{'unclassified'}{id} = $unclassified_id;

########################
#Call script subroutines
########################

read_in_csv_fasta();
write_to_files();

####################
# Helper Subroutines
####################

# CSV Headers in order:

#Reads in csv and fasta files
sub read_in_csv_fasta {

	open (my $fh, "<", $path_to_csv) or die "Could no open file:$1\n";

	my $fasta_in = Bio::SeqIO->new(
		-file => $path_to_vf_fasta, 
		-format => 'fasta'
		);

	$csv_header = <$fh>;
	$max_tabs = 0;

	while (<$fh>) {
		my @line = split('\t', $_);
		$max_tabs = scalar(@line) if scalar(@line) >= $max_tabs;
		$annotated_ids{lc($line[0])} = 1;
 		# Need to convert the first letter of the gene name to lowercase
 		$line[0] =~ s/^([A-Z])/\l$1/;
 		push(@annotations, \@line);
 	}

 	while (my $seq = $fasta_in->next_seq()) {
 		unless ($annotated_ids{lc($seq->id)}) {
 			$unannotated_ids{$seq->id} = undef;
 		}
 	}

 	close $fh;

 	print "Number of annotated genes: " . scalar @annotations . "\n";
 	print "Number of genes to add: " . scalar (keys %unannotated_ids) . "\n";

 }
 
# Writes all genes out to CSV 
sub write_to_files {

	open (my $write_fh, ">", $path_to_csv);
	open (my $ontology_fh, ">", "./e_coli_VFO_$filetimestamp.obo") or die "Could not open ontology file handle: $!\n";

	



	print $ontology_fh (
		"format-version: 1.2\n". 
		"date: $timestamp\n".
		"saved-by: Akiff Manji\n".
		"auto-generated-by: update_vf_csv_ontology\n".
		"default-namespace: e_coli_virulence\n".
		"ontology: e_coli_virulence\n\n"
		);

	print $ontology_fh (
		"[Term]\n".
		"id: VFO:0000000\n".
		"name: Pathogenesis\n".
		"namespace: e_coli_virulence\n".
		"xref: VFO:www.mgc.ac.cn/VFs/\n".
		"created_by: amanji\n".
		"creation_date: $timestamp\n\n"
		);



	print $write_fh $csv_header;
	
	# Write out existing annotations
	foreach (@annotations) {
		write_to_ontology($_, $ontology_fh);
		print $write_fh join("\t", @{$_});
	}
	
	# Write out new gene additions
	# TODO: This feature is not implemented. DO NOT UNCOMMENT
	#foreach (keys %unannotated_ids) {
		#my $updated_line = write_to_ontology($_);
		#print $write_fh join("\t", @{$updated_line});
		#print $write_fh "$_" . "\t"x($max_tabs-1) . "\n";
	#}
	
	close $write_fh;


	

	my $unclassified_term = "[Term]\n".
	"id: VFO:" . $unclassified_id . "\n".
	"name: unclassified\n".
	"namespace: e_coli_virulence\n".
	"xref: VFO:www.mgc.ac.cn/VFs/\n".
	"is_a: unclassified\n";

	foreach (keys %ontology_unclassified) {
		$unclassified_term .= "is_a: " . $_ . "\n";
	}

	$unclassified_term .= "created_by: amanji\n".
	"creation_date: $timestamp\n\n";

	print $ontology_fh $unclassified_term;	
	
	# Write out ontology Categories and Subcategories
	foreach (keys %ontology_categories) {
		print $ontology_fh (
			"[Term]\n".
			"id: VFO: " . $ontology_categories{$_}{id} ."\n".
			"name: " . $_ . "\n".
			"namespace: e_coli_virulence\n".
			"xref: VFO:www.mgc.ac.cn/VFs/\n".
			"is_a: VFO:0000000 ! Pathogenesis\n".
			"created_by: amanji\n".
			"creation_date: $timestamp\n\n"
			) unless $_ eq 'unclassified';

		my @subcategories = keys %{$ontology_categories{$_}{subcategories}};

		foreach my $subcat (@subcategories) {
			print $ontology_fh (
				"[Term]\n".
				"id: VFO:" . $ontology_categories{$_}{subcategories}{$subcat} . "\n".
				"name: " . $subcat . "\n".
				"namespace: e_coli_virulence\n".
				"xref: VFO:www.mgc.ac.cn/VFs/\n".
				"is_a: VFO:". $ontology_categories{$_}{id} . " ! " . $_ . "\n".
				"created_by: amanji\n".
				"creation_date: $timestamp\n\n"
				);
		}
	}

	close $ontology_fh;

	# my $fasta_out = Bio::SeqIO->new(
	# 	-file => $path_to_vf_fasta, 
	# 	-format => 'fasta'
	# 	);

	#open (my $seq_fh, ">", "./e_coli_VF_$filetimestamp.fasta") or die "Could not open sequence file handle: $!\n";

	#Write out new fasta_file
	# while (my $seq = $fasta_out->next_seq()) {
	# 	my $new_id = $seq->id . "|VFO:" .$ontology_genes{$seq->id}{id} . "|";
	# 	print $seq_fh ">" . $new_id . " - " . $seq->desc . "\n";
	# 	print $seq_fh $seq->seq . "\n\n"
	# }

	#close $seq_fh;
}

#####################
# Ontology Structure:
#####################

# Parent VFO: 0000000
# Category IDs start with: 1000000
# Sub Category IDs start with: 2000000
# Gene IDs start with: 3000000

# Category Example
# [Term]
# id: VFO:0000001
# name: Adherence
# xref: VFO:www.mgc.ac.cn/VFs/
# is_a: VFO:0000000 ! Pathogenesis
# created_by: amanji
# creation_date: $timestamp

# Sub Cateegory Example:
# [Term]
# id: VFO:0000003
# name: Type II Secretion System
# xref: VFO:www.mgc.ac.cn/VFs/
# is_a: VFO:0000001 ! Adherence
# created_by: amanji
# creation_date: $timestamp

# VF gene Example:
# [Term]
# id: VFO:0000006
# name: gspC
# xref: VFO:www.mgc.ac.cn/VFs/
# def: "Inner membrane protein; secretin interaction" []
# is_a: VFO:0000002 ! Autotrasnporter
# is_a: VFO:0000003 ! Type II Secretion System
# created_by: amanji
# creation_date: $timestamp

sub write_to_ontology {

	# CSV Headers:
	# [0] VF gene
	# [1] VFO ID
	# [2] Function
	# [3] Uniprot
	# [4] Categor(y/ies)
	# [5] Sub Categor(y/ies)
	# [6] Reference(s)
	# [7] Ref Genome
	# [8] Sequence

	# Need to check if a reference to array or scalar
	my ($obj_to_write, $_ontology_fh) = @_;
	
	$ontology_gene_count++;
	
	if (ref($obj_to_write) eq 'ARRAY') {
		#Gene Ontology ID
		#$obj_to_write->[1] = $ontology_gene_count;
		# Categories and Sub Categories
		
		foreach (split(',', @$obj_to_write[4])) {
			
			unless (exists $ontology_categories{$_}) {
				
				# Add by default to unclassified
				$ontology_unclassified{$_} = 1;
				
				$ontology_categories{$_} = {};
				$ontology_categories{$_}{id} = $ontology_category_count++;
			}

			$ontology_genes{$obj_to_write->[0]}{belongs_to} = [] unless exists $ontology_genes{$obj_to_write->[0]}{belongs_to};
			#$ontology_genes{$obj_to_write->[0]}{id} = $ontology_gene_count;
			$ontology_genes{$obj_to_write->[0]}{id} = $obj_to_write->[1];

			if ($obj_to_write->[5] eq 'unclassified') {
				push(@{$ontology_genes{$obj_to_write->[0]}}{belongs_to}, $unclassified_id);
			}
			else {
				$ontology_subcategory_count++;
				$ontology_categories{$_}{subcategories}{$obj_to_write->[5]} = $ontology_subcategory_count unless exists $ontology_categories{$_}{subcategories}{$obj_to_write->[5]};
				push(@{$ontology_genes{$obj_to_write->[0]}}{belongs_to}, $ontology_subcategory_count);
			}

		}
	}

	# elsif (ref($obj_to_write) eq 'SCALAR') {
	# 	# TODO: Not implemented. DO NOT UNCOMMENT
	# }

	# Update VFO ID in CSV
	#$obj_to_write->[1] = $ontology_gene_count;

	#Write gene out to ontology
	my $ontology_term = "[Term]\n".
	#"id: VFO: $ontology_gene_count\n".
	"id: VFO: " . $obj_to_write->[1] . "\n".
	"name: " . $obj_to_write->[0] . "\n".
	"namespace: e_coli_virulence\n".
	"xref: VFO:www.mgc.ac.cn/VFs/\n".
	"def: \"\" []\n";
	foreach (@{$ontology_genes{$obj_to_write->[0]}{belongs_to}}) {
		$ontology_term .= "is_a: VFO:$_ ! \n";
	}
	$ontology_term .= "created_by: amanji\n".
	"creation_date: $timestamp\n\n";

	print $_ontology_fh $ontology_term;

	#return $obj_to_write;
	return;
}
