use utf8;
package Database::Chado::Schema::Result::FeatureDistance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeatureDistance

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_distance>

=cut

__PACKAGE__->table("feature_distance");

=head1 ACCESSORS

=head2 subject_id

  data_type: 'integer'
  is_nullable: 1

=head2 object_id

  data_type: 'integer'
  is_nullable: 1

=head2 srcfeature_id

  data_type: 'integer'
  is_nullable: 1

=head2 subject_strand

  data_type: 'smallint'
  is_nullable: 1

=head2 object_strand

  data_type: 'smallint'
  is_nullable: 1

=head2 distance

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "subject_id",
  { data_type => "integer", is_nullable => 1 },
  "object_id",
  { data_type => "integer", is_nullable => 1 },
  "srcfeature_id",
  { data_type => "integer", is_nullable => 1 },
  "subject_strand",
  { data_type => "smallint", is_nullable => 1 },
  "object_strand",
  { data_type => "smallint", is_nullable => 1 },
  "distance",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LhgRpSr6hOLqUihr2kawnQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
