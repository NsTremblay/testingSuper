use utf8;
package Database::Chado::Schema::Result::Gff3att;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Gff3att

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gff3atts>

=cut

__PACKAGE__->table("gff3atts");

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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:99jhIoelTXTwYY/2+/5jiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
