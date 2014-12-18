use utf8;
package Database::Chado::Schema::Result::PangenomeAlignment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PangenomeAlignment

=head1 DESCRIPTION

The pangenome_alignment table contains both the core and accessory pangenome region aligned prensence/absence strings in column core_alignment and acc_alignment respectively.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pangenome_alignment>

=cut

__PACKAGE__->table("pangenome_alignment");

=head1 ACCESSORS

=head2 pangenome_alignment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pangenome_alignment_pangenome_alignment_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 core_column

  data_type: 'integer'
  is_nullable: 0

=head2 core_alignment

  data_type: 'text'
  is_nullable: 1

=head2 acc_column

  data_type: 'integer'
  is_nullable: 0

=head2 acc_alignment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pangenome_alignment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pangenome_alignment_pangenome_alignment_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "core_column",
  { data_type => "integer", is_nullable => 0 },
  "core_alignment",
  { data_type => "text", is_nullable => 1 },
  "acc_column",
  { data_type => "integer", is_nullable => 0 },
  "acc_alignment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pangenome_alignment_id>

=back

=cut

__PACKAGE__->set_primary_key("pangenome_alignment_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<pangenome_alignment_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("pangenome_alignment_c1", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07041 @ 2014-12-08 08:13:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EV98ixISvHzMI5ipE9Wlhw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
