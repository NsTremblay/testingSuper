use utf8;
package Database::Chado::Schema::Result::Snp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Snp

=head1 DESCRIPTION

Stores the names and, in the future, other info (accession, location, other properties) of snps used to compare groups of strains.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snps>

=cut

__PACKAGE__->table("snps");

=head1 ACCESSORS

=head2 snp_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'snps_snp_id_seq'

Serial ID generated for each snp

=head2 snp_name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

Snp name (can contain both char and int)

=cut

__PACKAGE__->add_columns(
  "snp_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "snps_snp_id_seq",
  },
  "snp_name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</snp_id>

=back

=cut

__PACKAGE__->set_primary_key("snp_id");

=head1 RELATIONS

=head2 snps_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::SnpsGenotype>

=cut

__PACKAGE__->has_many(
  "snps_genotypes",
  "Database::Chado::Schema::Result::SnpsGenotype",
  { "foreign.snp_id" => "self.snp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-21 11:51:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SX1/xvV+SjMuS1EMFf3GWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
