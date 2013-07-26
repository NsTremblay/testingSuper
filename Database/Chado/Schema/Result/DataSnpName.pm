use utf8;
package Database::Chado::Schema::Result::DataSnpName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::DataSnpName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<data_snp_names>

=cut

__PACKAGE__->table("data_snp_names");

=head1 ACCESSORS

=head2 serial_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'data_snp_names_serial_id_seq'

=head2 snp_name

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
    sequence          => "data_snp_names_serial_id_seq",
  },
  "snp_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</serial_id>

=back

=cut

__PACKAGE__->set_primary_key("serial_id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-26 02:31:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dTyh8ZuebYCMUOffxtqyrQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
