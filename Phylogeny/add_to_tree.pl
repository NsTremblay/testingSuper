#!/usr/bin/env perl

=head1 NAME

$0 - Inserts new genomes into existing genome tree

=head1 SYNOPSIS

  % $0 --config file [options]

=head1 OPTIONS

 --config      Config file with tmp directory and db connection parameters

=head1 DESCRIPTION

TODO

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2014

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Phylogeny::Tree;
use Phylogeny::TreeBuilder;
use Data::Dumper;
use Carp;
use Getopt::Long;

## Arguments
my ($config);
GetOptions(
    'config=s' => \$config,
);

croak "Missing argument. You must supply the config filename.\n" unless $config;
my $tmp_dir;
my $v = 1;
if(my $conf = new Config::Simple($config)) {
	$tmp_dir    = $conf->param('tmp.dir');
} else {
	die Config::Simple->error();
}
croak "Invalid configuration file." unless $tmp_dir;

my $t = Phylogeny::Tree->new(config => $config);
my $tree_builder = Phylogeny::TreeBuilder->new();

###
# TESTING SET
###
my @test_set = qw/public_100756 public_100112 public_100930 public_100619 public_100802 public_172974/;
my @target_set = qw/public_100756/;

# Obtain working tree
my $root = $t->globalTree;
my $num_orig_leaves = scalar($t->find_leaves($root));

# Build fast approx tree
my ($nj_root, $nj_leaves) = buildNJtree();

printTree($nj_root, 0);
print "LEAVES\n".join(',',map {$_->{name}} @$nj_leaves)."\n";

# Sometimes a supertree approach is not possible
# In which case, the entire ML genome tree needs to 
# be built.
my $short_circuit = 0;

# Keep track of which new genomes are inserted into main tree
my %waiting_targets;
map { $waiting_targets{$_} = 1 } @target_set;

# Use supertree approach to add new genomes to existing ML tree
foreach my $targetG (@target_set) {

	# Find corresponding leaf node
	my $leaf;
	foreach my $l (@$nj_leaves) {
		if($l->{name} eq $targetG) {
			$leaf = $l;
			last;
		}
	}
	croak "Error: new genome $targetG not found in core_alignment table.\n" unless $leaf;


	my $terminate = 0;
	my $level = 2;
	do {

		# Get candidate subtree set
		print "LEAF\n$leaf->{name}\n";
		my ($rs, $genome_set) = find_umbrella($leaf, $level);

		print "UMBRELLA: $rs / [",join(',',@$genome_set),"]\n";
		exit(0);

		if($rs) {
			# Target genome not embedded in suitable subtree,
			# need to rebuild entire ML genome tree
			$short_circuit = 1;
			$terminate = 1;

		} else {
			# Attempt build of subtree using ML approach
			my ($new_subtree_root, $old_subtree_root) = buildSubtree($genome_set);

			# Check if target is outgroup
			my @subtree_leaves = $t->find_leaves($new_subtree_root);

			if(_isOutgroup($targetG, \@subtree_leaves)) {
				# Target is outgroup in subtree,
				# move to larger subtree
				$level++;
				$terminate = 0;

			} else {
				# Build successful
				# Reattach subtree to main tree
				foreach my $k (keys %{$old_subtree_root}) {
					$new_subtree_root->{$k} = $old_subtree_root->{$k};
				}

				# $root now contains $targetG, move on to next genome
				$terminate = 1;
			}

		}

	} while(!$terminate);
	
	last if $short_circuit;

	# Genome inserted into ML tree using supertree approach
	$waiting_targets{$targetG} = 0;

} # End of iteration of target_genomes


if($short_circuit) {
	# The supertree approach failed for one or more new genomes
	# Rebuild entire ML tree
	$root = buildMLtree();
}

# Verify correct number of leaves
my @final_leaves = $t->find_leaves($root);
croak "Error: Final number of genomes in phylogenetic tree does not match input genomes.\n" unless scalar(@final_leaves) == ($num_orig_leaves + @target_set);

# Load into DB
$t->loadPerlTree($root);


## Subs

# Build NJ tree to use to pick candidate subtrees in supertree approach
sub buildNJtree {

	# Build quick NJ tree to identify closely related genomes
	my $pg_file = $tmp_dir . "superphy_core_aligment.txt";

	if(-e $pg_file) {
		 unlink $pg_file or carp "Warning: could not delete temp file $pg_file ($!).\n";
	}

	if(@test_set) {
		$t->pgAlignment(genomes => \@test_set, file => $pg_file)
	} else {
		$t->pgAlignment(file => $pg_file)
	}

	my $nj_file = $tmp_dir . 'superphy_core_tree.txt';
	open(OUT, ">$nj_file") or croak "Error: unable to write to file '$nj_file' ($!).\n";
	close OUT;
		
	$tree_builder->build_njtree($pg_file, $nj_file) or croak "Error: nj genome tree build failed.\n";

	# Load tree
	my $nj_tree = $t->newickToPerl($nj_file);

	# Add parent links, collect leaves
	my @leaves = ();
	_add_parent_links($nj_tree, \@leaves);

	return($nj_tree, \@leaves);
}

sub _add_parent_links {
	my $this_root = shift;
	my $leaves = shift;

	if($this_root->{children}) {
		foreach my $c (@{$this_root->{children}}) {
			$c->{parent} = $this_root;
			_add_parent_links($c, $leaves);
		}
	} else {
		push @$leaves, $this_root;
	}
}

=head2 find_umbrella

Given a single node, find the lowest (or most recent) umbrella ancestor internal node.
Umbrella nodes try to obtain a local subtree that encompasses the node of interest &
captures a reasonable degree of variation around the node of interest.

