use utf8;
package Database::Chado::TestSchema::Result::LibraryCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::LibraryCvterm

=head1 DESCRIPTION

The table library_cvterm links a library to controlled vocabularies which describe the library.  For instance, there might be a link to the anatomy cv for "head" or "testes" for a head or testes library.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<library_cvterm>

=cut

__PACKAGE__->table("library_cvterm");

=head1 ACCESSORS

=head2 library_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_cvterm_library_cvterm_id_seq'

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "library_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_cvterm_library_cvterm_id_seq",
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</library_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("library_cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<library_cvterm_c1>

=over 4

=item * L</library_id>

=item * L</cvterm_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint("library_cvterm_c1", ["library_id", "cvterm_id", "pub_id"]);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::TestSchema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 library

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Database::Chado::TestSchema::Result::Library",
  { library_id => "library_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::TestSchema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PkmwnJBIHMR+MJW+32YfFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
