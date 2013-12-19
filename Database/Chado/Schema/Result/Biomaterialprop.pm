use utf8;
package Database::Chado::Schema::Result::Biomaterialprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Biomaterialprop

=head1 DESCRIPTION

Extra biomaterial properties that are not accounted for in biomaterial.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<biomaterialprop>

=cut

__PACKAGE__->table("biomaterialprop");

=head1 ACCESSORS

=head2 biomaterialprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterialprop_biomaterialprop_id_seq'

=head2 biomaterial_id

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
  "biomaterialprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterialprop_biomaterialprop_id_seq",
  },
  "biomaterial_id",
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

=item * L</biomaterialprop_id>

=back

=cut

__PACKAGE__->set_primary_key("biomaterialprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<biomaterialprop_c1>

=over 4

=item * L</biomaterial_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("biomaterialprop_c1", ["biomaterial_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 biomaterial

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "biomaterial",
  "Database::Chado::Schema::Result::Biomaterial",
  { biomaterial_id => "biomaterial_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U9J5c2j1YdISSa5KrojSAg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
