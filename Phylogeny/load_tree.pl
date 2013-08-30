use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/";
use Tree;
use Carp;
use Getopt::Long;

=head1 NAME

$0 - Loads pre-computed phylogenetic tree data into tree table

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --tree      Newick-format tree file

=head1 DESCRIPTION

To improve the speed of page loading, tree data
is computed once and then saved in a table called tree. Tree data
needs to be updated anytime data changes (relatively infrequent).

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($tree_file);

GetOptions(
    'tree=s' => \$tree_file,
);

# Connect to DB
croak "Missing argument. You must supply the filename containing the newick tree data.\n" unless $tree_file;

my $t = Phylogeny::Tree->new;


$t->loadTree($tree_file);



