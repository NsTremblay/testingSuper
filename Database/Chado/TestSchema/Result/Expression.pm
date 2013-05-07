use utf8;
package Database::Chado::TestSchema::Result::Expression;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Expression - The expression table is essentially a bridge table.

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

Related object: L<Database::Chado::TestSchema::Result::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterms",
  "Database::Chado::TestSchema::Result::ExpressionCvterm",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_images

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ExpressionImage>

=cut

__PACKAGE__->has_many(
  "expression_images",
  "Database::Chado::TestSchema::Result::ExpressionImage",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_pubs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::ExpressionPub>

=cut

__PACKAGE__->has_many(
  "expression_pubs",
  "Database::Chado::TestSchema::Result::ExpressionPub",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expressionprops

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Expressionprop>

=cut

__PACKAGE__->has_many(
  "expressionprops",
  "Database::Chado::TestSchema::Result::Expressionprop",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressions

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::FeatureExpression>

=cut

__PACKAGE__->has_many(
  "feature_expressions",
  "Database::Chado::TestSchema::Result::FeatureExpression",
  { "foreign.expression_id" => "self.expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JARpPgjRdWmA6EcwLTm+Wg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
