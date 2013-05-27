use utf8;
package Database::Chado::Schema::Result::PrivateFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PrivateFeature

=head1 DESCRIPTION

private_feature is identical to feature table but is 
intended to contain private data only available to specific users.  The table
private_feature contains upload_id column. This column references the upload table and
links sequences to specific users via the permission table.  All other columns are
identical in feature and private_feature.  See feature table comments for further 
information on other columns.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<private_feature>

=cut

__PACKAGE__->table("private_feature");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'private_feature_feature_id_seq'

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 residues

  data_type: 'text'
  is_nullable: 1

=head2 seqlen

  data_type: 'integer'
  is_nullable: 1

=head2 md5checksum

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_analysis

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_obsolete

  data_type: 'boolean'
  default_value: false
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

=head2 upload_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "private_feature_feature_id_seq",
  },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "residues",
  { data_type => "text", is_nullable => 1 },
  "seqlen",
  { data_type => "integer", is_nullable => 1 },
  "md5checksum",
  { data_type => "char", is_nullable => 1, size => 32 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_analysis",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
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
  "upload_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<private_feature_c1>

=over 4

=item * L</organism_id>

=item * L</uniquename>

=item * L</type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "private_feature_c1",
  ["organism_id", "uniquename", "type_id"],
);

=head1 RELATIONS

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

=head2 organism

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Database::Chado::Schema::Result::Organism",
  { organism_id => "organism_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 private_feature_dbxrefs

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeatureDbxref>

=cut

__PACKAGE__->has_many(
  "private_feature_dbxrefs",
  "Database::Chado::Schema::Result::PrivateFeatureDbxref",
  { "foreign.feature_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_feature_relationship_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeatureRelationship>

=cut

__PACKAGE__->has_many(
  "private_feature_relationship_objects",
  "Database::Chado::Schema::Result::PrivateFeatureRelationship",
  { "foreign.object_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_feature_relationship_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeatureRelationship>

=cut

__PACKAGE__->has_many(
  "private_feature_relationship_subjects",
  "Database::Chado::Schema::Result::PrivateFeatureRelationship",
  { "foreign.subject_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_featureprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeatureprop>

=cut

__PACKAGE__->has_many(
  "private_featureprops",
  "Database::Chado::Schema::Result::PrivateFeatureprop",
  { "foreign.feature_id" => "self.feature_id" },
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
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 upload

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Upload>

=cut

__PACKAGE__->belongs_to(
  "upload",
  "Database::Chado::Schema::Result::Upload",
  { upload_id => "upload_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-27 15:24:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FpYPH3+TlY0LTHxwMYBxXw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
