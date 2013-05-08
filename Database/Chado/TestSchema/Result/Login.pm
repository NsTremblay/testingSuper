use utf8;
package Database::Chado::TestSchema::Result::Login;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::Login

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<login>

=cut

__PACKAGE__->table("login");

=head1 ACCESSORS

=head2 login_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'login_login_id_seq'

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 22

=head2 firstname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 30

=head2 lastname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 30

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 creation_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "login_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "login_login_id_seq",
  },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 22 },
  "firstname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 30 },
  "lastname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 30 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "creation_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</login_id>

=back

=cut

__PACKAGE__->set_primary_key("login_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<login_c1>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("login_c1", ["username"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-24 14:52:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XRborAA3misZ0UtGtV3K0A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
