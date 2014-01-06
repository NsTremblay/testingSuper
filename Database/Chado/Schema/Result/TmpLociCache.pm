use utf8;
package Database::Chado::Schema::Result::TmpLociCache;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::TmpLociCache

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tmp_loci_cache>

=cut

__PACKAGE__->table("tmp_loci_cache");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 uniquename

  data_type: 'varchar'
  is_nullable: 1
  size: 1000

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=head2 genome_id

  data_type: 'integer'
  is_nullable: 1

=head2 contig_id

  data_type: 'integer'
  is_nullable: 1

=head2 query_id

  data_type: 'integer'
  is_nullable: 1

=head2 copy_number

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 pub

  data_type: 'boolean'
  is_nullable: 1

=head2 updated

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "uniquename",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
  "genome_id",
  { data_type => "integer", is_nullable => 1 },
  "contig_id",
  { data_type => "integer", is_nullable => 1 },
  "query_id",
  { data_type => "integer", is_nullable => 1 },
  "copy_number",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "pub",
  { data_type => "boolean", is_nullable => 1 },
  "updated",
  { data_type => "boolean", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Px3aWxQGmTlbxvt0gCyviA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
