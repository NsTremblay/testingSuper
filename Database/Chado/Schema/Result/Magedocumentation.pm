use utf8;
package Database::Chado::Schema::Result::Magedocumentation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Magedocumentation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<magedocumentation>

=cut

__PACKAGE__->table("magedocumentation");

=head1 ACCESSORS

=head2 magedocumentation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'magedocumentation_magedocumentation_id_seq'

=head2 mageml_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tableinfo_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 row_id

  data_type: 'integer'
  is_nullable: 0

=head2 mageidentifier

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "magedocumentation_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "magedocumentation_magedocumentation_id_seq",
  },
  "mageml_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tableinfo_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "row_id",
  { data_type => "integer", is_nullable => 0 },
  "mageidentifier",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</magedocumentation_id>

=back

=cut

__PACKAGE__->set_primary_key("magedocumentation_id");

=head1 RELATIONS

=head2 mageml

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Mageml>

=cut

__PACKAGE__->belongs_to(
  "mageml",
  "Database::Chado::Schema::Result::Mageml",
  { mageml_id => "mageml_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 tableinfo

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Tableinfo>

=cut

__PACKAGE__->belongs_to(
  "tableinfo",
  "Database::Chado::Schema::Result::Tableinfo",
  { tableinfo_id => "tableinfo_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FNU2/7/ebP0ZUaw5KZXPzA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
