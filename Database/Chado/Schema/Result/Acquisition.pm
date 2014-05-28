use utf8;
package Database::Chado::Schema::Result::Acquisition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Acquisition

=head1 DESCRIPTION

This represents the scanning of hybridized material. The output of this process is typically a digital image of an array.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<acquisition>

=cut

__PACKAGE__->table("acquisition");

=head1 ACCESSORS

=head2 acquisition_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'acquisition_acquisition_id_seq'

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 channel_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 acquisitiondate

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "acquisition_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "acquisition_acquisition_id_seq",
  },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "channel_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "acquisitiondate",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</acquisition_id>

=back

=cut

__PACKAGE__->set_primary_key("acquisition_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<acquisition_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("acquisition_c1", ["name"]);

=head1 RELATIONS

=head2 acquisition_relationship_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::AcquisitionRelationship>

=cut

__PACKAGE__->has_many(
  "acquisition_relationship_objects",
  "Database::Chado::Schema::Result::AcquisitionRelationship",
  { "foreign.object_id" => "self.acquisition_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 acquisition_relationship_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::AcquisitionRelationship>

=cut

__PACKAGE__->has_many(
  "acquisition_relationship_subjects",
  "Database::Chado::Schema::Result::AcquisitionRelationship",
  { "foreign.subject_id" => "self.acquisition_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 acquisitionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Acquisitionprop>

=cut

__PACKAGE__->has_many(
  "acquisitionprops",
  "Database::Chado::Schema::Result::Acquisitionprop",
  { "foreign.acquisition_id" => "self.acquisition_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Database::Chado::Schema::Result::Assay",
  { assay_id => "assay_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 channel

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Channel>

=cut

__PACKAGE__->belongs_to(
  "channel",
  "Database::Chado::Schema::Result::Channel",
  { channel_id => "channel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
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

=head2 quantifications

Type: has_many

Related object: L<Database::Chado::Schema::Result::Quantification>

=cut

__PACKAGE__->has_many(
  "quantifications",
  "Database::Chado::Schema::Result::Quantification",
  { "foreign.acquisition_id" => "self.acquisition_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:s530GDhGJPUieee838hhqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
