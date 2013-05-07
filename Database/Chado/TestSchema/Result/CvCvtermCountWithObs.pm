use utf8;
package Database::Chado::TestSchema::Result::CvCvtermCountWithObs;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::CvCvtermCountWithObs - per-cv terms counts (includes obsoletes)

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cv_cvterm_count_with_obs>

=cut

__PACKAGE__->table("cv_cvterm_count_with_obs");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 num_terms_incl_obs

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "num_terms_incl_obs",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:04VasH8ez9rRjjM25Focqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
