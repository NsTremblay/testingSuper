use utf8;
package Database::Chado::Schema::Result::LibraryFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::LibraryFeature

=head1 DESCRIPTION

library_feature links a library to the clones which are contained in the library.  Examples of such linked features might be "cDNA_clone" or  "genomic_clone".

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<library_feature>

=cut

__PACKAGE__->table("library_feature");

=head1 ACCESSORS

=head2 library_feature_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_feature_library_feature_id_seq'

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "library_feature_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_feature_library_feature_id_seq",
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</library_feature_id>

=back

=cut

__PACKAGE__->set_primary_key("library_feature_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<library_feature_c1>

=over 4

=item * L</library_id>

=item * L</feature_id>

=back

=cut

__PACKAGE__->add_unique_constraint("library_feature_c1", ["library_id", "feature_id"]);

=head1 RELATIONS

=head2 feature

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 library

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Database::Chado::Schema::Result::Library",
  { library_id => "library_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:twUOpJNAOkaMvpvl7nLVuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
