use utf8;
package Database::Chado::Schema::Result::ProjectRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::ProjectRelationship - A project can be composed of several smaller scale projects

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project_relationship>

=cut

__PACKAGE__->table("project_relationship");

=head1 ACCESSORS

=head2 project_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_relationship_project_relationship_id_seq'

=head2 subject_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 object_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type of relationship being stated, such as "is part of".

=cut

__PACKAGE__->add_columns(
  "project_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_relationship_project_relationship_id_seq",
  },
  "subject_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_relationship_id>

=back

=cut

__PACKAGE__->set_primary_key("project_relationship_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<project_relationship_c1>

=over 4

=item * L</subject_project_id>

=item * L</object_project_id>

=item * L</type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "project_relationship_c1",
  ["subject_project_id", "object_project_id", "type_id"],
);

=head1 RELATIONS

=head2 object_project

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "object_project",
  "Database::Chado::Schema::Result::Project",
  { project_id => "object_project_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 subject_project

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "subject_project",
  "Database::Chado::Schema::Result::Project",
  { project_id => "subject_project_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pjxa5JFW5z7Emfs1AyWOuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
