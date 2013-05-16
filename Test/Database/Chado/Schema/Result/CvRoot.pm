use utf8;
package Database::Chado::Schema::Result::CvRoot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::CvRoot

=head1 DESCRIPTION

the roots of a cv are the set of terms
which have no parents (terms that are not the subject of a
relation). Most cvs will have a single root, some may have >1. All
will have at least 1

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cv_root>

=cut

__PACKAGE__->table("cv_root");

=head1 ACCESSORS

=head2 cv_id

  data_type: 'integer'
  is_nullable: 1

=head2 root_cvterm_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cv_id",
  { data_type => "integer", is_nullable => 1 },
  "root_cvterm_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-06 10:20:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SOmxg19JfnyExBmGV4WyAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
