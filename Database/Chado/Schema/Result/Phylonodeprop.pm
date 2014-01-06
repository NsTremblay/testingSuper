use utf8;
package Database::Chado::Schema::Result::Phylonodeprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Phylonodeprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phylonodeprop>

=cut

__PACKAGE__->table("phylonodeprop");

=head1 ACCESSORS

=head2 phylonodeprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylonodeprop_phylonodeprop_id_seq'

=head2 phylonode_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

type_id could designate phylonode hierarchy relationships, for example: species taxonomy (kingdom, order, family, genus, species), "ortholog/paralog", "fold/superfold", etc.

=head2 value

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phylonodeprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylonodeprop_phylonodeprop_id_seq",
  },
  "phylonode_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phylonodeprop_id>

=back

=cut

__PACKAGE__->set_primary_key("phylonodeprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<phylonodeprop_phylonode_id_type_id_value_rank_key>

=over 4

=item * L</phylonode_id>

=item * L</type_id>

=item * L</value>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phylonodeprop_phylonode_id_type_id_value_rank_key",
  ["phylonode_id", "type_id", "value", "rank"],
);

=head1 RELATIONS

=head2 phylonode

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phylonode>

=cut

__PACKAGE__->belongs_to(
  "phylonode",
  "Database::Chado::Schema::Result::Phylonode",
  { phylonode_id => "phylonode_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WwBe596b8Ip5nbza+vf91Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
