use utf8;
package Database::Chado::Schema::Result::UserSavedGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::UserSavedGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_saved_group>

=cut

__PACKAGE__->table("user_saved_group");

=head1 ACCESSORS

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 saved_groups

  data_type: 'json'
  is_nullable: 1

=head2 user_saved_groups_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_saved_group_user_saved_groups_id_seq'

=cut

__PACKAGE__->add_columns(
  "username",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "saved_groups",
  { data_type => "json", is_nullable => 1 },
  "user_saved_groups_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_saved_group_user_saved_groups_id_seq",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_saved_groups_id>

=back

=cut

__PACKAGE__->set_primary_key("user_saved_groups_id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-04 15:01:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZIIDxBNahv1Ky4gYj8Thwg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
