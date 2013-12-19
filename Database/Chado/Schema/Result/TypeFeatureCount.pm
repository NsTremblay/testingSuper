use utf8;
package Database::Chado::Schema::Result::TypeFeatureCount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::TypeFeatureCount - per-feature-type feature counts

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<type_feature_count>

=cut

__PACKAGE__->table("type_feature_count");

=head1 ACCESSORS

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 num_features

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "type",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "num_features",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pr4DQfoTPbPbzT++wBKy+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
