use utf8;
package Database::Chado::Schema::Result::Tableinfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Tableinfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tableinfo>

=cut

__PACKAGE__->table("tableinfo");

=head1 ACCESSORS

=head2 tableinfo_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tableinfo_tableinfo_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 primary_key_column

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 is_view

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 view_on_table_id

  data_type: 'integer'
  is_nullable: 1

=head2 superclass_table_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_updateable

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 modification_date

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "tableinfo_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tableinfo_tableinfo_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "primary_key_column",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "is_view",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "view_on_table_id",
  { data_type => "integer", is_nullable => 1 },
  "superclass_table_id",
  { data_type => "integer", is_nullable => 1 },
  "is_updateable",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "modification_date",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</tableinfo_id>

=back

=cut

__PACKAGE__->set_primary_key("tableinfo_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tableinfo_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("tableinfo_c1", ["name"]);

=head1 RELATIONS

=head2 controls

Type: has_many

Related object: L<Database::Chado::Schema::Result::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Database::Chado::Schema::Result::Control",
  { "foreign.tableinfo_id" => "self.tableinfo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 magedocumentations

Type: has_many

Related object: L<Database::Chado::Schema::Result::Magedocumentation>

=cut

__PACKAGE__->has_many(
  "magedocumentations",
  "Database::Chado::Schema::Result::Magedocumentation",
  { "foreign.tableinfo_id" => "self.tableinfo_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a54QXUHfiyfuw0izT2JjYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
