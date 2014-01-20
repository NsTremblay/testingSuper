use utf8;
package Database::Chado::Schema::Result::SnpAlignment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::SnpAlignment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<snp_alignment>

=cut

__PACKAGE__->table("snp_alignment");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 block

  data_type: 'integer'
  is_nullable: 1

=head2 current_position

  data_type: 'integer'
  is_nullable: 1

=head2 alignment

  data_type: 'varchar'
  is_nullable: 1
  size: 10000

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "block",
  { data_type => "integer", is_nullable => 1 },
  "current_position",
  { data_type => "integer", is_nullable => 1 },
  "alignment",
  { data_type => "varchar", is_nullable => 1, size => 10000 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<snp_alignment_c1>

=over 4

=item * L</name>

=item * L</block>

=back

=cut

__PACKAGE__->add_unique_constraint("snp_alignment_c1", ["name", "block"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-01-01 14:20:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DeX2XsFP4g9W3Ic0N0cvPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
