use utf8;
package Database::Chado::Schema::Result::SnpCore;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::SnpCore

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snp_core>

=cut

__PACKAGE__->table("snp_core");

=head1 ACCESSORS

=head2 snp_core_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'snp_core_snp_core_id_seq'

=head2 pangenome_region

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele

  data_type: 'char'
  default_value: 'n'
  is_nullable: 0
  size: 1

=head2 position

  data_type: 'integer'
  default_value: -1
  is_nullable: 0

=head2 gap_offset

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 aln_block

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 aln_column

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "snp_core_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "snp_core_snp_core_id_seq",
  },
  "pangenome_region",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "allele",
  { data_type => "char", default_value => "n", is_nullable => 0, size => 1 },
  "position",
  { data_type => "integer", default_value => -1, is_nullable => 0 },
  "gap_offset",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "aln_block",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "aln_column",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</snp_core_id>

=back

=cut

__PACKAGE__->set_primary_key("snp_core_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<snp_core_c1>

=over 4

=item * L</pangenome_region>

=item * L</position>

=item * L</gap_offset>

=back

=cut

__PACKAGE__->add_unique_constraint("snp_core_c1", ["pangenome_region", "position", "gap_offset"]);

=head2 C<snp_core_c2>

=over 4

=item * L</aln_block>

=item * L</aln_column>

=back

=cut

__PACKAGE__->add_unique_constraint("snp_core_c2", ["aln_block", "aln_column"]);

=head1 RELATIONS

=head2 pangenome_region

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "pangenome_region",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "pangenome_region" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 private_snp_variations

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateSnpVariation>

=cut

__PACKAGE__->has_many(
  "private_snp_variations",
  "Database::Chado::Schema::Result::PrivateSnpVariation",
  { "foreign.snp" => "self.snp_core_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snp_variations

Type: has_many

Related object: L<Database::Chado::Schema::Result::SnpVariation>

=cut

__PACKAGE__->has_many(
  "snp_variations",
  "Database::Chado::Schema::Result::SnpVariation",
  { "foreign.snp" => "self.snp_core_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-19 22:19:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AsMC/KnwbYesLgRIsazzpg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
