use utf8;
package Database::Chado::Schema::Result::NdExperimentStockDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::NdExperimentStockDbxref - Cross-reference experiment_stock to accessions, images, etc

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_stock_dbxref>

=cut

__PACKAGE__->table("nd_experiment_stock_dbxref");

=head1 ACCESSORS

=head2 nd_experiment_stock_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_stock_dbxref_nd_experiment_stock_dbxref_id_seq'

=head2 nd_experiment_stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_stock_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_stock_dbxref_nd_experiment_stock_dbxref_id_seq",
  },
  "nd_experiment_stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_stock_dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_stock_dbxref_id");

=head1 RELATIONS

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nd_experiment_stock

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::NdExperimentStock>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment_stock",
  "Database::Chado::Schema::Result::NdExperimentStock",
  { nd_experiment_stock_id => "nd_experiment_stock_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iDvyBQtRwqb//aUOy/W/uw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