An umbrella node is defined as:
1. An internal node
2. Not direct parent of node of interest
3. Contains at least one leaf node that is farther than the node of interest
4. Contains at least 5 leaf nodes

Args:
1. A hash reference representing internal node in PERL-based tree
2. Array of strings that match the 'name' value in leaf nodes
3. Number of levels up on path to root from node of interest

Returns:
1. An arrayref of genomes that are leaves in umbrella-node subtree
2. Level of umbrella node

=cut

sub find_umbrella {
	my $leaf = shift;
	my $level = shift;

	my $rs;
	my $min_set_size = 5;

	# Move up $level levels from leaf
	my $node = $leaf;
	my $reached_root = 0;
	for(my $i = 0; $i < $level; $i++) {
		if($node->{parent}) {
			$node = $node->{parent}
		} else {
			# Reached root
			$reached_root = 1;
			last;
		}
	}

	if($reached_root) {
		# Need rebuild entire tree
		$rs = 1;
		return($rs, []);
	}

	print " STARTING UMBRELLA:\n";
	printTree($node, 0);


	# Check for valid umbrella node
	# Move up tree to root until one is found, or root is reached
	my $found = 0;
	my @leaves;

	do {
		@leaves = $t->find_leaves($node);

		# Remove leaves that have not yet been added to ML tree
		# Including the target genome
		my @tmp;
		my $theLeaf; # The target genome leaf node, now with length filled in
		foreach my $l (@leaves) {
			push @tmp, $l unless $waiting_targets{$l->{node}->{name}};
			$theLeaf = $l if $l->{node}->{name} eq $leaf->{name};
		}
		@leaves = @tmp;
		unshift @leaves, $theLeaf; # Stick target genome at front of leaves array

		if(@leaves < $min_set_size) {
			# Only small subtree at this point
			# Move up one level if possible

			if($node->{parent}) {
				$found = 0;
				$node = $node->{parent};
			} else {
				# Reached root
				print "ABORT!! Too few genomes and reached root\n" if $v;
				$rs = 1;
				return($rs, []);
			}

		} else {
			# Found substantial subtree

			if(_isOutgroup($leaf->{name}, \@leaves)) {
				# If target genome is outgroup
				# Move up one level if possible

				if($node->{parent}) {
					$found = 0;
					$node = $node->{parent};
				} else {
					# Reached root
					$rs = 1;
					return($rs, []);
				}

			} else {
				# Found umbrella node
				$found = 1;
			}

		}

		print "TRYING AGAIN"

	} while(!$found);
	
	
	my @genome_set = map { $_->{node}->{name} } @leaves;
	$rs = 0;
	return ($rs, \@genome_set);
}

sub _isOutgroup {
	my $leafName = shift;
	my $leaves = shift;

	# Check outgroup in subtree
	my $outg = { node => undef, len => -1};
	my $target_len;
	foreach my $l (@$leaves) {
		print "CHECKING :".$l->{node}->{name}."\n";
		$outg = $l if $l->{len} > $outg->{len};
		if($l->{node}->{name} eq $leafName) {
			$target_len = $l->{len};
		}
	}

	croak "Error: subtree does not contain target genome $leafName. Cannot run _isOutgroup()." unless defined $target_len;
	return($target_len == $outg->{len});
}


# Build subtree
sub buildSubtree {
	# Target genome is first in set
	my $genome_set = [qw/public_100765 public_100802 public_100112/];
	my $target_genome = pop @$genome_set; 

	# Find LCA of leaf nodes
	my $subtree_root = $t->find_lca($root, $genome_set);


	# Build tree for genomes in LCA subtree
	my @leaves = $t->find_leaves($subtree_root);
	my @subtree_genomes = map { $_->{node}->{name} } @leaves;
	unshift @subtree_genomes, $target_genome;

	my $align_file = $tmp_dir . "superphy_snp_aligment.txt";
	if(-e $align_file) {
		 unlink $align_file or carp "Warning: could not delete temp file $align_file ($!).\n";
	}

	$t->snpAlignment(genomes => \@subtree_genomes, file => $align_file);

	my $tree_file = $tmp_dir . 'superphy_snp_tree.txt';
	open(my $out, ">".$tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
	close $out;
		
	$tree_builder->build_tree($align_file, $tree_file) or croak "Error: genome tree build failed.\n";

	# Load tree
	my $new_subtree = $t->newickToPerl($tree_file);

	return ($new_subtree, $subtree_root);
}

# Build entire ML tree
sub buildMLtree {

	# write alignment file
	my $tmp_file = $tmp_dir . 'genodo_genome_aln.txt';
	$t->snpAlignment(file => $tmp_file);
	
	# clear output file for safety
	my $tree_file = $tmp_dir . 'genodo_genome_tree.txt';
	open(my $out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
	close $out;
	
	# build newick tree
	$tree_builder->build_tree($tmp_file, $tree_file) or croak "Error: genome tree build failed.\n";

	my $new_tree = $t->newickToPerl($tree_file);

	return $new_tree;
}

sub printTree {
	my $node = shift;
	my $level = shift;

	my $n = defined $node->{name} ? $node->{name} : 'undefined';
	my $l = defined $node->{length} ? $node->{length} : 'undefined';

	print join('',("\t") x $level);
	if($node->{children}) {
		print "I-Node: <$n> ($l)\n";
		$level++;
		foreach my $c (@{$node->{children}}) {
			printTree($c, $level);
		}
	} else {
		print "L-Node: <$n ($l)\n";
	}

}

