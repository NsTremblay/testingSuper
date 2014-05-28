use utf8;
package Database::Chado::Schema::Result::Gff3view;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Gff3view

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gff3view>

=cut

__PACKAGE__->table("gff3view");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 ref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 fstart

  data_type: 'integer'
  is_nullable: 1

=head2 fend

  data_type: 'integer'
  is_nullable: 1

=head2 score

  data_type: 'text'
  is_nullable: 1

=head2 strand

  data_type: 'text'
  is_nullable: 1

=head2 phase

  data_type: 'text'
  is_nullable: 1

=head2 seqlen

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "ref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "fstart",
  { data_type => "integer", is_nullable => 1 },
  "fend",
  { data_type => "integer", is_nullable => 1 },
  "score",
  { data_type => "text", is_nullable => 1 },
  "strand",
  { data_type => "text", is_nullable => 1 },
  "phase",
  { data_type => "text", is_nullable => 1 },
  "seqlen",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-05-27 15:57:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:25VfAFn2PpYCLoEeBhOlWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
