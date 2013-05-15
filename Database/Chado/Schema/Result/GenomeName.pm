use utf8;
package Database::Chado::Schema::Result::GenomeName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::GenomeName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<genome_names>

=cut

__PACKAGE__->table("genome_names");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 1

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 1 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-13 10:57:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XDynLb8tmG0w2hdYh6aJkQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
