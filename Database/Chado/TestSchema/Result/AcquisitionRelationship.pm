use utf8;
package Database::Chado::TestSchema::Result::AcquisitionRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::AcquisitionRelationship

=head1 DESCRIPTION

Multiple monochrome images may be merged to form a multi-color image. Red-green images of 2-channel hybridizations are an example of this.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<acquisition_relationship>

=cut

__PACKAGE__->table("acquisition_relationship");

=head1 ACCESSORS

=head2 acquisition_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'acquisition_relationship_acquisition_relationship_id_seq'

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

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "acquisition_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "acquisition_relationship_acquisition_relationship_id_seq",
  },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</acquisition_relationship_id>

=back

=cut

__PACKAGE__->set_primary_key("acquisition_relationship_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<acquisition_relationship_c1>

=over 4

=item * L</subject_id>

=item * L</object_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "acquisition_relationship_c1",
  ["subject_id", "object_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Acquisition>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Database::Chado::TestSchema::Result::Acquisition",
  { acquisition_id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 subject

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Acquisition>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Database::Chado::TestSchema::Result::Acquisition",
  { acquisition_id => "subject_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pqVQCLXPzzsWn2xrdkhqVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
