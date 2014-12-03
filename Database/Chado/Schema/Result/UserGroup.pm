use utf8;
package Database::Chado::Schema::Result::UserGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::UserGroup

=head1 DESCRIPTION

Saves user defined groups and group collections from shiny app in JSON format

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_groups>

=cut

__PACKAGE__->table("user_groups");

=head1 ACCESSORS

=head2 user_group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_groups_user_group_id_seq'

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 last_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 user_groups

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_groups_user_group_id_seq",
  },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "last_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "user_groups",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_group_id>

=back

=cut

__PACKAGE__->set_primary_key("user_group_id");


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-08-26 16:23:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8zASrov+vjE0bFWSW6Lzcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
