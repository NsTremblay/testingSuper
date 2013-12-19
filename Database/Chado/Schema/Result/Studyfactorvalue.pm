use utf8;
package Database::Chado::Schema::Result::Studyfactorvalue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Studyfactorvalue

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<studyfactorvalue>

=cut

__PACKAGE__->table("studyfactorvalue");

=head1 ACCESSORS

=head2 studyfactorvalue_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studyfactorvalue_studyfactorvalue_id_seq'

=head2 studyfactor_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 factorvalue

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "studyfactorvalue_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studyfactorvalue_studyfactorvalue_id_seq",
  },
  "studyfactor_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "factorvalue",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</studyfactorvalue_id>

=back

=cut

__PACKAGE__->set_primary_key("studyfactorvalue_id");

=head1 RELATIONS

=head2 assay

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Database::Chado::Schema::Result::Assay",
  { assay_id => "assay_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 studyfactor

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Studyfactor>

=cut

__PACKAGE__->belongs_to(
  "studyfactor",
  "Database::Chado::Schema::Result::Studyfactor",
  { studyfactor_id => "studyfactor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DWPf26uTu0UjZg30c3px/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
