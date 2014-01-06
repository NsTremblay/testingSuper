use utf8;
package Database::Chado::Schema::Result::Studydesign;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Studydesign

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<studydesign>

=cut

__PACKAGE__->table("studydesign");

=head1 ACCESSORS

=head2 studydesign_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studydesign_studydesign_id_seq'

=head2 study_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "studydesign_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studydesign_studydesign_id_seq",
  },
  "study_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</studydesign_id>

=back

=cut

__PACKAGE__->set_primary_key("studydesign_id");

=head1 RELATIONS

=head2 study

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Study>

=cut

__PACKAGE__->belongs_to(
  "study",
  "Database::Chado::Schema::Result::Study",
  { study_id => "study_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 studydesignprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studydesignprop>

=cut

__PACKAGE__->has_many(
  "studydesignprops",
  "Database::Chado::Schema::Result::Studydesignprop",
  { "foreign.studydesign_id" => "self.studydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactors

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studyfactor>

=cut

__PACKAGE__->has_many(
  "studyfactors",
  "Database::Chado::Schema::Result::Studyfactor",
  { "foreign.studydesign_id" => "self.studydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4/1GPM7dHO64rfHybRzMpA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
