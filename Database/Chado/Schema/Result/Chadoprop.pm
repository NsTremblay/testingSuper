use utf8;
package Database::Chado::Schema::Result::Chadoprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Chadoprop

=head1 DESCRIPTION

This table is different from other prop tables in the database, as it is for storing information about the database itself, like schema version

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<chadoprop>

=cut

__PACKAGE__->table("chadoprop");

=head1 ACCESSORS

=head2 chadoprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'chadoprop_chadoprop_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the property or slot is a cvterm. The meaning of the property is defined in that cvterm.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the property, represented as text. Numeric values are converted to their text representation.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Property-Value ordering. Any
cv can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used.

=cut

__PACKAGE__->add_columns(
  "chadoprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chadoprop_chadoprop_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</chadoprop_id>

=back

=cut

__PACKAGE__->set_primary_key("chadoprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<chadoprop_c1>

=over 4

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("chadoprop_c1", ["type_id", "rank"]);

=head1 RELATIONS

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fLxPim3zUt+wI9nG4DvjVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
