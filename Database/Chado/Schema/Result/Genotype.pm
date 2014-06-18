use utf8;
package Database::Chado::Schema::Result::Genotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Genotype

=head1 DESCRIPTION

Genetic context. A genotype is defined by a collection of features, mutations, balancers, deficiencies, haplotype blocks, or engineered constructs.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<genotype>

=cut

__PACKAGE__->table("genotype");

=head1 ACCESSORS

=head2 genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotype_genotype_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

Optional alternative name for a genotype, 
for display purposes.

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

The unique name for a genotype; 
typically derived from the features making up the genotype.

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotype_genotype_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("genotype_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<genotype_c1>

=over 4

=item * L</uniquename>

=back

=cut

__PACKAGE__->add_unique_constraint("genotype_c1", ["uniquename"]);

=head1 RELATIONS

=head2 feature_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureGenotype>

=cut

__PACKAGE__->has_many(
  "feature_genotypes",
  "Database::Chado::Schema::Result::FeatureGenotype",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotypeprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Genotypeprop>

=cut

__PACKAGE__->has_many(
  "genotypeprops",
  "Database::Chado::Schema::Result::Genotypeprop",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentGenotype>

=cut

__PACKAGE__->has_many(
  "nd_experiment_genotypes",
  "Database::Chado::Schema::Result::NdExperimentGenotype",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Database::Chado::Schema::Result::Phendesc",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_genotype1s

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_genotype1s",
  "Database::Chado::Schema::Result::PhenotypeComparison",
  { "foreign.genotype1_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_genotype2s

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_genotype2s",
  "Database::Chado::Schema::Result::PhenotypeComparison",
  { "foreign.genotype2_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Database::Chado::Schema::Result::Phenstatement",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockGenotype>

=cut

__PACKAGE__->has_many(
  "stock_genotypes",
  "Database::Chado::Schema::Result::StockGenotype",
  { "foreign.genotype_id" => "self.genotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5usKPOPtCugJKtIWTjI7ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
