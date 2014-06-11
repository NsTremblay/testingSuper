use utf8;
package Database::Chado::Schema::Result::EnvironmentCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::EnvironmentCvterm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<environment_cvterm>

=cut

__PACKAGE__->table("environment_cvterm");

=head1 ACCESSORS

=head2 environment_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'environment_cvterm_environment_cvterm_id_seq'

=head2 environment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "environment_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "environment_cvterm_environment_cvterm_id_seq",
  },
  "environment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</environment_cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("environment_cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<environment_cvterm_c1>

=over 4

=item * L</environment_id>

=item * L</cvterm_id>

=back

=cut

__PACKAGE__->add_unique_constraint("environment_cvterm_c1", ["environment_id", "cvterm_id"]);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "cvterm_id" },
  { is_deferrable => 0, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fJBlHkUThT9cxnYeBCdV6g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
