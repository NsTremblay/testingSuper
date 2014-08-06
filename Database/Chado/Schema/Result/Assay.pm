use utf8;
package Database::Chado::Schema::Result::Assay;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Assay

=head1 DESCRIPTION

An assay consists of a physical instance of
an array, combined with the conditions used to create the array
(protocols, technician information). The assay can be thought of as a hybridization.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<assay>

=cut

__PACKAGE__->table("assay");

=head1 ACCESSORS

=head2 assay_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'assay_assay_id_seq'

=head2 arraydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 assaydate

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 arrayidentifier

  data_type: 'text'
  is_nullable: 1

=head2 arraybatchidentifier

  data_type: 'text'
  is_nullable: 1

=head2 operator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "assay_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "assay_assay_id_seq",
  },
  "arraydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "assaydate",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "arrayidentifier",
  { data_type => "text", is_nullable => 1 },
  "arraybatchidentifier",
  { data_type => "text", is_nullable => 1 },
  "operator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</assay_id>

=back

=cut

__PACKAGE__->set_primary_key("assay_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<assay_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("assay_c1", ["name"]);

=head1 RELATIONS

=head2 acquisitions

Type: has_many

Related object: L<Database::Chado::Schema::Result::Acquisition>

=cut

__PACKAGE__->has_many(
  "acquisitions",
  "Database::Chado::Schema::Result::Acquisition",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesign

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Arraydesign>

=cut

__PACKAGE__->belongs_to(
  "arraydesign",
  "Database::Chado::Schema::Result::Arraydesign",
  { arraydesign_id => "arraydesign_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 assay_biomaterials

Type: has_many

Related object: L<Database::Chado::Schema::Result::AssayBiomaterial>

=cut

__PACKAGE__->has_many(
  "assay_biomaterials",
  "Database::Chado::Schema::Result::AssayBiomaterial",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay_projects

Type: has_many

Related object: L<Database::Chado::Schema::Result::AssayProject>

=cut

__PACKAGE__->has_many(
  "assay_projects",
  "Database::Chado::Schema::Result::AssayProject",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assayprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Assayprop>

=cut

__PACKAGE__->has_many(
  "assayprops",
  "Database::Chado::Schema::Result::Assayprop",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 controls

Type: has_many

Related object: L<Database::Chado::Schema::Result::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Database::Chado::Schema::Result::Control",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 operator

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "operator",
  "Database::Chado::Schema::Result::Contact",
  { contact_id => "operator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 protocol

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Database::Chado::Schema::Result::Protocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 study_assays

Type: has_many

Related object: L<Database::Chado::Schema::Result::StudyAssay>

=cut

__PACKAGE__->has_many(
  "study_assays",
  "Database::Chado::Schema::Result::StudyAssay",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactorvalues

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studyfactorvalue>

=cut

__PACKAGE__->has_many(
  "studyfactorvalues",
  "Database::Chado::Schema::Result::Studyfactorvalue",
  { "foreign.assay_id" => "self.assay_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qRFwn3fOakSgrwgXXyRiGQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
