use utf8;
package Database::Chado::Schema::Result::NdExperimentProtocol;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::NdExperimentProtocol - Linking table: experiments to the protocols they involve.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<nd_experiment_protocol>

=cut

__PACKAGE__->table("nd_experiment_protocol");

=head1 ACCESSORS

=head2 nd_experiment_protocol_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_protocol_nd_experiment_protocol_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 nd_protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_protocol_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_protocol_nd_experiment_protocol_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "nd_protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nd_experiment_protocol_id>

=back

=cut

__PACKAGE__->set_primary_key("nd_experiment_protocol_id");

=head1 RELATIONS

=head2 nd_experiment

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::NdExperiment>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment",
  "Database::Chado::Schema::Result::NdExperiment",
  { nd_experiment_id => "nd_experiment_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);

=head2 nd_protocol

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::NdProtocol>

=cut

__PACKAGE__->belongs_to(
  "nd_protocol",
  "Database::Chado::Schema::Result::NdProtocol",
  { nd_protocol_id => "nd_protocol_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mtoJVjPZPhP1nfyCaMyvYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
