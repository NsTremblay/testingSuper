use utf8;
package Database::Chado::Schema::Result::BiomaterialTreatment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::BiomaterialTreatment

=head1 DESCRIPTION

Link biomaterials to treatments. Treatments have an order of operations (rank), and associated measurements (unittype_id, value).

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<biomaterial_treatment>

=cut

__PACKAGE__->table("biomaterial_treatment");

=head1 ACCESSORS

=head2 biomaterial_treatment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterial_treatment_biomaterial_treatment_id_seq'

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 treatment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unittype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'real'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "biomaterial_treatment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterial_treatment_biomaterial_treatment_id_seq",
  },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "treatment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unittype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "real", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</biomaterial_treatment_id>

=back

=cut

__PACKAGE__->set_primary_key("biomaterial_treatment_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<biomaterial_treatment_c1>

=over 4

=item * L</biomaterial_id>

=item * L</treatment_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "biomaterial_treatment_c1",
  ["biomaterial_id", "treatment_id"],
);

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

=head2 treatment

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Treatment>

=cut

__PACKAGE__->belongs_to(
  "treatment",
  "Database::Chado::Schema::Result::Treatment",
  { treatment_id => "treatment_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 unittype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "unittype",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "unittype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pIu+WU7S7I3f+xdqVTx/Pg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
