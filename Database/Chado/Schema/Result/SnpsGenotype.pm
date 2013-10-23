use utf8;
package Database::Chado::Schema::Result::SnpsGenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::SnpsGenotype - Presence absence values for each snp for each strain

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snps_genotypes>

=cut

__PACKAGE__->table("snps_genotypes");

=head1 ACCESSORS

=head2 snp_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'snps_genotypes_snp_genotype_id_seq'

=head2 genome_id

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 snp_a

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Presence absence value for base "A" for each locus for each strain. Default is 0.

=head2 snp_t

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Presence absence value for base "T" for each locus for each strain. Default is 0.

=head2 snp_c

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Presence absence value for base "C" for each locus for each strain. Default is 0.

=head2 snp_g

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Presence absence value for base "G" for each locus for each strain. Default is 0.

=cut

__PACKAGE__->add_columns(
  "snp_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "snps_genotypes_snp_genotype_id_seq",
  },
  "genome_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "snp_a",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "snp_t",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "snp_c",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "snp_g",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</snp_genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("snp_genotype_id");

=head1 RELATIONS

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-10-23 15:36:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ynD1t66g7ltNAsH5CP7S6A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
