use utf8;
package Database::Chado::Schema::Result::CommonDescendantCvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::CommonDescendantCvterm

=head1 DESCRIPTION

The common descendant of
any two terms is the intersection of both terms descendants. Two terms
can have multiple common descendants. Use total_pathdistance to get
the least common ancestor

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<common_descendant_cvterm>

=cut

__PACKAGE__->table("common_descendant_cvterm");

=head1 ACCESSORS

=head2 cvterm1_id

  data_type: 'integer'
  is_nullable: 1

=head2 cvterm2_id

  data_type: 'integer'
  is_nullable: 1

=head2 ancestor_cvterm_id

  data_type: 'integer'
  is_nullable: 1

=head2 pathdistance1

  data_type: 'integer'
  is_nullable: 1

=head2 pathdistance2

  data_type: 'integer'
  is_nullable: 1

=head2 total_pathdistance

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cvterm1_id",
  { data_type => "integer", is_nullable => 1 },
  "cvterm2_id",
  { data_type => "integer", is_nullable => 1 },
  "ancestor_cvterm_id",
  { data_type => "integer", is_nullable => 1 },
  "pathdistance1",
  { data_type => "integer", is_nullable => 1 },
  "pathdistance2",
  { data_type => "integer", is_nullable => 1 },
  "total_pathdistance",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0c5XV96NrmpEl91TTa6hsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
