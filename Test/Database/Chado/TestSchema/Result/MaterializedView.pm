use utf8;
package Database::Chado::TestSchema::Result::MaterializedView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::MaterializedView

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<materialized_view>

=cut

__PACKAGE__->table("materialized_view");

=head1 ACCESSORS

=head2 materialized_view_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'materialized_view_materialized_view_id_seq'

=head2 last_update

  data_type: 'timestamp'
  is_nullable: 1

=head2 refresh_time

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 mv_schema

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 mv_table

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 mv_specs

  data_type: 'text'
  is_nullable: 1

=head2 indexed

  data_type: 'text'
  is_nullable: 1

=head2 query

  data_type: 'text'
  is_nullable: 1

=head2 special_index

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "materialized_view_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "materialized_view_materialized_view_id_seq",
  },
  "last_update",
  { data_type => "timestamp", is_nullable => 1 },
  "refresh_time",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "mv_schema",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "mv_table",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "mv_specs",
  { data_type => "text", is_nullable => 1 },
  "indexed",
  { data_type => "text", is_nullable => 1 },
  "query",
  { data_type => "text", is_nullable => 1 },
  "special_index",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<materialized_view_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("materialized_view_name_key", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wkUtlYb4J+2yxhG3cyCJCg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
