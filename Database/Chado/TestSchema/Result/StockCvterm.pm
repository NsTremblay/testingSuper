use utf8;
package Database::Chado::TestSchema::Result::StockCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::StockCvterm

=head1 DESCRIPTION

stock_cvterm links a stock to cvterms. This is for secondary cvterms; primary cvterms should use stock.type_id.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_cvterm>

=cut

__PACKAGE__->table("stock_cvterm");

=head1 ACCESSORS

=head2 stock_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_cvterm_stock_cvterm_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_not

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_cvterm_stock_cvterm_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_not",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_cvterm_c1>

=over 4

=item * L</stock_id>

=item * L</cvterm_id>

=item * L</pub_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "stock_cvterm_c1",
  ["stock_id", "cvterm_id", "pub_id", "rank"],
);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::TestSchema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
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

=head2 stock_cvtermprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockCvtermprop>

=cut

__PACKAGE__->has_many(
  "stock_cvtermprops",
  "Database::Chado::TestSchema::Result::StockCvtermprop",
  { "foreign.stock_cvterm_id" => "self.stock_cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5d4AMNZbTCf3RZ+lMTE6ew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
