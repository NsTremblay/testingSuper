use utf8;
package Database::Chado::Schema::Result::CellLineprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::CellLineprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cell_lineprop>

=cut

__PACKAGE__->table("cell_lineprop");

=head1 ACCESSORS

=head2 cell_lineprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_lineprop_cell_lineprop_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_lineprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_lineprop_cell_lineprop_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cell_lineprop_id>

=back

=cut

__PACKAGE__->set_primary_key("cell_lineprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cell_lineprop_c1>

=over 4

=item * L</cell_line_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("cell_lineprop_c1", ["cell_line_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 cell_line

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::CellLine>

=cut

__PACKAGE__->belongs_to(
  "cell_line",
  "Database::Chado::Schema::Result::CellLine",
  { cell_line_id => "cell_line_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 cell_lineprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLinepropPub>

=cut

__PACKAGE__->has_many(
  "cell_lineprop_pubs",
  "Database::Chado::Schema::Result::CellLinepropPub",
  { "foreign.cell_lineprop_id" => "self.cell_lineprop_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H36XZtc/ms9X1u6Yu2lsfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
