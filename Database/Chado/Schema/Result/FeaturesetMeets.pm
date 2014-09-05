use utf8;
package Database::Chado::Schema::Result::FeaturesetMeets;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeaturesetMeets

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<featureset_meets>

=cut

__PACKAGE__->table("featureset_meets");

=head1 ACCESSORS

=head2 subject_id

  data_type: 'integer'
  is_nullable: 1

=head2 object_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "subject_id",
  { data_type => "integer", is_nullable => 1 },
  "object_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2014-06-27 14:59:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pr8+WXH2diLUR3RgQ/8m6w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
