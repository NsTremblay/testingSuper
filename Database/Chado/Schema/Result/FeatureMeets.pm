use utf8;
package Database::Chado::Schema::Result::FeatureMeets;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::FeatureMeets

=head1 DESCRIPTION

intervals have at least one
interbase point in common (ie overlap OR abut). symmetric,reflexive

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feature_meets>

=cut

__PACKAGE__->table("feature_meets");

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6t74s7Mqo4MP84kEc3dT1g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
