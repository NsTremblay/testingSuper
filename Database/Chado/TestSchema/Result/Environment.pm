use utf8;
package Database::Chado::TestSchema::Result::Environment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Environment - The environmental component of a phenotype description.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<environment>

=cut

__PACKAGE__->table("environment");

=head1 ACCESSORS

=head2 environment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'environment_environment_id_seq'

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "environment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "environment_environment_id_seq",
  },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</environment_id>

=back

=cut

__PACKAGE__->set_primary_key("environment_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<environment_c1>

=over 4

=item * L</uniquename>

=back

=cut

__PACKAGE__->add_unique_constraint("environment_c1", ["uniquename"]);

=head1 RELATIONS

=head2 environment_cvterms

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::EnvironmentCvterm>

=cut

__PACKAGE__->has_many(
  "environment_cvterms",
  "Database::Chado::TestSchema::Result::EnvironmentCvterm",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Database::Chado::TestSchema::Result::Phendesc",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_environment1s

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_environment1s",
  "Database::Chado::TestSchema::Result::PhenotypeComparison",
  { "foreign.environment1_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_environment2s

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_environment2s",
  "Database::Chado::TestSchema::Result::PhenotypeComparison",
  { "foreign.environment2_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Database::Chado::TestSchema::Result::Phenstatement",
  { "foreign.environment_id" => "self.environment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NPTuFdv8EuT0aGgPpNonbA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
