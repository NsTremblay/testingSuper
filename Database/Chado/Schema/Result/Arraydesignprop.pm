use utf8;
package Database::Chado::Schema::Result::Arraydesignprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Arraydesignprop

=head1 DESCRIPTION

Extra array design properties that are not accounted for in arraydesign.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<arraydesignprop>

=cut

__PACKAGE__->table("arraydesignprop");

=head1 ACCESSORS

=head2 arraydesignprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'arraydesignprop_arraydesignprop_id_seq'

=head2 arraydesign_id

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
  "arraydesignprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "arraydesignprop_arraydesignprop_id_seq",
  },
  "arraydesign_id",
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

=item * L</arraydesignprop_id>

=back

=cut

__PACKAGE__->set_primary_key("arraydesignprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<arraydesignprop_c1>

=over 4

=item * L</arraydesign_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("arraydesignprop_c1", ["arraydesign_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 arraydesign

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Arraydesign>

=cut

__PACKAGE__->belongs_to(
  "arraydesign",
  "Database::Chado::Schema::Result::Arraydesign",
  { arraydesign_id => "arraydesign_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xbGzas6y/P5S9YsJI/slkQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
