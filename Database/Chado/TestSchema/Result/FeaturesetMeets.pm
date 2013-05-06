use utf8;
package Database::Chado::TestSchema::Result::FeaturesetMeets;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::TestSchema::Result::FeaturesetMeets

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-29 14:01:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QmIo7LIN9q8dJoFgK1fShA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
