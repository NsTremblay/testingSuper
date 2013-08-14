#!/usr/bin/perl

=pod

=head1 NAME

  Phylogeny::Tree

=head1 DESCRIPTION

  This class provides phylogenetic tree functions for maniputing and displaying
  trees in newick, perl-encoded and json format.

=head1 AUTHOR

  Matt Whiteside (mawhites@phac-aspc.gov.ca)

=cut

package Phylogeny::Tree;

use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__) . "/../";
use FindBin;
use lib "$FindBin::Bin/..";
use Carp qw/croak carp/;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';
use Config::Simple;
use Data::Dumper;
use Log::Log4perl qw(:easy get_logger);
use JSON;
use Modules::FormDataGenerator;

# Globals
my $visable_nodes; # temporary pointer to list of nodes to keep when pruning by recursion

=head2 new

Constructor

Required input parameter: config filename containing DB connection parameters
or pointer to existing DBIX::Class::Schema object.

=cut

sub new {
	my ($class) = shift;
	
	my $self = {};
	bless( $self, $class );
	
	my %params = @_;
	my $config_file = $params{config} //= dirname (__FILE__) . "/../Modules/genodo.cfg";
	my $dbix = $params{dbix_schema};
	
	unless($dbix) {
		# No schema provided, connect to database
		croak "Error: config file not found ($config_file).\n" unless -e $config_file;
		
		#print "$config_file\n";
		
		my $db_conf = new Config::Simple($config_file);
		
		$self->connectDatabase( dbi     => $db_conf->param('db.dbi'),
						        dbName  => $db_conf->param('db.name'),
						        dbHost  => $db_conf->param('db.host'),
						        dbPort  => $db_conf->param('db.port'),
						        dbUser  => $db_conf->param('db.user'),
						        dbPass  => $db_conf->param('db.user')
		);
	} else {
		# Use existing connection
		$self->setDbix($dbix);
	}
	
	return $self;
}


=head2 loadTree

Called after each time a new phylogenetic tree is built. Performs the following
functions:

  1. parses newick string into perl-encoded data structure
  2. saves perl-encoded tree as "global" in DB
  3. prunes tree into only those visable by public, converts to json and saves as "public" in DB

=cut

sub loadTree {
	my ($self, $newick_file) = @_;
	
	# Parse newick tree
	my $ptree = $self->newickToPerl($newick_file);
	
	# Save entire tree in database as Data::Dumper perl structure
	$Data::Dumper::Indent = 0;
	my $ptree_string = Data::Dumper->Dump([$ptree], ['tree']);
	
	$self->dbixSchema->resultset('Tree')->update_or_create(
		{
			name             => 'global',
			format           => 'perl',
			tree_string      => $ptree_string,
			timelastmodified => \'now()'
		},
		{
			key => 'tree_c1'
		}
	);
	
	# Remove any private genomes
	my $public_list = $self->visableGenomes;
	
	# Prune private genomes from tree
	my $public_tree = $self->pruneTree($ptree, $public_list, 1);
	
	# Convert to json
	my $jtree_string = encode_json($public_tree);
	
	# Save in DB
	$self->dbixSchema->resultset('Tree')->update_or_create(
		{
			name             => 'public',
			format           => 'json',
			tree_string      => $jtree_string,
			timelastmodified => \'now()'
		},
		{
			key => 'tree_c1'
		}
	);

}

=head2 pruneTree

 

=cut

sub pruneTree {
	my ($self, $root, $nodes, $restrict_depth) = @_;
	
	# Set global
	$visable_nodes = $nodes;
	
	$root->{'length'} = 0;
	
	my ($updated_tree, $discard) = _pruneNodeRecursive($root, 0, $restrict_depth, 0);
	
	return $updated_tree;
}

sub _pruneNodeRecursive {
	my ($node, $depth, $restrict_depth, $parent_length) = @_;
	
	$depth++;
	$node->{sum_length} = $node->{'length'} + $parent_length;
	
	if($node->{children}) {
		# Internal node
		
		# Find visable descendent nodes
		my @visableNodes;
		my @nodeRecords;
		foreach my $childnode (@{$node->{children}}) {
			my ($visableNode, $nodeRecord) = _pruneNodeRecursive($childnode, $depth, $restrict_depth, $node->{sum_length});
			if($visableNode) {
				push @visableNodes, $visableNode;
				push @nodeRecords, $nodeRecord;
			}
		}
		
		# Finished recursion
		# Transform internal node if needed
		
		if(@visableNodes > 1) {
			# Update children, length unchanged
			
			my $record;
			
			# Make informative label for internal node
			my $num_leaves = 0;
			my $outg_label;
			my $outg_length;
			my $outg_depth;
			foreach my $child (@nodeRecords) {
				$num_leaves += $child->{num_leaves};
				if($outg_label) {
					# Compare to existing outgroup
					if($outg_depth > $child->{depth} || ($outg_depth == $child->{depth} && $outg_length < $child->{'length'})) {
						# new outgroup found
						$outg_label = $child->{outgroup};
						$outg_depth = $child->{depth};
						$outg_length = $child->{'length'};
					}
				} else {
					$outg_label = $child->{outgroup};
					$outg_depth = $child->{depth};
					$outg_length = $child->{'length'};
				}
			}
			
			$node->{label} = "$num_leaves genomes (outgroup: $outg_label)";
			
			$record->{num_leaves} = $num_leaves;
			$record->{depth} = $outg_depth;
			$record->{'length'} = $outg_length;
			$record->{outgroup} = $outg_label;
			
			if($restrict_depth && $depth > 8) {
				# Collapse all nodes above a certain depth
				
				delete $node->{children};
				$node->{_children} = \@visableNodes;
				
			} else {
				$node->{children} = \@visableNodes;
			}
			
	
			return ($node, $record); # record is empty unless $restrict_depth is true
			
		} elsif(@visableNodes == 1) {
			# No internal node needed, replace with singleton child node
			# Sum lengths
			my $replacementNode = shift @visableNodes;
			$replacementNode->{'length'} += $node->{'length'};
			my $newRecord = shift @nodeRecords;
			$newRecord->{depth}--;
			$newRecord->{'length'} = $replacementNode->{'length'};
			return ($replacementNode, $newRecord);
		} else {
			# Empty node, remove
			return;
		}
		
	} else {
		# Leaf node
		croak "Leaf node with no defined name at depth $depth.\n" unless $node->{name};
		if(my $label = $visable_nodes->{$node->{name}}) {
			# Add a label to the leaf node
			$node->{label} = $label;
			$node->{leaf} = 'true';
			my $record;
			$record->{num_leaves} = 1;
			$record->{outgroup} = $label;
			$record->{depth} = $depth;
			$record->{'length'} = $node->{'length'};
			return ($node, $record);
		} else {	
			return;
		}
	}
	
}


