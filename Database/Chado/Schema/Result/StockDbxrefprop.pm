use utf8;
package Database::Chado::Schema::Result::StockDbxrefprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::StockDbxrefprop

=head1 DESCRIPTION

A stock_dbxref can have any number of
slot-value property tags attached to it. This is useful for storing properties related to dbxref annotations of stocks, such as evidence codes, and references, and metadata, such as create/modify dates. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stock_dbxrefprop_c1, for
the combination of stock_dbxref_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_dbxrefprop>

=cut

__PACKAGE__->table("stock_dbxrefprop");

=head1 ACCESSORS

=head2 stock_dbxrefprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_dbxrefprop_stock_dbxrefprop_id_seq'

=head2 stock_dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_dbxrefprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_dbxrefprop_stock_dbxrefprop_id_seq",
  },
  "stock_dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_dbxrefprop_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_dbxrefprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_dbxrefprop_c1>

=over 4

=item * L</stock_dbxref_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_dbxrefprop_c1", ["stock_dbxref_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 stock_dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::StockDbxref>

=cut

__PACKAGE__->belongs_to(
  "stock_dbxref",
  "Database::Chado::Schema::Result::StockDbxref",
  { stock_dbxref_id => "stock_dbxref_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3WBZQt1PCduJIObM65MOuA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
