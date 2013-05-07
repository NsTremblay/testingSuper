use utf8;
package Database::Chado::TestSchema::Result::GffSortTmp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::GffSortTmp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gff_sort_tmp>

=cut

__PACKAGE__->table("gff_sort_tmp");

=head1 ACCESSORS

=head2 refseq

  data_type: 'varchar'
  is_nullable: 1
  size: 4000

=head2 id

  data_type: 'varchar'
  is_nullable: 1
  size: 4000

=head2 parent

  data_type: 'varchar'
  is_nullable: 1
  size: 4000

=head2 gffline

  data_type: 'varchar'
  is_nullable: 1
  size: 8000

=head2 row_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'gff_sort_tmp_row_id_seq'

=cut

__PACKAGE__->add_columns(
  "refseq",
  { data_type => "varchar", is_nullable => 1, size => 4000 },
  "id",
  { data_type => "varchar", is_nullable => 1, size => 4000 },
  "parent",
  { data_type => "varchar", is_nullable => 1, size => 4000 },
  "gffline",
  { data_type => "varchar", is_nullable => 1, size => 8000 },
  "row_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "gff_sort_tmp_row_id_seq",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</row_id>

=back

=cut

__PACKAGE__->set_primary_key("row_id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kUohqfrD1kK1HSGyNT7vnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
