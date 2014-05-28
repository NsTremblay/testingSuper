use utf8;
package Database::Chado::Schema::Result::PhenotypeComparisonCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PhenotypeComparisonCvterm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotype_comparison_cvterm>

=cut

__PACKAGE__->table("phenotype_comparison_cvterm");

=head1 ACCESSORS

=head2 phenotype_comparison_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_comparison_cvterm_phenotype_comparison_cvterm_id_seq'

=head2 phenotype_comparison_id

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

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenotype_comparison_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_comparison_cvterm_phenotype_comparison_cvterm_id_seq",
  },
  "phenotype_comparison_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phenotype_comparison_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("phenotype_comparison_cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<phenotype_comparison_cvterm_c1>

=over 4

=item * L</phenotype_comparison_id>

=item * L</cvterm_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phenotype_comparison_cvterm_c1",
  ["phenotype_comparison_id", "cvterm_id"],
);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 phenotype_comparison

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::PhenotypeComparison>

=cut

__PACKAGE__->belongs_to(
  "phenotype_comparison",
  "Database::Chado::Schema::Result::PhenotypeComparison",
  { phenotype_comparison_id => "phenotype_comparison_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4wbem/bszMVTy4f13pz4TA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
