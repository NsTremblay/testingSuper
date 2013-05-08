use utf8;
package Database::Chado::Schema::Result::PhylonodeDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PhylonodeDbxref

=head1 DESCRIPTION

For example, for orthology, paralogy group identifiers; could also be used for NCBI taxonomy; for sequences, refer to phylonode_feature, feature associated dbxrefs.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phylonode_dbxref>

=cut

__PACKAGE__->table("phylonode_dbxref");

=head1 ACCESSORS

=head2 phylonode_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylonode_dbxref_phylonode_dbxref_id_seq'

=head2 phylonode_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phylonode_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylonode_dbxref_phylonode_dbxref_id_seq",
  },
  "phylonode_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phylonode_dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("phylonode_dbxref_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<phylonode_dbxref_phylonode_id_dbxref_id_key>

=over 4

=item * L</phylonode_id>

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phylonode_dbxref_phylonode_id_dbxref_id_key",
  ["phylonode_id", "dbxref_id"],
);

=head1 RELATIONS

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 phylonode

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phylonode>

=cut

__PACKAGE__->belongs_to(
  "phylonode",
  "Database::Chado::Schema::Result::Phylonode",
  { phylonode_id => "phylonode_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QIH6qHZsusMox23uoErvTg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
