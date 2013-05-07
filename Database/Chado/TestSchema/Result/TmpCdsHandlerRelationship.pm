use utf8;
package Database::Chado::TestSchema::Result::TmpCdsHandlerRelationship;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::TmpCdsHandlerRelationship

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tmp_cds_handler_relationship>

=cut

__PACKAGE__->table("tmp_cds_handler_relationship");

=head1 ACCESSORS

=head2 rel_row_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tmp_cds_handler_relationship_rel_row_id_seq'

=head2 cds_row_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 parent_id

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 grandparent_id

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=cut

__PACKAGE__->add_columns(
  "rel_row_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tmp_cds_handler_relationship_rel_row_id_seq",
  },
  "cds_row_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "parent_id",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "grandparent_id",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
);

=head1 PRIMARY KEY

=over 4

=item * L</rel_row_id>

=back

=cut

__PACKAGE__->set_primary_key("rel_row_id");

=head1 RELATIONS

=head2 cds_row

Type: belongs_to

Related object: L<Database::Chado::TestSchema::Result::TmpCdsHandler>

=cut

__PACKAGE__->belongs_to(
  "cds_row",
  "Database::Chado::TestSchema::Result::TmpCdsHandler",
  { cds_row_id => "cds_row_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7ODBh1JH6Zdc3fG7SU5ZLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
