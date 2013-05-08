use utf8;
package Database::Chado::TestSchema::Result::Element;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Element

=head1 DESCRIPTION

Represents a feature of the array. This is typically a region of the array coated or bound to DNA.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<element>

=cut

__PACKAGE__->table("element");

=head1 ACCESSORS

=head2 element_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'element_element_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 arraydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "element_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "element_element_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "arraydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</element_id>

=back

=cut

__PACKAGE__->set_primary_key("element_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<element_c1>

=over 4

=item * L</feature_id>

=item * L</arraydesign_id>

=back

=cut

__PACKAGE__->add_unique_constraint("element_c1", ["feature_id", "arraydesign_id"]);

=head1 RELATIONS

=head2 arraydesign

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Arraydesign>

=cut

__PACKAGE__->belongs_to(
  "arraydesign",
  "Database::Chado::TestSchema::Result::Arraydesign",
  { arraydesign_id => "arraydesign_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::TestSchema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 element_relationship_objects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationship_objects",
  "Database::Chado::TestSchema::Result::ElementRelationship",
  { "foreign.object_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 element_relationship_subjects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationship_subjects",
  "Database::Chado::TestSchema::Result::ElementRelationship",
  { "foreign.subject_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elementresults

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Elementresult>

=cut

__PACKAGE__->has_many(
  "elementresults",
  "Database::Chado::TestSchema::Result::Elementresult",
  { "foreign.element_id" => "self.element_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::TestSchema::Result::Feature",
  { feature_id => "feature_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LkgAOlLve4eXOjzXe86iAQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
