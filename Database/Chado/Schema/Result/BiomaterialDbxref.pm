use utf8;
package Database::Chado::Schema::Result::BiomaterialDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::BiomaterialDbxref

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<biomaterial_dbxref>

=cut

__PACKAGE__->table("biomaterial_dbxref");

=head1 ACCESSORS

=head2 biomaterial_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'biomaterial_dbxref_biomaterial_dbxref_id_seq'

=head2 biomaterial_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "biomaterial_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "biomaterial_dbxref_biomaterial_dbxref_id_seq",
  },
  "biomaterial_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</biomaterial_dbxref_id>

=back

=cut

__PACKAGE__->set_primary_key("biomaterial_dbxref_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<biomaterial_dbxref_c1>

=over 4

=item * L</biomaterial_id>

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->add_unique_constraint("biomaterial_dbxref_c1", ["biomaterial_id", "dbxref_id"]);

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

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zasfqnCaLbzntwh7vr6CqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
