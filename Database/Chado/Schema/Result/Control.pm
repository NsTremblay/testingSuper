use utf8;
package Database::Chado::Schema::Result::Control;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Control

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<control>

=cut

__PACKAGE__->table("control");

=head1 ACCESSORS

=head2 control_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'control_control_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tableinfo_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 row_id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "control_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "control_control_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tableinfo_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "row_id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</control_id>

=back

=cut

__PACKAGE__->set_primary_key("control_id");

=head1 RELATIONS

=head2 assay

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Database::Chado::Schema::Result::Assay",
  { assay_id => "assay_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 tableinfo

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Tableinfo>

=cut

__PACKAGE__->belongs_to(
  "tableinfo",
  "Database::Chado::Schema::Result::Tableinfo",
  { tableinfo_id => "tableinfo_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fclYQMB98Mam7w9ye2LA7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
