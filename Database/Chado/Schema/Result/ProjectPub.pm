use utf8;
package Database::Chado::Schema::Result::ProjectPub;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::ProjectPub - Linking project(s) to publication(s)

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project_pub>

=cut

__PACKAGE__->table("project_pub");

=head1 ACCESSORS

=head2 project_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_pub_project_pub_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_pub_project_pub_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_pub_id>

=back

=cut

__PACKAGE__->set_primary_key("project_pub_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<project_pub_c1>

=over 4

=item * L</project_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint("project_pub_c1", ["project_id", "pub_id"]);

=head1 RELATIONS

=head2 project

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Database::Chado::Schema::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gpP6iPLxGO4MHNedrCCJDw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
