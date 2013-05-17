use utf8;
package Database::Chado::Schema::Result::RawBinaryData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::RawBinaryData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<raw_binary_data>

=cut

__PACKAGE__->table("raw_binary_data");

=head1 ACCESSORS

=head2 serial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'raw_binary_data_serial_id_seq'

=head2 strain

  data_type: 'text'
  is_nullable: 1

=head2 locus_name

  data_type: 'text'
  is_nullable: 1

=head2 presence_absence

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "serial_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "raw_binary_data_serial_id_seq",
  },
  "strain",
  { data_type => "text", is_nullable => 1 },
  "locus_name",
  { data_type => "text", is_nullable => 1 },
  "presence_absence",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</serial_id>

=back

=cut

__PACKAGE__->set_primary_key("serial_id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-17 14:51:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ll5GkhSMRXXswdLrU8Nc0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
