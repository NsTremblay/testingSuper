use utf8;
package Database::Chado::Schema::Result::Genotypeprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Genotypeprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<genotypeprop>

=cut

__PACKAGE__->table("genotypeprop");

=head1 ACCESSORS

=head2 genotypeprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotypeprop_genotypeprop_id_seq'

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "genotypeprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotypeprop_genotypeprop_id_seq",
  },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</genotypeprop_id>

=back

=cut

__PACKAGE__->set_primary_key("genotypeprop_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<genotypeprop_c1>

=over 4

=item * L</genotype_id>

=item * L</type_id>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("genotypeprop_c1", ["genotype_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 genotype

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype",
  "Database::Chado::Schema::Result::Genotype",
  { genotype_id => "genotype_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ogdZKhMAV+4KEvJHGC32vw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
