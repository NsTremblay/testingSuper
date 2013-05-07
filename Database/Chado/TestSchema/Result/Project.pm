use utf8;
package Database::Chado::TestSchema::Result::Project;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Project

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project>

=cut

__PACKAGE__->table("project");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_project_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_project_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_id>

=back

=cut

__PACKAGE__->set_primary_key("project_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<project_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("project_c1", ["name"]);

=head1 RELATIONS

=head2 assay_projects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::AssayProject>

=cut

__PACKAGE__->has_many(
  "assay_projects",
  "Database::Chado::TestSchema::Result::AssayProject",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_projects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdExperimentProject>

=cut

__PACKAGE__->has_many(
  "nd_experiment_projects",
  "Database::Chado::TestSchema::Result::NdExperimentProject",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_contacts

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ProjectContact>

=cut

__PACKAGE__->has_many(
  "project_contacts",
  "Database::Chado::TestSchema::Result::ProjectContact",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_pubs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ProjectPub>

=cut

__PACKAGE__->has_many(
  "project_pubs",
  "Database::Chado::TestSchema::Result::ProjectPub",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationship_object_projects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationship_object_projects",
  "Database::Chado::TestSchema::Result::ProjectRelationship",
  { "foreign.object_project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationship_subject_projects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationship_subject_projects",
  "Database::Chado::TestSchema::Result::ProjectRelationship",
  { "foreign.subject_project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Projectprop>

=cut

__PACKAGE__->has_many(
  "projectprops",
  "Database::Chado::TestSchema::Result::Projectprop",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JH7v9qxskhW9m1LBIEPg1g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
