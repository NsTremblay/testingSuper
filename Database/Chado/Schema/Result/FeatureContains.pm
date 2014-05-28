use utf8;
package Database::Chado::Schema::Result::FeatureContains;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeatureContains

=head1 DESCRIPTION

subject intervals contains (or is
same as) object interval. transitive,reflexive

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_contains>

=cut

__PACKAGE__->table("feature_contains");

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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jqLiByPZRx19HUJUkn1dcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
