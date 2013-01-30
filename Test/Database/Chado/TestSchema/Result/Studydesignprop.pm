use utf8;
package Database::Chado::TestSchema::Result::Studydesignprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Studydesignprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<studydesignprop>

=cut

__PACKAGE__->table("studydesignprop");

=head1 ACCESSORS

=head2 studydesignprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studydesignprop_studydesignprop_id_seq'

=head2 studydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

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
  "studydesignprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studydesignprop_studydesignprop_id_seq",
  },
  "studydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</studydesignprop_id>

=back

=cut

__PACKAGE__->set_primary_key("studydesignprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<studydesignprop_c1>

=over 4

=item * L</studydesign_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("studydesignprop_c1", ["studydesign_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 studydesign

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Studydesign>

=cut

__PACKAGE__->belongs_to(
  "studydesign",
  "Database::Chado::TestSchema::Result::Studydesign",
  { studydesign_id => "studydesign_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0OZNhOAJCyUgdTk2IfKDWg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
