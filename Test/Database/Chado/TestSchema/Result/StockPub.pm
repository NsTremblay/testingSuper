use utf8;
package Database::Chado::TestSchema::Result::StockPub;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::StockPub

=head1 DESCRIPTION

Provenance. Linking table between stocks and, for example, a stocklist computer file.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_pub>

=cut

__PACKAGE__->table("stock_pub");

=head1 ACCESSORS

=head2 stock_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_pub_stock_pub_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_pub_stock_pub_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_pub_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_pub_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_pub_c1>

=over 4

=item * L</stock_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_pub_c1", ["stock_id", "pub_id"]);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IaM43aD0P3qdxRkgLr405A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
