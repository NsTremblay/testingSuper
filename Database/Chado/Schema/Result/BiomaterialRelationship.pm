use utf8;
package Database::Chado::Schema::Result::BiomaterialRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::BiomaterialRelationship

=head1 DESCRIPTION

Relate biomaterials to one another. This is a way to track a series of treatments or material splits/merges, for instance.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<biomaterial_relationship>

=cut

__PACKAGE__->table("biomaterial_relationship");

=head1 ACCESSORS

=head2 biomaterial_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterial_relationship_biomaterial_relationship_id_seq'

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "biomaterial_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterial_relationship_biomaterial_relationship_id_seq",
  },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</biomaterial_relationship_id>

=back

=cut

__PACKAGE__->set_primary_key("biomaterial_relationship_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<biomaterial_relationship_c1>

=over 4

=item * L</subject_id>

=item * L</object_id>

=item * L</type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "biomaterial_relationship_c1",
  ["subject_id", "object_id", "type_id"],
);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Database::Chado::Schema::Result::Biomaterial",
  { biomaterial_id => "object_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 subject

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Database::Chado::Schema::Result::Biomaterial",
  { biomaterial_id => "subject_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wdztsfr0PTIiw/7iugjTVw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
