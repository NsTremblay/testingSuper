use utf8;
package Database::Chado::Schema::Result::Channel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Channel

=head1 DESCRIPTION

Different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but Affymetrix uses only one).

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<channel>

=cut

__PACKAGE__->table("channel");

=head1 ACCESSORS

=head2 channel_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'channel_channel_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 definition

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "channel_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "channel_channel_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "definition",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</channel_id>

=back

=cut

__PACKAGE__->set_primary_key("channel_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<channel_c1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("channel_c1", ["name"]);

=head1 RELATIONS

=head2 acquisitions

Type: has_many

Related object: L<Database::Chado::Schema::Result::Acquisition>

=cut

__PACKAGE__->has_many(
  "acquisitions",
  "Database::Chado::Schema::Result::Acquisition",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay_biomaterials

Type: has_many

Related object: L<Database::Chado::Schema::Result::AssayBiomaterial>

=cut

__PACKAGE__->has_many(
  "assay_biomaterials",
  "Database::Chado::Schema::Result::AssayBiomaterial",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 12:10:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WAwrB+Si6h79Fi0g2KPquA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
