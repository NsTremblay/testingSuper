use utf8;
package Database::Chado::Schema::Result::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Contact - Model persons, institutes, groups, organizations, etc.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<contact>

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contact_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'contact_contact_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

What type of contact is this?  E.g. "person", "lab".

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "contact_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "contact_contact_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contact_id>

=back

=cut

__PACKAGE__->set_primary_key("contact_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<contact_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("contact_c1", ["name"]);

=head1 RELATIONS

=head2 arraydesigns

Type: has_many

Related object: L<Database::Chado::Schema::Result::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesigns",
  "Database::Chado::Schema::Result::Arraydesign",
  { "foreign.manufacturer_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assays

Type: has_many

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->has_many(
  "assays",
  "Database::Chado::Schema::Result::Assay",
  { "foreign.operator_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterials

Type: has_many

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->has_many(
  "biomaterials",
  "Database::Chado::Schema::Result::Biomaterial",
  { "foreign.biosourceprovider_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_relationship_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationship_objects",
  "Database::Chado::Schema::Result::ContactRelationship",
  { "foreign.object_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_relationship_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationship_subjects",
  "Database::Chado::Schema::Result::ContactRelationship",
  { "foreign.subject_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_contacts

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentContact>

=cut

__PACKAGE__->has_many(
  "nd_experiment_contacts",
  "Database::Chado::Schema::Result::NdExperimentContact",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_contacts

Type: has_many

Related object: L<Database::Chado::Schema::Result::ProjectContact>

=cut

__PACKAGE__->has_many(
  "project_contacts",
  "Database::Chado::Schema::Result::ProjectContact",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantifications

Type: has_many

Related object: L<Database::Chado::Schema::Result::Quantification>

=cut

__PACKAGE__->has_many(
  "quantifications",
  "Database::Chado::Schema::Result::Quantification",
  { "foreign.operator_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollections

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stockcollection>

=cut

__PACKAGE__->has_many(
  "stockcollections",
  "Database::Chado::Schema::Result::Stockcollection",
  { "foreign.contact_id" => "self.contact_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studies

Type: has_many

Related object: L<Database::Chado::Schema::Result::Study>

=cut

__PACKAGE__->has_many(
  "studies",
  "Database::Chado::Schema::Result::Study",
  { "foreign.contact_id" => "self.contact_id" },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DnNdAUNNYQdYySi7KPbZ+A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
