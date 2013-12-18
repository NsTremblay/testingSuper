use utf8;
package Database::Chado::Schema::Result::ExpressionImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::ExpressionImage

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<expression_image>

=cut

__PACKAGE__->table("expression_image");

=head1 ACCESSORS

=head2 expression_image_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'expression_image_expression_image_id_seq'

=head2 expression_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 eimage_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "expression_image_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "expression_image_expression_image_id_seq",
  },
  "expression_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "eimage_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</expression_image_id>

=back

=cut

__PACKAGE__->set_primary_key("expression_image_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<expression_image_c1>

=over 4

=item * L</expression_id>

=item * L</eimage_id>

=back

=cut

__PACKAGE__->add_unique_constraint("expression_image_c1", ["expression_id", "eimage_id"]);

=head1 RELATIONS

=head2 eimage

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Eimage>

=cut

__PACKAGE__->belongs_to(
  "eimage",
  "Database::Chado::Schema::Result::Eimage",
  { eimage_id => "eimage_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 expression

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Expression>

=cut

__PACKAGE__->belongs_to(
  "expression",
  "Database::Chado::Schema::Result::Expression",
  { expression_id => "expression_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RhzNcVhs4L15/KfyKWQqVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
