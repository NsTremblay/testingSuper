use utf8;
package Database::Chado::Schema::Result::FeatureGenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeatureGenotype

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_genotype>

=cut

__PACKAGE__->table("feature_genotype");

=head1 ACCESSORS

=head2 feature_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_genotype_feature_genotype_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 chromosome_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

A feature of SO type "chromosome".

=head2 rank

  data_type: 'integer'
  is_nullable: 0

rank can be used for
n-ploid organisms or to preserve order.

=head2 cgroup

  data_type: 'integer'
  is_nullable: 0

Spatially distinguishable
group. group can be used for distinguishing the chromosomal groups,
for example (RNAi products and so on can be treated as different
groups, as they do not fall on a particular chromosome).

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_genotype_feature_genotype_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "chromosome_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
  "cgroup",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_genotype_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<feature_genotype_c1>

=over 4

=item * L</feature_id>

=item * L</genotype_id>

=item * L</cvterm_id>

=item * L</chromosome_id>

=item * L</rank>

=item * L</cgroup>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "feature_genotype_c1",
  [
    "feature_id",
    "genotype_id",
    "cvterm_id",
    "chromosome_id",
    "rank",
    "cgroup",
  ],
);

=head1 RELATIONS

=head2 chromosome

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "chromosome",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "chromosome_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

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

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 genotype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype",
  "Database::Chado::Schema::Result::Genotype",
  { genotype_id => "genotype_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4/9tE3qGyziwScPzEXt3rA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
