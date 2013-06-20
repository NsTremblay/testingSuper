use utf8;
package Database::Chado::Schema::Result::DataLoci;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::DataLoci

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<data_loci>

=cut

__PACKAGE__->table("data_loci");

=head1 ACCESSORS

=head2 locus_name

  data_type: 'text'
  is_nullable: 1

=head2 pk_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'data_loci_pk_id_seq'

=cut

__PACKAGE__->add_columns(
  "locus_name",
  { data_type => "text", is_nullable => 1 },
  "pk_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "data_loci_pk_id_seq",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</pk_id>

=back

=cut

__PACKAGE__->set_primary_key("pk_id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-29 14:47:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wSlvzJdh4a9ByxKTartqXQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
