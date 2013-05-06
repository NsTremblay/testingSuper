use utf8;
package Database::Chado::TestSchema::Result::Stock;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Stock

=head1 DESCRIPTION

Any stock can be globally identified by the
combination of organism, uniquename and stock type. A stock is the physical entities, either living or preserved, held by collections. Stocks belong to a collection; they have IDs, type, organism, description and may have a genotype.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock>

=cut

__PACKAGE__->table("stock");

=head1 ACCESSORS

=head2 stock_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_stock_id_seq'

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

The dbxref_id is an optional primary stable identifier for this stock. Secondary indentifiers and external dbxrefs go in table: stock_dbxref.

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

The organism_id is the organism to which the stock belongs. This column should only be left blank if the organism cannot be determined.

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

The name is a human-readable local name for a stock.

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

The description is the genetic description provided in the stock list.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type_id foreign key links to a controlled vocabulary of stock types. The would include living stock, genomic DNA, preserved specimen. Secondary cvterms for stocks would go in stock_cvterm.

=head2 is_obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_stock_id_seq",
  },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stock_c1>

=over 4

=item * L</organism_id>

=item * L</uniquename>

=item * L</type_id>

=back

=cut

__PACKAGE__->add_unique_constraint("stock_c1", ["organism_id", "uniquename", "type_id"]);

=head1 RELATIONS

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::TestSchema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 nd_experiment_stocks

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdExperimentStock>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stocks",
  "Database::Chado::TestSchema::Result::NdExperimentStock",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Database::Chado::TestSchema::Result::Organism",
  { organism_id => "organism_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Database::Chado::TestSchema::Result::StockCvterm",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_dbxrefs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockDbxref>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefs",
  "Database::Chado::TestSchema::Result::StockDbxref",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_genotypes

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockGenotype>

=cut

__PACKAGE__->has_many(
  "stock_genotypes",
  "Database::Chado::TestSchema::Result::StockGenotype",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_pubs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockPub>

=cut

__PACKAGE__->has_many(
  "stock_pubs",
  "Database::Chado::TestSchema::Result::StockPub",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_objects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationship_objects",
  "Database::Chado::TestSchema::Result::StockRelationship",
  { "foreign.object_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_subjects

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationship_subjects",
  "Database::Chado::TestSchema::Result::StockRelationship",
  { "foreign.subject_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollection_stocks

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::StockcollectionStock>

=cut

__PACKAGE__->has_many(
  "stockcollection_stocks",
  "Database::Chado::TestSchema::Result::StockcollectionStock",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Stockprop>

=cut

__PACKAGE__->has_many(
  "stockprops",
  "Database::Chado::TestSchema::Result::Stockprop",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ZEvBd6BvkTv20NJBXF4KA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
