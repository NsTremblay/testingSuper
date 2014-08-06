use utf8;
package Database::Chado::Schema::Result::Phylotree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Phylotree - Global anchor for phylogenetic tree.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phylotree>

=cut

__PACKAGE__->table("phylotree");

=head1 ACCESSORS

=head2 phylotree_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylotree_phylotree_id_seq'

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

Type: protein, nucleotide, taxonomy, for example. The type should be any SO type, or "taxonomy".

=head2 analysis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "phylotree_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylotree_phylotree_id_seq",
  },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "analysis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phylotree_id>

=back

=cut

__PACKAGE__->set_primary_key("phylotree_id");

=head1 RELATIONS

=head2 analysis

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Analysis>

=cut

__PACKAGE__->belongs_to(
  "analysis",
  "Database::Chado::Schema::Result::Analysis",
  { analysis_id => "analysis_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 phylonode_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylonodeRelationship>

=cut

__PACKAGE__->has_many(
  "phylonode_relationships",
  "Database::Chado::Schema::Result::PhylonodeRelationship",
  { "foreign.phylotree_id" => "self.phylotree_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonodes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phylonode>

=cut

__PACKAGE__->has_many(
  "phylonodes",
  "Database::Chado::Schema::Result::Phylonode",
  { "foreign.phylotree_id" => "self.phylotree_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotree_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylotreePub>

=cut

__PACKAGE__->has_many(
  "phylotree_pubs",
  "Database::Chado::Schema::Result::PhylotreePub",
  { "foreign.phylotree_id" => "self.phylotree_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QqS4rzWrBsIiRsNB6e8iow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
