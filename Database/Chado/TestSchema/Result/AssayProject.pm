use utf8;
package Database::Chado::TestSchema::Result::AssayProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::AssayProject - Link assays to projects.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<assay_project>

=cut

__PACKAGE__->table("assay_project");

=head1 ACCESSORS

=head2 assay_project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'assay_project_assay_project_id_seq'

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "assay_project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "assay_project_assay_project_id_seq",
  },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</assay_project_id>

=back

=cut

__PACKAGE__->set_primary_key("assay_project_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<assay_project_c1>

=over 4

=item * L</assay_id>

=item * L</project_id>

=back

=cut

__PACKAGE__->add_unique_constraint("assay_project_c1", ["assay_id", "project_id"]);

=head1 RELATIONS

=head2 assay

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Database::Chado::TestSchema::Result::Assay",
  { assay_id => "assay_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 project

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Database::Chado::TestSchema::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PwSyxsMIM2CG7u8+EMa+bA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
