use utf8;
package Database::Chado::Schema::Result::IntronlocView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::IntronlocView

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<intronloc_view>

=cut

__PACKAGE__->table("intronloc_view");

=head1 ACCESSORS

=head2 exon1_id

  data_type: 'integer'
  is_nullable: 1

=head2 exon2_id

  data_type: 'integer'
  is_nullable: 1

=head2 fmin

  data_type: 'integer'
  is_nullable: 1

=head2 fmax

  data_type: 'integer'
  is_nullable: 1

=head2 strand

  data_type: 'smallint'
  is_nullable: 1

=head2 srcfeature_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "exon1_id",
  { data_type => "integer", is_nullable => 1 },
  "exon2_id",
  { data_type => "integer", is_nullable => 1 },
  "fmin",
  { data_type => "integer", is_nullable => 1 },
  "fmax",
  { data_type => "integer", is_nullable => 1 },
  "strand",
  { data_type => "smallint", is_nullable => 1 },
  "srcfeature_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q/zE4UYAslZTzQkjTHtAQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
