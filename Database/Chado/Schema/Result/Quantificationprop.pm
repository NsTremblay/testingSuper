use utf8;
package Database::Chado::Schema::Result::Quantificationprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Quantificationprop

=head1 DESCRIPTION

Extra quantification properties that are not accounted for in quantification.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<quantificationprop>

=cut

__PACKAGE__->table("quantificationprop");

=head1 ACCESSORS

=head2 quantificationprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'quantificationprop_quantificationprop_id_seq'

=head2 quantification_id

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
  "quantificationprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "quantificationprop_quantificationprop_id_seq",
  },
  "quantification_id",
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

=item * L</quantificationprop_id>

=back

=cut

__PACKAGE__->set_primary_key("quantificationprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<quantificationprop_c1>

=over 4

=item * L</quantification_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "quantificationprop_c1",
  ["quantification_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 quantification

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Quantification>

=cut

__PACKAGE__->belongs_to(
  "quantification",
  "Database::Chado::Schema::Result::Quantification",
  { quantification_id => "quantification_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ymam87aG+U44sgcHDhteLQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
