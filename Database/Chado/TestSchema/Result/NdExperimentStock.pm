use utf8;
package Database::Chado::TestSchema::Result::NdExperimentStock;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::NdExperimentStock

=head1 DESCRIPTION

Part of a stock or a clone of a stock that is used in an experiment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_stock>

=cut

__PACKAGE__->table("nd_experiment_stock");

=head1 ACCESSORS

=head2 nd_experiment_stock_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_stock_nd_experiment_stock_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

stock used in the extraction or the corresponding stock for the clone

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_stock_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_stock_nd_experiment_stock_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_stock_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_stock_id");

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

=head2 nd_experiment_stock_dbxrefs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdExperimentStockDbxref>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stock_dbxrefs",
  "Database::Chado::TestSchema::Result::NdExperimentStockDbxref",
  {
    "foreign.nd_experiment_stock_id" => "self.nd_experiment_stock_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stockprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdExperimentStockprop>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stockprops",
  "Database::Chado::TestSchema::Result::NdExperimentStockprop",
  {
    "foreign.nd_experiment_stock_id" => "self.nd_experiment_stock_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Database::Chado::TestSchema::Result::Stock",
  { stock_id => "stock_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wMliFR5SVKcAd47nMnm7bw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
