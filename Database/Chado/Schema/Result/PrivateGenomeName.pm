use utf8;
package Database::Chado::Schema::Result::PrivateGenomeName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::PrivateGenomeName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<private_genome_names>

=cut

__PACKAGE__->table("private_genome_names");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 1

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=head2 upload_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 1 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
  "upload_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-13 10:57:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Ub28HtRl9SQKOcELQOe+Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 upload

Join to upload table

=cut

__PACKAGE__->belongs_to(
  "upload",
  "Database::Chado::Schema::Result::Upload",
  { upload_id => "upload_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


1;
