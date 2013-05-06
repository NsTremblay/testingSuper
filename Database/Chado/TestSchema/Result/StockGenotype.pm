use utf8;
package Database::Chado::TestSchema::Result::StockGenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::StockGenotype

=head1 DESCRIPTION

Simple table linking a stock to
a genotype. Features with genotypes can be linked to stocks thru feature_genotype -> genotype -> stock_genotype -> stock.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_genotype>

=cut

__PACKAGE__->table("stock_genotype");

=head1 ACCESSORS

=head2 stock_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_genotype_stock_genotype_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_genotype_stock_genotype_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_genotype_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_genotype_c1>

=over 4

=item * L</stock_id>

=item * L</genotype_id>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_genotype_c1", ["stock_id", "genotype_id"]);

=head1 RELATIONS

=head2 genotype

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype",
  "Database::Chado::TestSchema::Result::Genotype",
  { genotype_id => "genotype_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 stock

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Database::Chado::TestSchema::Result::Stock",
  { stock_id => "stock_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FhumgFkiQDBT6T9ICTVQQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
