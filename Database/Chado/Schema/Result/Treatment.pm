use utf8;
package Database::Chado::Schema::Result::Treatment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Treatment

=head1 DESCRIPTION

A biomaterial may undergo multiple
treatments. Examples of treatments: apoxia, fluorophore and biotin labeling.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<treatment>

=cut

__PACKAGE__->table("treatment");

=head1 ACCESSORS

=head2 treatment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'treatment_treatment_id_seq'

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "treatment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "treatment_treatment_id_seq",
  },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</treatment_id>

=back

=cut

__PACKAGE__->set_primary_key("treatment_id");

=head1 RELATIONS

=head2 biomaterial

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->belongs_to(
  "biomaterial",
  "Database::Chado::Schema::Result::Biomaterial",
  { biomaterial_id => "biomaterial_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 biomaterial_treatments

Type: has_many

Related object: L<Database::Chado::Schema::Result::BiomaterialTreatment>

=cut

__PACKAGE__->has_many(
  "biomaterial_treatments",
  "Database::Chado::Schema::Result::BiomaterialTreatment",
  { "foreign.treatment_id" => "self.treatment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Protocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "Database::Chado::Schema::Result::Protocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5B6WydviGN+0pwdmDNmLSQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
