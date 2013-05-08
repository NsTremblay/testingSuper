use utf8;
package Database::Chado::Schema::Result::Arraydesign;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Arraydesign

=head1 DESCRIPTION

General properties about an array.
An array is a template used to generate physical slides, etc.  It
contains layout information, as well as global array properties, such
as material (glass, nylon) and spot dimensions (in rows/columns).

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<arraydesign>

=cut

__PACKAGE__->table("arraydesign");

=head1 ACCESSORS

=head2 arraydesign_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'arraydesign_arraydesign_id_seq'

=head2 manufacturer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 platformtype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 substratetype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 array_dimensions

  data_type: 'text'
  is_nullable: 1

=head2 element_dimensions

  data_type: 'text'
  is_nullable: 1

=head2 num_of_elements

  data_type: 'integer'
  is_nullable: 1

=head2 num_array_columns

  data_type: 'integer'
  is_nullable: 1

=head2 num_array_rows

  data_type: 'integer'
  is_nullable: 1

=head2 num_grid_columns

  data_type: 'integer'
  is_nullable: 1

=head2 num_grid_rows

  data_type: 'integer'
  is_nullable: 1

=head2 num_sub_columns

  data_type: 'integer'
  is_nullable: 1

=head2 num_sub_rows

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "arraydesign_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "arraydesign_arraydesign_id_seq",
  },
  "manufacturer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "platformtype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "substratetype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "array_dimensions",
  { data_type => "text", is_nullable => 1 },
  "element_dimensions",
  { data_type => "text", is_nullable => 1 },
  "num_of_elements",
  { data_type => "integer", is_nullable => 1 },
  "num_array_columns",
  { data_type => "integer", is_nullable => 1 },
  "num_array_rows",
  { data_type => "integer", is_nullable => 1 },
  "num_grid_columns",
  { data_type => "integer", is_nullable => 1 },
  "num_grid_rows",
  { data_type => "integer", is_nullable => 1 },
  "num_sub_columns",
  { data_type => "integer", is_nullable => 1 },
  "num_sub_rows",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</arraydesign_id>

=back

=cut

__PACKAGE__->set_primary_key("arraydesign_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<arraydesign_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("arraydesign_c1", ["name"]);

=head1 RELATIONS

=head2 arraydesignprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Arraydesignprop>

=cut

__PACKAGE__->has_many(
  "arraydesignprops",
  "Database::Chado::Schema::Result::Arraydesignprop",
  { "foreign.arraydesign_id" => "self.arraydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assays

Type: has_many

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->has_many(
  "assays",
  "Database::Chado::Schema::Result::Assay",
  { "foreign.arraydesign_id" => "self.arraydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 elements

Type: has_many

Related object: L<Database::Chado::Schema::Result::Element>

=cut

__PACKAGE__->has_many(
  "elements",
  "Database::Chado::Schema::Result::Element",
  { "foreign.arraydesign_id" => "self.arraydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 manufacturer

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "manufacturer",
  "Database::Chado::Schema::Result::Contact",
  { contact_id => "manufacturer_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 platformtype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "platformtype",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "platformtype_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 protocol

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Database::Chado::Schema::Result::Protocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 substratetype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "substratetype",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "substratetype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3cnwft6wSJxeLAWI7KKOmg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
