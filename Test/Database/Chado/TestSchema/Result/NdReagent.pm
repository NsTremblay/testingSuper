use utf8;
package Database::Chado::TestSchema::Result::NdReagent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::NdReagent

=head1 DESCRIPTION

A reagent such as a primer, an enzyme, an adapter oligo, a linker oligo. Reagents are used in genotyping experiments, or in any other kind of experiment.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_reagent>

=cut

__PACKAGE__->table("nd_reagent");

=head1 ACCESSORS

=head2 nd_reagent_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_reagent_nd_reagent_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 80

The name of the reagent. The name should be unique for a given type.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type of the reagent, for example linker oligomer, or forward primer.

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

If the reagent is a primer, the feature that it corresponds to. More generally, the corresponding feature for any reagent that has a sequence that maps to another sequence.

=cut

__PACKAGE__->add_columns(
  "nd_reagent_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_reagent_nd_reagent_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_reagent_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_reagent_id");

=head1 RELATIONS

=head2 nd_protocol_reagents

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdProtocolReagent>

=cut

__PACKAGE__->has_many(
  "nd_protocol_reagents",
  "Database::Chado::TestSchema::Result::NdProtocolReagent",
  { "foreign.reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationship_object_reagents

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationship_object_reagents",
  "Database::Chado::TestSchema::Result::NdReagentRelationship",
  { "foreign.object_reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationship_subject_reagents

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationship_subject_reagents",
  "Database::Chado::TestSchema::Result::NdReagentRelationship",
  { "foreign.subject_reagent_id" => "self.nd_reagent_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagentprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::NdReagentprop>

=cut

__PACKAGE__->has_many(
  "nd_reagentprops",
  "Database::Chado::TestSchema::Result::NdReagentprop",
  { "foreign.nd_reagent_id" => "self.nd_reagent_id" },
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
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GVx6EMom2pVDve6cDuJU7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
