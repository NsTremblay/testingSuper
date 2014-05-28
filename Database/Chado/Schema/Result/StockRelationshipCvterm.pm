use utf8;
package Database::Chado::Schema::Result::StockRelationshipCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::StockRelationshipCvterm

=head1 DESCRIPTION

For germplasm maintenance and pedigree data, stock_relationship. type_id will record cvterms such as "is a female parent of", "a parent for mutation", "is a group_id of", "is a source_id of", etc The cvterms for higher categories such as "generative", "derivative" or "maintenance" can be stored in table stock_relationship_cvterm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_relationship_cvterm>

=cut

__PACKAGE__->table("stock_relationship_cvterm");

=head1 ACCESSORS

=head2 stock_relationship_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_relationship_cvterm_stock_relationship_cvterm_id_seq'

=head2 stock_relationship_id

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
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "stock_relationship_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_relationship_cvterm_stock_relationship_cvterm_id_seq",
  },
  "stock_relationship_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_relationship_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_relationship_cvterm_id");

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "NO ACTION",
  },
);

=head2 stock_relationship

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::StockRelationship>

=cut

__PACKAGE__->belongs_to(
  "stock_relationship",
  "Database::Chado::Schema::Result::StockRelationship",
  { stock_relationship_id => "stock_relationship_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZYI6ws6cfwuFEkWW32QKQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
