use utf8;
package Database::Chado::Schema::Result::CellLineFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::CellLineFeature

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cell_line_feature>

=cut

__PACKAGE__->table("cell_line_feature");

=head1 ACCESSORS

=head2 cell_line_feature_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_feature_cell_line_feature_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_line_feature_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_feature_cell_line_feature_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cell_line_feature_id>

=back

=cut

__PACKAGE__->set_primary_key("cell_line_feature_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cell_line_feature_c1>

=over 4

=item * L</cell_line_id>

=item * L</feature_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "cell_line_feature_c1",
  ["cell_line_id", "feature_id", "pub_id"],
);

=head1 RELATIONS

=head2 cell_line

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::CellLine>

=cut

__PACKAGE__->belongs_to(
  "cell_line",
  "Database::Chado::Schema::Result::CellLine",
  { cell_line_id => "cell_line_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fpzR0Vozq3uKt16rZEWK/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
