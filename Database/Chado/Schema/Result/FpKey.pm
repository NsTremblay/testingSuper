use utf8;
package Database::Chado::Schema::Result::FpKey;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FpKey

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<fp_key>

=cut

__PACKAGE__->table("fp_key");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 pkey

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "pkey",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "value",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3inoz8LDvbiXa20ahIV3Cg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
