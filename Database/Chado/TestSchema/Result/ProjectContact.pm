use utf8;
package Database::Chado::TestSchema::Result::ProjectContact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::ProjectContact - Linking project(s) to contact(s)

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project_contact>

=cut

__PACKAGE__->table("project_contact");

=head1 ACCESSORS

=head2 project_contact_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_contact_project_contact_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project_contact_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_contact_project_contact_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_contact_id>

=back

=cut

__PACKAGE__->set_primary_key("project_contact_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<project_contact_c1>

=over 4

=item * L</project_id>

=item * L</contact_id>

=back

=cut

__PACKAGE__->add_unique_constraint("project_contact_c1", ["project_id", "contact_id"]);

=head1 RELATIONS

=head2 contact

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Database::Chado::TestSchema::Result::Contact",
  { contact_id => "contact_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 project

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Database::Chado::TestSchema::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vUwJAK3m3zRCsLzld5/KNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
