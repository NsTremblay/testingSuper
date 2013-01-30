use utf8;
package Database::Chado::TestSchema::Result::Libraryprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Libraryprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<libraryprop>

=cut

__PACKAGE__->table("libraryprop");

=head1 ACCESSORS

=head2 libraryprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'libraryprop_libraryprop_id_seq'

=head2 library_id

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
  "libraryprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "libraryprop_libraryprop_id_seq",
  },
  "library_id",
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

=item * L</libraryprop_id>

=back

=cut

__PACKAGE__->set_primary_key("libraryprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<libraryprop_c1>

=over 4

=item * L</library_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("libraryprop_c1", ["library_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 library

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Database::Chado::TestSchema::Result::Library",
  { library_id => "library_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 libraryprop_pubs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::LibrarypropPub>

=cut

__PACKAGE__->has_many(
  "libraryprop_pubs",
  "Database::Chado::TestSchema::Result::LibrarypropPub",
  { "foreign.libraryprop_id" => "self.libraryprop_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:isY5tpHe8ZLtX6r7dmRwPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
