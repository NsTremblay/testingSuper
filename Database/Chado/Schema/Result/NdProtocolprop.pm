use utf8;
package Database::Chado::Schema::Result::NdProtocolprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::NdProtocolprop - Property/value associations for protocol.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_protocolprop>

=cut

__PACKAGE__->table("nd_protocolprop");

=head1 ACCESSORS

=head2 nd_protocolprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_protocolprop_nd_protocolprop_id_seq'

=head2 nd_protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The protocol to which the property applies.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the property as a reference to a controlled vocabulary term.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the property.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

The rank of the property value, if the property has an array of values.

=cut

__PACKAGE__->add_columns(
  "nd_protocolprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_protocolprop_nd_protocolprop_id_seq",
  },
  "nd_protocol_id",
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

=item * L</nd_protocolprop_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_protocolprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<nd_protocolprop_c1>

=over 4

=item * L</nd_protocol_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("nd_protocolprop_c1", ["nd_protocol_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 nd_protocol

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::NdProtocol>

=cut

__PACKAGE__->belongs_to(
  "nd_protocol",
  "Database::Chado::Schema::Result::NdProtocol",
  { nd_protocol_id => "nd_protocol_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QMoQzOUZHVrjYHB6vfmZ2g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
