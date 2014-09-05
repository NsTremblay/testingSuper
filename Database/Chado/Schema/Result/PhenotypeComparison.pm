use utf8;
package Database::Chado::Schema::Result::PhenotypeComparison;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PhenotypeComparison

=head1 DESCRIPTION

Comparison of phenotypes e.g., genotype1/environment1/phenotype1 "non-suppressible" with respect to genotype2/environment2/phenotype2.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotype_comparison>

=cut

__PACKAGE__->table("phenotype_comparison");

=head1 ACCESSORS

=head2 phenotype_comparison_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_comparison_phenotype_comparison_id_seq'

=head2 genotype1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenotype_comparison_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_comparison_phenotype_comparison_id_seq",
  },
  "genotype1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phenotype_comparison_id>

=back

=cut

__PACKAGE__->set_primary_key("phenotype_comparison_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<phenotype_comparison_c1>

=over 4

=item * L</genotype1_id>

=item * L</environment1_id>

=item * L</genotype2_id>

=item * L</environment2_id>

=item * L</phenotype1_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phenotype_comparison_c1",
  [
    "genotype1_id",
    "environment1_id",
    "genotype2_id",
    "environment2_id",
    "phenotype1_id",
    "pub_id",
  ],
);

=head1 RELATIONS

=head2 environment1

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment1",
  "Database::Chado::Schema::Result::Environment",
  { environment_id => "environment1_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 environment2

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment2",
  "Database::Chado::Schema::Result::Environment",
  { environment_id => "environment2_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 genotype1

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype1",
  "Database::Chado::Schema::Result::Genotype",
  { genotype_id => "genotype1_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 genotype2

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype2",
  "Database::Chado::Schema::Result::Genotype",
  { genotype_id => "genotype2_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 organism

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Database::Chado::Schema::Result::Organism",
  { organism_id => "organism_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 phenotype1

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype1",
  "Database::Chado::Schema::Result::Phenotype",
  { phenotype_id => "phenotype1_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 phenotype2

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype2",
  "Database::Chado::Schema::Result::Phenotype",
  { phenotype_id => "phenotype2_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Database::Chado::Schema::Result::PhenotypeComparisonCvterm",
  {
    "foreign.phenotype_comparison_id" => "self.phenotype_comparison_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hkhfviox1wDbYpsNLQDMZQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
