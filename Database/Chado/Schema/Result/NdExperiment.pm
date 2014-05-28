use utf8;
package Database::Chado::Schema::Result::NdExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::NdExperiment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment>

=cut

__PACKAGE__->table("nd_experiment");

=head1 ACCESSORS

=head2 nd_experiment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_nd_experiment_id_seq'

=head2 nd_geolocation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_nd_experiment_id_seq",
  },
  "nd_geolocation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_id");

=head1 RELATIONS

=head2 nd_experiment_contacts

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentContact>

=cut

__PACKAGE__->has_many(
  "nd_experiment_contacts",
  "Database::Chado::Schema::Result::NdExperimentContact",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_dbxrefs

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentDbxref>

=cut

__PACKAGE__->has_many(
  "nd_experiment_dbxrefs",
  "Database::Chado::Schema::Result::NdExperimentDbxref",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentGenotype>

=cut

__PACKAGE__->has_many(
  "nd_experiment_genotypes",
  "Database::Chado::Schema::Result::NdExperimentGenotype",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_phenotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentPhenotype>

=cut

__PACKAGE__->has_many(
  "nd_experiment_phenotypes",
  "Database::Chado::Schema::Result::NdExperimentPhenotype",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_projects

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentProject>

=cut

__PACKAGE__->has_many(
  "nd_experiment_projects",
  "Database::Chado::Schema::Result::NdExperimentProject",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_protocols

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentProtocol>

=cut

__PACKAGE__->has_many(
  "nd_experiment_protocols",
  "Database::Chado::Schema::Result::NdExperimentProtocol",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentPub>

=cut

__PACKAGE__->has_many(
  "nd_experiment_pubs",
  "Database::Chado::Schema::Result::NdExperimentPub",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stocks

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentStock>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stocks",
  "Database::Chado::Schema::Result::NdExperimentStock",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experimentprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentprop>

=cut

__PACKAGE__->has_many(
  "nd_experimentprops",
  "Database::Chado::Schema::Result::NdExperimentprop",
  { "foreign.nd_experiment_id" => "self.nd_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_geolocation

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::NdGeolocation>

=cut

__PACKAGE__->belongs_to(
  "nd_geolocation",
  "Database::Chado::Schema::Result::NdGeolocation",
  { nd_geolocation_id => "nd_geolocation_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EUoo851CYWP1dsIBnXo2LQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
