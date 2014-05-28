use utf8;
package Database::Chado::Schema::Result::Gffatt;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Gffatt

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gffatts>

=cut

__PACKAGE__->table("gffatts");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 attribute

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "attribute",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+WL9eQW9Azsd9TrgZYjKNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
