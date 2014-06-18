use utf8;
package Database::Chado::Schema::Result::Phenstatement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Phenstatement

=head1 DESCRIPTION

Phenotypes are things like "larval lethal".  Phenstatements are things like "dpp-1 is recessive larval lethal". So essentially phenstatement is a linking table expressing the relationship between genotype, environment, and phenotype.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenstatement>

=cut

__PACKAGE__->table("phenstatement");

=head1 ACCESSORS

=head2 phenstatement_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenstatement_phenstatement_id_seq'

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 environment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenstatement_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenstatement_phenstatement_id_seq",
  },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "environment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phenstatement_id>

=back

=cut

__PACKAGE__->set_primary_key("phenstatement_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<phenstatement_c1>

=over 4

=item * L</genotype_id>

=item * L</phenotype_id>

=item * L</environment_id>

=item * L</type_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "phenstatement_c1",
  [
    "genotype_id",
    "phenotype_id",
    "environment_id",
    "type_id",
    "pub_id",
  ],
);

=head1 RELATIONS

=head2 environment

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment",
  "Database::Chado::Schema::Result::Environment",
  { environment_id => "environment_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 genotype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype",
  "Database::Chado::Schema::Result::Genotype",
  { genotype_id => "genotype_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 phenotype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->belongs_to(
  "phenotype",
  "Database::Chado::Schema::Result::Phenotype",
  { phenotype_id => "phenotype_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A9tlLn/uJaLxR/DqUD2LSw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