=head2 userTree

Return json string of phylogenetic visable to user

=cut

sub userTree {
	my ($self, $visable) = @_;
	
	# Get tree perl hash-ref
	my $ptree = $self->globalTree;
	
	# Remove genomes not visable to user
	my $user_tree = $self->pruneTree($ptree, $visable);
	
	# Convert to json
	my $jtree_string = encode_json($user_tree);
	
	return $jtree_string;
}

=head2 publicTree

Return json string of phylogenetic visable to all users

=cut
sub publicTree {
	my $self = shift;
	
	my $tree_rs = $self->dbixSchema->resultset("Tree")->search(
		{
			name => 'public'	
		},
		{
			columns => ['tree_string']
		}
	);
	
	return $tree_rs->first->tree_string;	
}

=head2 publicTree

Return perl data-structure phylogenetic containing all nodes (INCLUDING PRIVATE!!)

Returns a perl hash-ref and not a string.

=cut
sub globalTree {
	my $self = shift;
	
	my $tree_rs = $self->dbixSchema->resultset("Tree")->search(
		{
			name => 'global'	
		},
		{
			columns => ['tree_string']
		}
	);
	
	# Tree hash is saved as $tree in Data::Dumper string
	my $tree;
	
	eval $tree_rs->first->tree_string;
	
	return $tree;	
}

=cut newick_to_perl

Convert from Newick to Perl structure.

Input: file name containing Newick string
Returns: hash-ref

=cut
sub newickToPerl {
	my $self = shift;
	my $newick_file = shift;
	
	my $newick;
	open(IN, "<$newick_file") or croak "Error: unable to read file $newick_file ($!)\n";
	
	while(my $line = <IN>) {
		chomp $line;
		$newick .= $line;
	}
	
	close IN;
	
	my @tokens = split(/\s*(;|\(|\)|:|,)\s*/, $newick);
	my @ancestors;
	my $tree = {};
	
	for(my $i=0; $i < @tokens; $i++) {
		
		my $tok = $tokens[$i];
		
		if($tok eq '(') {
			my $subtree = {};
			$tree->{children} = [$subtree];
			push @ancestors, $tree;
			$tree = $subtree;
			
		} elsif($tok eq ',') {
			my $subtree = {};
			push @{$ancestors[$#ancestors]->{children}}, $subtree;
			$tree = $subtree;
			
		} elsif($tok eq ')') {
			$tree = pop @ancestors;
			
		} elsif($tok eq ':') {
			# optional length next
			
		} else {
			my $x = $tokens[$i-1];
        	
        	if( $x eq ')' || $x eq '(' || $x eq ',') {
				$tree->{name} = $tok;
          	} elsif ($x eq ':') {
          		$tree->{'length'} = $tok+=0;  # Force number
          	}
		}
	}
	
	return $tree;
}

=cut visableGenomes

	Get all public genomes for any user.  

	This is meant to be called outside of normal website operations, specifically
	when a new phylogenetic tree is being loaded.  Visable genomes for a user will be computed
	using FormDataGenerator during website queries and should be used instead of repeating 
	the same query in this method again.

=cut
sub visableGenomes {
	my ($self) = @_;
	
	# Get public genomes
	my $data = Modules::FormDataGenerator->new;
	$data->dbixSchema($self->dbixSchema);
	
	my $main_genomes = $data->publicGenomes;
	
	my $user_genomes = $data->privateGenomes;
	
	# Convert to tree naming scheme
	my %visable;
	foreach my $nodename (@$main_genomes) {
		$visable{'public_'.$nodename->{feature_id}} = $nodename->{uniquename}; 
	}
	foreach my $nodename (@$user_genomes) {
		$visable{'private_'.$nodename->{feature_id}} = $nodename->{uniquename}; 
	}
	
	return \%visable;
}


1;
