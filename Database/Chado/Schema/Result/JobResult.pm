use utf8;
package Database::Chado::Schema::Result::JobResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::JobResult

=head1 DESCRIPTION

Table for long-polling group wise comparisons. Stores job requests, user configurations and results (if generated)

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<job_result>

=cut

__PACKAGE__->table("job_result");

=head1 ACCESSORS

=head2 job_result_id

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 remote_address

  data_type: 'inet'
  is_nullable: 1

=head2 session_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_config

  data_type: 'json'
  is_nullable: 0

=head2 job_result_status

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 result

  data_type: 'json'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "job_result_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "remote_address",
  { data_type => "inet", is_nullable => 1 },
  "session_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_config",
  { data_type => "json", is_nullable => 0 },
  "job_result_status",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "result",
  { data_type => "json", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</job_result_id>

=back

=cut

__PACKAGE__->set_primary_key("job_result_id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Login>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Database::Chado::Schema::Result::Login",
  { login_id => "user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE,",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OTr5Gj7dE6m6aaLmj76FdQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
