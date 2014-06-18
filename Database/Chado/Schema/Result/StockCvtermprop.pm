use utf8;
package Database::Chado::Schema::Result::StockCvtermprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::StockCvtermprop

=head1 DESCRIPTION

Extensible properties for
stock to cvterm associations. Examples: GO evidence codes;
qualifiers; metadata such as the date on which the entry was curated
and the source of the association. See the stockprop table for
meanings of type_id, value and rank.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_cvtermprop>

=cut

__PACKAGE__->table("stock_cvtermprop");

=head1 ACCESSORS

=head2 stock_cvtermprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_cvtermprop_stock_cvtermprop_id_seq'

=head2 stock_cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. cvterms may come from the OBO evidence code cv.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Property-Value
ordering. Any stock_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.

=cut

__PACKAGE__->add_columns(
  "stock_cvtermprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_cvtermprop_stock_cvtermprop_id_seq",
  },
  "stock_cvterm_id",
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

=item * L</stock_cvtermprop_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_cvtermprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_cvtermprop_c1>

=over 4

=item * L</stock_cvterm_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_cvtermprop_c1", ["stock_cvterm_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 stock_cvterm

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::StockCvterm>

=cut

__PACKAGE__->belongs_to(
  "stock_cvterm",
  "Database::Chado::Schema::Result::StockCvterm",
  { stock_cvterm_id => "stock_cvterm_id" },
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
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B/yLF2gQUbshOuOdnSY9dg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
