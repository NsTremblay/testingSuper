use utf8;
package Database::Chado::Schema::Result::Pub;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Pub

=head1 DESCRIPTION

A documented provenance artefact - publications,
documents, personal communication.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pub>

=cut

__PACKAGE__->table("pub");

=head1 ACCESSORS

=head2 pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pub_pub_id_seq'

=head2 title

  data_type: 'text'
  is_nullable: 1

Descriptive general heading.

=head2 volumetitle

  data_type: 'text'
  is_nullable: 1

Title of part if one of a series.

=head2 volume

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 series_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

Full name of (journal) series.

=head2 issue

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pyear

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pages

  data_type: 'varchar'
  is_nullable: 1
  size: 255

Page number range[s], e.g. 457--459, viii + 664pp, lv--lvii.

=head2 miniref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type of the publication (book, journal, poem, graffiti, etc). Uses pub cv.

=head2 is_obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 publisher

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pubplace

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pub_pub_id_seq",
  },
  "title",
  { data_type => "text", is_nullable => 1 },
  "volumetitle",
  { data_type => "text", is_nullable => 1 },
  "volume",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "series_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "issue",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pyear",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pages",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "miniref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "publisher",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pubplace",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pub_id>

=back

=cut

__PACKAGE__->set_primary_key("pub_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<pub_c1>

=over 4

=item * L</uniquename>

=back

=cut

__PACKAGE__->add_unique_constraint("pub_c1", ["uniquename"]);

=head1 RELATIONS

=head2 cell_line_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Database::Chado::Schema::Result::CellLineCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_features

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineFeature>

=cut

__PACKAGE__->has_many(
  "cell_line_features",
  "Database::Chado::Schema::Result::CellLineFeature",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_libraries

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineLibrary>

=cut

__PACKAGE__->has_many(
  "cell_line_libraries",
  "Database::Chado::Schema::Result::CellLineLibrary",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLinePub>

=cut

__PACKAGE__->has_many(
  "cell_line_pubs",
  "Database::Chado::Schema::Result::CellLinePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_synonyms

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineSynonym>

=cut

__PACKAGE__->has_many(
  "cell_line_synonyms",
  "Database::Chado::Schema::Result::CellLineSynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLinepropPub>

=cut

__PACKAGE__->has_many(
  "cell_lineprop_pubs",
  "Database::Chado::Schema::Result::CellLinepropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionPub>

=cut

__PACKAGE__->has_many(
  "expression_pubs",
  "Database::Chado::Schema::Result::ExpressionPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterm_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureCvtermPub>

=cut

__PACKAGE__->has_many(
  "feature_cvterm_pubs",
  "Database::Chado::Schema::Result::FeatureCvtermPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureCvterm>

=cut

__PACKAGE__->has_many(
  "feature_cvterms",
  "Database::Chado::Schema::Result::FeatureCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressions

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureExpression>

=cut

__PACKAGE__->has_many(
  "feature_expressions",
  "Database::Chado::Schema::Result::FeatureExpression",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeaturePub>

=cut

__PACKAGE__->has_many(
  "feature_pubs",
  "Database::Chado::Schema::Result::FeaturePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationship_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureRelationshipPub>

=cut

__PACKAGE__->has_many(
  "feature_relationship_pubs",
  "Database::Chado::Schema::Result::FeatureRelationshipPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationshipprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureRelationshippropPub>

=cut

__PACKAGE__->has_many(
  "feature_relationshipprop_pubs",
  "Database::Chado::Schema::Result::FeatureRelationshippropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_synonyms

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureSynonym>

=cut

__PACKAGE__->has_many(
  "feature_synonyms",
  "Database::Chado::Schema::Result::FeatureSynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureloc_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeaturelocPub>

=cut

__PACKAGE__->has_many(
  "featureloc_pubs",
  "Database::Chado::Schema::Result::FeaturelocPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featuremap_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeaturemapPub>

=cut

__PACKAGE__->has_many(
  "featuremap_pubs",
  "Database::Chado::Schema::Result::FeaturemapPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeaturepropPub>

=cut

__PACKAGE__->has_many(
  "featureprop_pubs",
  "Database::Chado::Schema::Result::FeaturepropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::LibraryCvterm>

=cut

__PACKAGE__->has_many(
  "library_cvterms",
  "Database::Chado::Schema::Result::LibraryCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::LibraryPub>

=cut

__PACKAGE__->has_many(
  "library_pubs",
  "Database::Chado::Schema::Result::LibraryPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_synonyms

Type: has_many

Related object: L<Database::Chado::Schema::Result::LibrarySynonym>

=cut

__PACKAGE__->has_many(
  "library_synonyms",
  "Database::Chado::Schema::Result::LibrarySynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraryprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::LibrarypropPub>

=cut

__PACKAGE__->has_many(
  "libraryprop_pubs",
  "Database::Chado::Schema::Result::LibrarypropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentPub>

=cut

__PACKAGE__->has_many(
  "nd_experiment_pubs",
  "Database::Chado::Schema::Result::NdExperimentPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Database::Chado::Schema::Result::Phendesc",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Database::Chado::Schema::Result::PhenotypeComparisonCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparisons

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparisons",
  "Database::Chado::Schema::Result::PhenotypeComparison",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Database::Chado::Schema::Result::Phenstatement",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylonodePub>

=cut

__PACKAGE__->has_many(
  "phylonode_pubs",
  "Database::Chado::Schema::Result::PhylonodePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotree_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylotreePub>

=cut

__PACKAGE__->has_many(
  "phylotree_pubs",
  "Database::Chado::Schema::Result::PhylotreePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_feature_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PrivateFeatureCvterm>

=cut

__PACKAGE__->has_many(
  "private_feature_cvterms",
  "Database::Chado::Schema::Result::PrivateFeatureCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::ProjectPub>

=cut

__PACKAGE__->has_many(
  "project_pubs",
  "Database::Chado::Schema::Result::ProjectPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocols

Type: has_many

Related object: L<Database::Chado::Schema::Result::Protocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "Database::Chado::Schema::Result::Protocol",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_dbxrefs

Type: has_many

Related object: L<Database::Chado::Schema::Result::PubDbxref>

=cut

__PACKAGE__->has_many(
  "pub_dbxrefs",
  "Database::Chado::Schema::Result::PubDbxref",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationship_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationship_objects",
  "Database::Chado::Schema::Result::PubRelationship",
  { "foreign.object_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationship_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationship_subjects",
  "Database::Chado::Schema::Result::PubRelationship",
  { "foreign.subject_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubauthors

Type: has_many

Related object: L<Database::Chado::Schema::Result::Pubauthor>

=cut

__PACKAGE__->has_many(
  "pubauthors",
  "Database::Chado::Schema::Result::Pubauthor",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Pubprop>

=cut

__PACKAGE__->has_many(
  "pubprops",
  "Database::Chado::Schema::Result::Pubprop",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Database::Chado::Schema::Result::StockCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockPub>

=cut

__PACKAGE__->has_many(
  "stock_pubs",
  "Database::Chado::Schema::Result::StockPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockRelationshipCvterm>

=cut

__PACKAGE__->has_many(
  "stock_relationship_cvterms",
  "Database::Chado::Schema::Result::StockRelationshipCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockRelationshipPub>

=cut

__PACKAGE__->has_many(
  "stock_relationship_pubs",
  "Database::Chado::Schema::Result::StockRelationshipPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprop_pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockpropPub>

=cut

__PACKAGE__->has_many(
  "stockprop_pubs",
  "Database::Chado::Schema::Result::StockpropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studies

Type: has_many

Related object: L<Database::Chado::Schema::Result::Study>

=cut

__PACKAGE__->has_many(
  "studies",
  "Database::Chado::Schema::Result::Study",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Database::Chado::Schema::Result::Cvterm",
  { cvterm_id => "type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-18 19:03:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iKqiDv2AcU+IMXRu3ADG1w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
