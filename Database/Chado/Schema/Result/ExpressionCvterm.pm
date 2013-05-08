use utf8;
package Database::Chado::Schema::Result::ExpressionCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::ExpressionCvterm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<expression_cvterm>

=cut

__PACKAGE__->table("expression_cvterm");

=head1 ACCESSORS

=head2 expression_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'expression_cvterm_expression_cvterm_id_seq'

=head2 expression_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 cvterm_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "expression_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "expression_cvterm_expression_cvterm_id_seq",
  },
  "expression_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "cvterm_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</expression_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("expression_cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<expression_cvterm_c1>

=over 4

=item * L</expression_id>

=item * L</cvterm_id>

=item * L</cvterm_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "expression_cvterm_c1",
  ["expression_id", "cvterm_id", "cvterm_type_id"],
);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 cvterm_type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm_type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "cvterm_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 expression

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Expression>

=cut

__PACKAGE__->belongs_to(
  "expression",
  "Database::Chado::Schema::Result::Expression",
  { expression_id => "expression_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 expression_cvtermprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionCvtermprop>

=cut

__PACKAGE__->has_many(
  "expression_cvtermprops",
  "Database::Chado::Schema::Result::ExpressionCvtermprop",
  { "foreign.expression_cvterm_id" => "self.expression_cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 17:37:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5DZS+l1BWpN+1g0eB/Ar1Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
