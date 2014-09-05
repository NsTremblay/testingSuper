use utf8;
package Database::Chado::Schema::Result::FeaturePhenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeaturePhenotype

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_phenotype>

=cut

__PACKAGE__->table("feature_phenotype");

=head1 ACCESSORS

=head2 feature_phenotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_phenotype_feature_phenotype_id_seq'

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_phenotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_phenotype_feature_phenotype_id_seq",
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_phenotype_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_phenotype_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<feature_phenotype_c1>

=over 4

=item * L</feature_id>

=item * L</phenotype_id>

=back

=cut

__PACKAGE__->add_unique_constraint("feature_phenotype_c1", ["feature_id", "phenotype_id"]);

=head1 RELATIONS

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 phenotype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype",
  "Database::Chado::Schema::Result::Phenotype",
  { phenotype_id => "phenotype_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9ZWz9yxNrHkucakmBGe9xA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
