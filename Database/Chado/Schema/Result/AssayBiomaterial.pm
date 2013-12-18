use utf8;
package Database::Chado::Schema::Result::AssayBiomaterial;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::AssayBiomaterial

=head1 DESCRIPTION

A biomaterial can be hybridized many times (technical replicates), or combined with other biomaterials in a single hybridization (for two-channel arrays).

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<assay_biomaterial>

=cut

__PACKAGE__->table("assay_biomaterial");

=head1 ACCESSORS

=head2 assay_biomaterial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'assay_biomaterial_assay_biomaterial_id_seq'

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 channel_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "assay_biomaterial_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "assay_biomaterial_assay_biomaterial_id_seq",
  },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "channel_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</assay_biomaterial_id>

=back

=cut

__PACKAGE__->set_primary_key("assay_biomaterial_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<assay_biomaterial_c1>

=over 4

=item * L</assay_id>

=item * L</biomaterial_id>

=item * L</channel_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "assay_biomaterial_c1",
  ["assay_id", "biomaterial_id", "channel_id", "rank"],
);

=head1 RELATIONS

=head2 assay

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Database::Chado::Schema::Result::Assay",
  { assay_id => "assay_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 biomaterial

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "biomaterial",
  "Database::Chado::Schema::Result::Biomaterial",
  { biomaterial_id => "biomaterial_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 channel

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Channel>

=cut

__PACKAGE__->belongs_to(
  "channel",
  "Database::Chado::Schema::Result::Channel",
  { channel_id => "channel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZNlVeES1j6o+bGxb3OGR+A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
