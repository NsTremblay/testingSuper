use utf8;
package Database::Chado::Schema::Result::AllFeatureName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::AllFeatureName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<all_feature_names>

=cut

__PACKAGE__->table("all_feature_names");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rJPEZzX1vdXef8JiDBTZng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
