use utf8;
package Database::Chado::TestSchema::Result::Studyprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Studyprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<studyprop>

=cut

__PACKAGE__->table("studyprop");

=head1 ACCESSORS

=head2 studyprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studyprop_studyprop_id_seq'

=head2 study_id

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
  "studyprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studyprop_studyprop_id_seq",
  },
  "study_id",
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

=item * L</studyprop_id>

=back

=cut

__PACKAGE__->set_primary_key("studyprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<studyprop_study_id_type_id_rank_key>

=over 4

=item * L</study_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "studyprop_study_id_type_id_rank_key",
  ["study_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 study

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Study>

=cut

__PACKAGE__->belongs_to(
  "study",
  "Database::Chado::TestSchema::Result::Study",
  { study_id => "study_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 studyprop_features

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StudypropFeature>

=cut

__PACKAGE__->has_many(
  "studyprop_features",
  "Database::Chado::TestSchema::Result::StudypropFeature",
  { "foreign.studyprop_id" => "self.studyprop_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/tm+4xkQqVjwGudqVikrHw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
