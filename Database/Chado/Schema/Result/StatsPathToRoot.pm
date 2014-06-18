use utf8;
package Database::Chado::Schema::Result::StatsPathToRoot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::StatsPathToRoot

=head1 DESCRIPTION

per-cvterm statistics on its
placement in the DAG relative to the root. There may be multiple paths
from any term to the root. This gives the total number of paths, and
the average minimum and maximum distances. Here distance is defined by
cvtermpath.pathdistance

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stats_paths_to_root>

=cut

__PACKAGE__->table("stats_paths_to_root");

=head1 ACCESSORS

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 1

=head2 total_paths

  data_type: 'bigint'
  is_nullable: 1

=head2 avg_distance

  data_type: 'numeric'
  is_nullable: 1

=head2 min_distance

  data_type: 'integer'
  is_nullable: 1

=head2 max_distance

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cvterm_id",
  { data_type => "integer", is_nullable => 1 },
  "total_paths",
  { data_type => "bigint", is_nullable => 1 },
  "avg_distance",
  { data_type => "numeric", is_nullable => 1 },
  "min_distance",
  { data_type => "integer", is_nullable => 1 },
  "max_distance",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m0xbxnUlBiw47mxS3dW9Rg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
