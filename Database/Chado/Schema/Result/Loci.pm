use utf8;
package Database::Chado::Schema::Result::Loci;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Loci

=head1 DESCRIPTION

Stores the names and, in the future, other info (accession, location, other properties) of loci used to compare groups of strains.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<loci>

=cut

__PACKAGE__->table("loci");

=head1 ACCESSORS

=head2 locus_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'loci_locus_id_seq'

Serial ID (integer) generated for each locus

=head2 locus_name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

Locus name (can contain both char and int)

=head2 locus_function

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "locus_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "loci_locus_id_seq",
  },
  "locus_name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "locus_function",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</locus_id>

=back

=cut

__PACKAGE__->set_primary_key("locus_id");

=head1 RELATIONS

=head2 loci_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::LociGenotype>

=cut

__PACKAGE__->has_many(
  "loci_genotypes",
  "Database::Chado::Schema::Result::LociGenotype",
  { "foreign.locus_id" => "self.locus_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snps_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::SnpsGenotype>

=cut

__PACKAGE__->has_many(
  "snps_genotypes",
  "Database::Chado::Schema::Result::SnpsGenotype",
  { "foreign.snp_id" => "self.locus_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-10-17 09:40:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zQPJ4NjbCzYpiU7HvK924w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
