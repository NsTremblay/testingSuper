use utf8;
package Database::Chado::TestSchema::Result::Protocol;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Protocol - Procedural notes on how data was prepared and processed.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<protocol>

=cut

__PACKAGE__->table("protocol");

=head1 ACCESSORS

=head2 protocol_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'protocol_protocol_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 uri

  data_type: 'text'
  is_nullable: 1

=head2 protocoldescription

  data_type: 'text'
  is_nullable: 1

=head2 hardwaredescription

  data_type: 'text'
  is_nullable: 1

=head2 softwaredescription

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protocol_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "protocol_protocol_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "uri",
  { data_type => "text", is_nullable => 1 },
  "protocoldescription",
  { data_type => "text", is_nullable => 1 },
  "hardwaredescription",
  { data_type => "text", is_nullable => 1 },
  "softwaredescription",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</protocol_id>

=back

=cut

__PACKAGE__->set_primary_key("protocol_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<protocol_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("protocol_c1", ["name"]);

=head1 RELATIONS

=head2 acquisitions

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Acquisition>

=cut

__PACKAGE__->has_many(
  "acquisitions",
  "Database::Chado::TestSchema::Result::Acquisition",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesigns

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesigns",
  "Database::Chado::TestSchema::Result::Arraydesign",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assays

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Assay>

=cut

__PACKAGE__->has_many(
  "assays",
  "Database::Chado::TestSchema::Result::Assay",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::TestSchema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 protocolparams

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Protocolparam>

=cut

__PACKAGE__->has_many(
  "protocolparams",
  "Database::Chado::TestSchema::Result::Protocolparam",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::TestSchema::Result::Pub",
  { pub_id => "pub_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 quantifications

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Quantification>

=cut

__PACKAGE__->has_many(
  "quantifications",
  "Database::Chado::TestSchema::Result::Quantification",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 treatments

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Treatment>

=cut

__PACKAGE__->has_many(
  "treatments",
  "Database::Chado::TestSchema::Result::Treatment",
  { "foreign.protocol_id" => "self.protocol_id" },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xatJEqa0E+b7mrRE9iYF3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
