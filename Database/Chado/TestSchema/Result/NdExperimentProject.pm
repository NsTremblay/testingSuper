use utf8;
package Database::Chado::TestSchema::Result::NdExperimentProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::NdExperimentProject

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_project>

=cut

__PACKAGE__->table("nd_experiment_project");

=head1 ACCESSORS

=head2 nd_experiment_project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_project_nd_experiment_project_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_project_nd_experiment_project_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_project_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_project_id");

=head1 RELATIONS

=head2 nd_experiment

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::NdExperiment>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment",
  "Database::Chado::TestSchema::Result::NdExperiment",
  { nd_experiment_id => "nd_experiment_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PoSxX9iPJncFZ4g6dGZp0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
