use utf8;
package Database::Chado::Schema::Result::RawVirulenceData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::RawVirulenceData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<raw_virulence_data>

=cut

__PACKAGE__->table("raw_virulence_data");

=head1 ACCESSORS

=head2 serial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'raw_virulence_data_serial_id_seq'

=head2 genome_id

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 presence_absence

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "serial_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "raw_virulence_data_serial_id_seq",
  },
  "genome_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "gene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "presence_absence",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</serial_id>

=back

=cut

__PACKAGE__->set_primary_key("serial_id");

=head1 RELATIONS

=head2 gene

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Database::Chado::Schema::Result::Feature",
  { feature_id => "gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U4vrP14jP5jq2uTgdwoxMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
