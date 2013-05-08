use utf8;
package Database::Chado::Schema::Result::ContactRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::ContactRelationship - Model relationships between contacts

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<contact_relationship>

=cut

__PACKAGE__->table("contact_relationship");

=head1 ACCESSORS

=head2 contact_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'contact_relationship_contact_relationship_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node.

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node.

=cut

__PACKAGE__->add_columns(
  "contact_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "contact_relationship_contact_relationship_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contact_relationship_id>

=back

=cut

__PACKAGE__->set_primary_key("contact_relationship_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<contact_relationship_c1>

=over 4

=item * L</subject_id>

=item * L</object_id>

=item * L</type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "contact_relationship_c1",
  ["subject_id", "object_id", "type_id"],
);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Database::Chado::Schema::Result::Contact",
  { contact_id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 subject

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Database::Chado::Schema::Result::Contact",
  { contact_id => "subject_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E1vC2ndE2mGH6j4X1ZMYXg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
