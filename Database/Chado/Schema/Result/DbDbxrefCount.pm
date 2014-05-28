use utf8;
package Database::Chado::Schema::Result::DbDbxrefCount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::DbDbxrefCount - per-db dbxref counts

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<db_dbxref_count>

=cut

__PACKAGE__->table("db_dbxref_count");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 num_dbxrefs

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "num_dbxrefs",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fcW5ZCfkMhbXP06vv5pZDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
