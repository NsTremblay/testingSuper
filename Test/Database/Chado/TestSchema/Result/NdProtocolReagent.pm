use utf8;
package Database::Chado::TestSchema::Result::NdProtocolReagent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::NdProtocolReagent

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_protocol_reagent>

=cut

__PACKAGE__->table("nd_protocol_reagent");

=head1 ACCESSORS

=head2 nd_protocol_reagent_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_protocol_reagent_nd_protocol_reagent_id_seq'

=head2 nd_protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 reagent_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_protocol_reagent_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_protocol_reagent_nd_protocol_reagent_id_seq",
  },
  "nd_protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "reagent_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_protocol_reagent_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_protocol_reagent_id");

=head1 RELATIONS

=head2 nd_protocol

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::NdProtocol>

=cut

__PACKAGE__->belongs_to(
  "nd_protocol",
  "Database::Chado::TestSchema::Result::NdProtocol",
  { nd_protocol_id => "nd_protocol_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 reagent

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::NdReagent>

=cut

__PACKAGE__->belongs_to(
  "reagent",
  "Database::Chado::TestSchema::Result::NdReagent",
  { nd_reagent_id => "reagent_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:haZZJHU5q4bUImt/UHrgZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
