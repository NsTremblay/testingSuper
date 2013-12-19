use utf8;
package Database::Chado::Schema::Result::CvLinkCount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::CvLinkCount

=head1 DESCRIPTION

per-cv summary of number of
links (cvterm_relationships) broken down by
relationship_type. num_links is the total # of links of the specified
type in which the subject_id of the link is in the named cv

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<cv_link_count>

=cut

__PACKAGE__->table("cv_link_count");

=head1 ACCESSORS

=head2 cv_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 relation_name

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 relation_cv_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 num_links

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cv_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "relation_name",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "relation_cv_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "num_links",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AQsTsqc66KwTFsI90BPbnQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
