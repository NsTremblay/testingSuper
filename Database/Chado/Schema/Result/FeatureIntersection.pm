use utf8;
package Database::Chado::Schema::Result::FeatureIntersection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeatureIntersection

=head1 DESCRIPTION

set-intersection on interval defined by featureloc. featurelocs must meet

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_intersection>

=cut

__PACKAGE__->table("feature_intersection");

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

=head2 fmin

  data_type: 'integer'
  is_nullable: 1

=head2 fmax

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
  "fmin",
  { data_type => "integer", is_nullable => 1 },
  "fmax",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FyAwZfX/HW+fCAHPYwSWFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
