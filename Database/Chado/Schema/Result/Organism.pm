use utf8;
package Database::Chado::Schema::Result::Organism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Organism

=head1 DESCRIPTION

The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<organism>

=cut

__PACKAGE__->table("organism");

=head1 ACCESSORS

=head2 organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organism_organism_id_seq'

=head2 abbreviation

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 genus

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 species

  data_type: 'varchar'
  is_nullable: 0
  size: 255

A type of organism is always
uniquely identified by genus and species. When mapping from the NCBI
taxonomy names.dmp file, this column must be used where it
is present, as the common_name column is not always unique (e.g. environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern.

=head2 common_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organism_organism_id_seq",
  },
  "abbreviation",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "genus",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "species",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "common_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</organism_id>

=back

=cut

__PACKAGE__->set_primary_key("organism_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<organism_c1>

=over 4

=item * L</genus>

=item * L</species>

=back

=cut

__PACKAGE__->add_unique_constraint("organism_c1", ["genus", "species"]);

=head1 RELATIONS

=head2 biomaterials

Type: has_many

Related object: L<Database::Chado::Schema::Result::Biomaterial>

=cut

__PACKAGE__->has_many(
  "biomaterials",
  "Database::Chado::Schema::Result::Biomaterial",
  { "foreign.taxon_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lines

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLine>

=cut

__PACKAGE__->has_many(
  "cell_lines",
  "Database::Chado::Schema::Result::CellLine",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "Database::Chado::Schema::Result::Feature",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraries

Type: has_many

Related object: L<Database::Chado::Schema::Result::Library>

=cut

__PACKAGE__->has_many(
  "libraries",
  "Database::Chado::Schema::Result::Library",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_dbxrefs

Type: has_many

Related object: L<Database::Chado::Schema::Result::OrganismDbxref>

=cut

__PACKAGE__->has_many(
  "organism_dbxrefs",
  "Database::Chado::Schema::Result::OrganismDbxref",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organismprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Organismprop>

=cut

__PACKAGE__->has_many(
  "organismprops",
  "Database::Chado::Schema::Result::Organismprop",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparisons

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparisons",
  "Database::Chado::Schema::Result::PhenotypeComparison",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_organisms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylonodeOrganism>

=cut

__PACKAGE__->has_many(
  "phylonode_organisms",
  "Database::Chado::Schema::Result::PhylonodeOrganism",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_features

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeature>

=cut

__PACKAGE__->has_many(
  "private_features",
  "Database::Chado::Schema::Result::PrivateFeature",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stocks

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stock>

=cut

__PACKAGE__->has_many(
  "stocks",
  "Database::Chado::Schema::Result::Stock",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-06-09 10:04:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hKp03MijayS32ivmYhhWZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
