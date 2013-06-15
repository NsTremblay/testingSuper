use utf8;
package Database::Chado::Schema::Result::DataLociName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::DataLociName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<data_loci_names>

=cut

__PACKAGE__->table("data_loci_names");

=head1 ACCESSORS

=head2 serial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'data_loci_names_serial_id_seq'

=head2 locus_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "serial_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "data_loci_names_serial_id_seq",
  },
  "locus_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</serial_id>

=back

=cut

__PACKAGE__->set_primary_key("serial_id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-06-15 13:08:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yxRlqDQNP9D7a+4tXYSNCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
