use utf8;
package Database::Chado::TestSchema::Result::CellLine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::CellLine

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cell_line>

=cut

__PACKAGE__->table("cell_line");

=head1 ACCESSORS

=head2 cell_line_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_cell_line_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 timeaccessioned

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 timelastmodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "cell_line_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_cell_line_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "timeaccessioned",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "timelastmodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cell_line_id>

=back

=cut

__PACKAGE__->set_primary_key("cell_line_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cell_line_c1>

=over 4

=item * L</uniquename>

=item * L</organism_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cell_line_c1", ["uniquename", "organism_id"]);

=head1 RELATIONS

=head2 cell_line_cvterms

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Database::Chado::TestSchema::Result::CellLineCvterm",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_dbxrefs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineDbxref>

=cut

__PACKAGE__->has_many(
  "cell_line_dbxrefs",
  "Database::Chado::TestSchema::Result::CellLineDbxref",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_features

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineFeature>

=cut

__PACKAGE__->has_many(
  "cell_line_features",
  "Database::Chado::TestSchema::Result::CellLineFeature",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_libraries

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineLibrary>

=cut

__PACKAGE__->has_many(
  "cell_line_libraries",
  "Database::Chado::TestSchema::Result::CellLineLibrary",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_pubs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLinePub>

=cut

__PACKAGE__->has_many(
  "cell_line_pubs",
  "Database::Chado::TestSchema::Result::CellLinePub",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationship_objects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationship_objects",
  "Database::Chado::TestSchema::Result::CellLineRelationship",
  { "foreign.object_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationship_subjects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationship_subjects",
  "Database::Chado::TestSchema::Result::CellLineRelationship",
  { "foreign.subject_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_synonyms

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineSynonym>

=cut

__PACKAGE__->has_many(
  "cell_line_synonyms",
  "Database::Chado::TestSchema::Result::CellLineSynonym",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::CellLineprop>

=cut

__PACKAGE__->has_many(
  "cell_lineprops",
  "Database::Chado::TestSchema::Result::CellLineprop",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Database::Chado::TestSchema::Result::Organism",
  { organism_id => "organism_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EZcBIa1epdbuIA1gUQWhtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
