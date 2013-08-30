use utf8;
package Database::Chado::Schema::Result::LociGenotype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::LociGenotype - Presence absence values for each locus for each strain 

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<loci_genotypes>

=cut

__PACKAGE__->table("loci_genotypes");

=head1 ACCESSORS

=head2 locus_genotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'loci_genotypes_locus_genotype_id_seq'

=head2 feature_id

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

Strain ID

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Stores a locus ID from the loci table

=head2 locus_genotype

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Presence absence value for each locus for each strain. Will have a value either 0 or 1. Default is 0.

=cut

__PACKAGE__->add_columns(
  "locus_genotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "loci_genotypes_locus_genotype_id_seq",
  },
  "feature_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "locus_genotype",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</locus_genotype_id>

=back

=cut

__PACKAGE__->set_primary_key("locus_genotype_id");

=head1 RELATIONS

=head2 locus

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Loci>

=cut

__PACKAGE__->belongs_to(
  "locus",
  "Database::Chado::Schema::Result::Loci",
  { locus_id => "locus_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-30 11:31:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5Pvp6fIBmf1hJbkgF8F/Gw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
