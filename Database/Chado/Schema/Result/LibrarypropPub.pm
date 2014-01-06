use utf8;
package Database::Chado::Schema::Result::LibrarypropPub;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::LibrarypropPub

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<libraryprop_pub>

=cut

__PACKAGE__->table("libraryprop_pub");

=head1 ACCESSORS

=head2 libraryprop_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'libraryprop_pub_libraryprop_pub_id_seq'

=head2 libraryprop_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "libraryprop_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "libraryprop_pub_libraryprop_pub_id_seq",
  },
  "libraryprop_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</libraryprop_pub_id>

=back

=cut

__PACKAGE__->set_primary_key("libraryprop_pub_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<libraryprop_pub_c1>

=over 4

=item * L</libraryprop_id>

=item * L</pub_id>

=back

=cut

__PACKAGE__->add_unique_constraint("libraryprop_pub_c1", ["libraryprop_id", "pub_id"]);

=head1 RELATIONS

=head2 libraryprop

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Libraryprop>

=cut

__PACKAGE__->belongs_to(
  "libraryprop",
  "Database::Chado::Schema::Result::Libraryprop",
  { libraryprop_id => "libraryprop_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 pub

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Database::Chado::Schema::Result::Pub",
  { pub_id => "pub_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uL8h1HFm2qky3NlPPvrssQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
