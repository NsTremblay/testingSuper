use utf8;
package Database::Chado::Schema::Result::StockDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::StockDbxref

=head1 DESCRIPTION

stock_dbxref links a stock to dbxrefs. This is for secondary identifiers; primary identifiers should use stock.dbxref_id.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_dbxref>

=cut

__PACKAGE__->table("stock_dbxref");

=head1 ACCESSORS

=head2 stock_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_dbxref_stock_dbxref_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked stock.

=cut

__PACKAGE__->add_columns(
  "stock_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_dbxref_stock_dbxref_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_dbxref_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_dbxref_c1>

=over 4

=item * L</stock_id>

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_dbxref_c1", ["stock_id", "dbxref_id"]);

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

=head2 stock

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Database::Chado::Schema::Result::Stock",
  { stock_id => "stock_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 stock_dbxrefprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockDbxrefprop>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefprops",
  "Database::Chado::Schema::Result::StockDbxrefprop",
  { "foreign.stock_dbxref_id" => "self.stock_dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:36gzJL4nuBefhbZKZ6LCyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
