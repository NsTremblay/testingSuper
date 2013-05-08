use utf8;
package Database::Chado::Schema::Result::Expression;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Expression - The expression table is essentially a bridge table.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<expression>

=cut

__PACKAGE__->table("expression");

=head1 ACCESSORS

=head2 expression_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'expression_expression_id_seq'

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 md5checksum

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "expression_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "expression_expression_id_seq",
  },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "md5checksum",
  { data_type => "char", is_nullable => 1, size => 32 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</expression_id>

=back

=cut

__PACKAGE__->set_primary_key("expression_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<expression_c1>

=over 4

=item * L</uniquename>

=back

=cut

__PACKAGE__->add_unique_constraint("expression_c1", ["uniquename"]);

=head1 RELATIONS

=head2 expression_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterms",
  "Database::Chado::Schema::Result::ExpressionCvterm",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_images

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionImage>

=cut

__PACKAGE__->has_many(
  "expression_images",
  "Database::Chado::Schema::Result::ExpressionImage",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionPub>

=cut

__PACKAGE__->has_many(
  "expression_pubs",
  "Database::Chado::Schema::Result::ExpressionPub",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expressionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Expressionprop>

=cut

__PACKAGE__->has_many(
  "expressionprops",
  "Database::Chado::Schema::Result::Expressionprop",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressions

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureExpression>

=cut

__PACKAGE__->has_many(
  "feature_expressions",
  "Database::Chado::Schema::Result::FeatureExpression",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-06 10:20:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HldUW6Lxaxqqk7+OcUl3kg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
