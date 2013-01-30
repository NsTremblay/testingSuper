use utf8;
package Database::Chado::TestSchema::Result::Protocolparam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Protocolparam

=head1 DESCRIPTION

Parameters related to a
protocol. For example, if the protocol is a soak, this might include attributes of bath temperature and duration.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<protocolparam>

=cut

__PACKAGE__->table("protocolparam");

=head1 ACCESSORS

=head2 protocolparam_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'protocolparam_protocolparam_id_seq'

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 datatype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 unittype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "protocolparam_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "protocolparam_protocolparam_id_seq",
  },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "datatype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "unittype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</protocolparam_id>

=back

=cut

__PACKAGE__->set_primary_key("protocolparam_id");

=head1 RELATIONS

=head2 datatype

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "datatype",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "datatype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 protocol

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Database::Chado::TestSchema::Result::Protocol",
  { protocol_id => "protocol_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 unittype

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "unittype",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "unittype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gM+PFWlywxZCN56tR/Xvpg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
