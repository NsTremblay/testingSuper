use utf8;
package Database::Chado::TestSchema::Result::TmpCdsHandler;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::TmpCdsHandler

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tmp_cds_handler>

=cut

__PACKAGE__->table("tmp_cds_handler");

=head1 ACCESSORS

=head2 cds_row_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tmp_cds_handler_cds_row_id_seq'

=head2 seq_id

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 gff_id

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

=head2 fmin

  data_type: 'integer'
  is_nullable: 0

=head2 fmax

  data_type: 'integer'
  is_nullable: 0

=head2 object

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cds_row_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tmp_cds_handler_cds_row_id_seq",
  },
  "seq_id",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "gff_id",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
  "fmin",
  { data_type => "integer", is_nullable => 0 },
  "fmax",
  { data_type => "integer", is_nullable => 0 },
  "object",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cds_row_id>

=back

=cut

__PACKAGE__->set_primary_key("cds_row_id");

=head1 RELATIONS

=head2 tmp_cds_handler_relationships

Type: has_many

Related object: L<Database::Chado::TestSchema::Result::TmpCdsHandlerRelationship>

=cut

__PACKAGE__->has_many(
  "tmp_cds_handler_relationships",
  "Database::Chado::TestSchema::Result::TmpCdsHandlerRelationship",
  { "foreign.cds_row_id" => "self.cds_row_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:thT/8fxrK8GAG/onpFQ6FA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
