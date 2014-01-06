#!/usr/bin/env perl

=pod

=head1 NAME

  Phylogeny::TreeBuilder

=head1 DESCRIPTION

  This class is a wrapper around FastTree. Given a 
  multiple sequence alignment, it produces a newick format tree.

=head1 AUTHOR

  Matt Whiteside (mawhites@phac-aspc.gov.ca)

=cut

package Phylogeny::TreeBuilder;
use base qw(Class::Accessor);

use strict;
use warnings;
use Carp qw/croak carp/;

# Get/set methods
Phylogeny::TreeBuilder->mk_accessors(qw/ft_exe ft_opt/);


=head2 new

Constructor

=cut

sub new {
	my ($class) = shift;
	my %args = @_;
	
	my $self = {};
	bless( $self, $class );
	
	# Fast tree executable
	my $ftexe = $args{fasttree_exe} // 'FastTree';
	$self->ft_exe($ftexe);
	
	# Fast tree command
	my $ftopt = $args{fasttree_opt} // '-gtr -nt -quiet -nopr';
	$self->ft_opt($ftopt);
	
	return $self;
}


=head2 build_tree

Args:
1. file name containg nt MSA in FASTA format
2. file name for newick tree output

=cut

sub build_tree {
	my ($self, $msa_file, $tree_file) = @_;
	
	my $cmd = join(' ', $self->ft_exe, $self->ft_opt, $msa_file, '>', $tree_file);
	
	unless(system($cmd) == 0) {
		die "FastTree error ($!).\n";
		return 0;
	}
	
	return(1);
}

1;
