use utf8;
package Database::Chado::Schema::Result::Cvterm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Database::Chado::Schema::Result::Cvterm

=head1 DESCRIPTION

A term, class, universal or type within an
ontology or controlled vocabulary.  This table is also used for
relations and properties. cvterms constitute nodes in the graph
defined by the collection of cvterms and cvterm_relationships.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cvterm>

=cut

__PACKAGE__->table("cvterm");

=head1 ACCESSORS

=head2 cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cvterm_cvterm_id_seq'

=head2 cv_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The cv or ontology or namespace to which
this cvterm belongs.

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

A concise human-readable name or
label for the cvterm. Uniquely identifies a cvterm within a cv.

=head2 definition

  data_type: 'text'
  is_nullable: 1

A human-readable text
definition.

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Primary identifier dbxref - The
unique global OBO identifier for this cvterm.  Note that a cvterm may
have multiple secondary dbxrefs - see also table: cvterm_dbxref.

=head2 is_obsolete

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Boolean 0=false,1=true; see
GO documentation for details of obsoletion. Note that two terms with
different primary dbxrefs may exist if one is obsolete.

=head2 is_relationshiptype

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Boolean
0=false,1=true relations or relationship types (also known as Typedefs
in OBO format, or as properties or slots) form a cv/ontology in
themselves. We use this flag to indicate whether this cvterm is an
actual term/class/universal or a relation. Relations may be drawn from
the OBO Relations ontology, but are not exclusively drawn from there.

=cut

__PACKAGE__->add_columns(
  "cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cvterm_cvterm_id_seq",
  },
  "cv_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
  "definition",
  { data_type => "text", is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "is_relationshiptype",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cvterm_id>

=back

=cut

__PACKAGE__->set_primary_key("cvterm_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cvterm_c1>

=over 4

=item * L</name>

=item * L</cv_id>

=item * L</is_obsolete>

=back

=cut

__PACKAGE__->add_unique_constraint("cvterm_c1", ["name", "cv_id", "is_obsolete"]);

=head2 C<cvterm_c2>

=over 4

=item * L</dbxref_id>

=back

=cut

__PACKAGE__->add_unique_constraint("cvterm_c2", ["dbxref_id"]);

=head1 RELATIONS

=head2 acquisition_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::AcquisitionRelationship>

=cut

__PACKAGE__->has_many(
  "acquisition_relationships",
  "Database::Chado::Schema::Result::AcquisitionRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 acquisitionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Acquisitionprop>

=cut

__PACKAGE__->has_many(
  "acquisitionprops",
  "Database::Chado::Schema::Result::Acquisitionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 analysisfeatureprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Analysisfeatureprop>

=cut

__PACKAGE__->has_many(
  "analysisfeatureprops",
  "Database::Chado::Schema::Result::Analysisfeatureprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 analysisprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Analysisprop>

=cut

__PACKAGE__->has_many(
  "analysisprops",
  "Database::Chado::Schema::Result::Analysisprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesign_platformtypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesign_platformtypes",
  "Database::Chado::Schema::Result::Arraydesign",
  { "foreign.platformtype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesign_substratetypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesign_substratetypes",
  "Database::Chado::Schema::Result::Arraydesign",
  { "foreign.substratetype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesignprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Arraydesignprop>

=cut

__PACKAGE__->has_many(
  "arraydesignprops",
  "Database::Chado::Schema::Result::Arraydesignprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assayprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Assayprop>

=cut

__PACKAGE__->has_many(
  "assayprops",
  "Database::Chado::Schema::Result::Assayprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::BiomaterialRelationship>

=cut

__PACKAGE__->has_many(
  "biomaterial_relationships",
  "Database::Chado::Schema::Result::BiomaterialRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_treatments

Type: has_many

Related object: L<Database::Chado::Schema::Result::BiomaterialTreatment>

=cut

__PACKAGE__->has_many(
  "biomaterial_treatments",
  "Database::Chado::Schema::Result::BiomaterialTreatment",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterialprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Biomaterialprop>

=cut

__PACKAGE__->has_many(
  "biomaterialprops",
  "Database::Chado::Schema::Result::Biomaterialprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_cvtermprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineCvtermprop>

=cut

__PACKAGE__->has_many(
  "cell_line_cvtermprops",
  "Database::Chado::Schema::Result::CellLineCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Database::Chado::Schema::Result::CellLineCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationships",
  "Database::Chado::Schema::Result::CellLineRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::CellLineprop>

=cut

__PACKAGE__->has_many(
  "cell_lineprops",
  "Database::Chado::Schema::Result::CellLineprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chadoprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Chadoprop>

=cut

__PACKAGE__->has_many(
  "chadoprops",
  "Database::Chado::Schema::Result::Chadoprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationships",
  "Database::Chado::Schema::Result::ContactRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contacts

Type: has_many

Related object: L<Database::Chado::Schema::Result::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "Database::Chado::Schema::Result::Contact",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 controls

Type: has_many

Related object: L<Database::Chado::Schema::Result::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Database::Chado::Schema::Result::Control",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cv

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Cv>

=cut

__PACKAGE__->belongs_to(
  "cv",
  "Database::Chado::Schema::Result::Cv",
  { cv_id => "cv_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 cvprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvprop>

=cut

__PACKAGE__->has_many(
  "cvprops",
  "Database::Chado::Schema::Result::Cvprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_dbxrefs

Type: has_many

Related object: L<Database::Chado::Schema::Result::CvtermDbxref>

=cut

__PACKAGE__->has_many(
  "cvterm_dbxrefs",
  "Database::Chado::Schema::Result::CvtermDbxref",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_objects",
  "Database::Chado::Schema::Result::CvtermRelationship",
  { "foreign.object_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_subjects",
  "Database::Chado::Schema::Result::CvtermRelationship",
  { "foreign.subject_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_types

Type: has_many

Related object: L<Database::Chado::Schema::Result::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_types",
  "Database::Chado::Schema::Result::CvtermRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_objects

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_objects",
  "Database::Chado::Schema::Result::Cvtermpath",
  { "foreign.object_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_subjects

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_subjects",
  "Database::Chado::Schema::Result::Cvtermpath",
  { "foreign.subject_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_types

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_types",
  "Database::Chado::Schema::Result::Cvtermpath",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermprop_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermprop>

=cut

__PACKAGE__->has_many(
  "cvtermprop_cvterms",
  "Database::Chado::Schema::Result::Cvtermprop",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermprop_types

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermprop>

=cut

__PACKAGE__->has_many(
  "cvtermprop_types",
  "Database::Chado::Schema::Result::Cvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermsynonym_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermsynonym>

=cut

__PACKAGE__->has_many(
  "cvtermsynonym_cvterms",
  "Database::Chado::Schema::Result::Cvtermsynonym",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermsynonym_types

Type: has_many

Related object: L<Database::Chado::Schema::Result::Cvtermsynonym>

=cut

__PACKAGE__->has_many(
  "cvtermsynonym_types",
  "Database::Chado::Schema::Result::Cvtermsynonym",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dbxref

Type: belongs_to

Related object: L<Database::Chado::Schema::Result::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Database::Chado::Schema::Result::Dbxref",
  { dbxref_id => "dbxref_id" },
  { is_deferrable => 1, on_delete => "SET NULL", on_update => "NO ACTION" },
);

=head2 dbxrefprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Dbxrefprop>

=cut

__PACKAGE__->has_many(
  "dbxrefprops",
  "Database::Chado::Schema::Result::Dbxrefprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 element_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationships",
  "Database::Chado::Schema::Result::ElementRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elementresult_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::ElementresultRelationship>

=cut

__PACKAGE__->has_many(
  "elementresult_relationships",
  "Database::Chado::Schema::Result::ElementresultRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elements

Type: has_many

Related object: L<Database::Chado::Schema::Result::Element>

=cut

__PACKAGE__->has_many(
  "elements",
  "Database::Chado::Schema::Result::Element",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 environment_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::EnvironmentCvterm>

=cut

__PACKAGE__->has_many(
  "environment_cvterms",
  "Database::Chado::Schema::Result::EnvironmentCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvterm_cvterm_types

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterm_cvterm_types",
  "Database::Chado::Schema::Result::ExpressionCvterm",
  { "foreign.cvterm_type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvterm_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterm_cvterms",
  "Database::Chado::Schema::Result::ExpressionCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvtermprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::ExpressionCvtermprop>

=cut

__PACKAGE__->has_many(
  "expression_cvtermprops",
  "Database::Chado::Schema::Result::ExpressionCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expressionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Expressionprop>

=cut

__PACKAGE__->has_many(
  "expressionprops",
  "Database::Chado::Schema::Result::Expressionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvtermprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureCvtermprop>

=cut

__PACKAGE__->has_many(
  "feature_cvtermprops",
  "Database::Chado::Schema::Result::FeatureCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureCvterm>

=cut

__PACKAGE__->has_many(
  "feature_cvterms",
  "Database::Chado::Schema::Result::FeatureCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureExpressionprop>

=cut

__PACKAGE__->has_many(
  "feature_expressionprops",
  "Database::Chado::Schema::Result::FeatureExpressionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureGenotype>

=cut

__PACKAGE__->has_many(
  "feature_genotypes",
  "Database::Chado::Schema::Result::FeatureGenotype",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_pubprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeaturePubprop>

=cut

__PACKAGE__->has_many(
  "feature_pubprops",
  "Database::Chado::Schema::Result::FeaturePubprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationshipprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureRelationshipprop>

=cut

__PACKAGE__->has_many(
  "feature_relationshipprops",
  "Database::Chado::Schema::Result::FeatureRelationshipprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::FeatureRelationship>

=cut

__PACKAGE__->has_many(
  "feature_relationships",
  "Database::Chado::Schema::Result::FeatureRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featuremaps

Type: has_many

Related object: L<Database::Chado::Schema::Result::Featuremap>

=cut

__PACKAGE__->has_many(
  "featuremaps",
  "Database::Chado::Schema::Result::Featuremap",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Featureprop>

=cut

__PACKAGE__->has_many(
  "featureprops",
  "Database::Chado::Schema::Result::Featureprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<Database::Chado::Schema::Result::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "Database::Chado::Schema::Result::Feature",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotypeprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Genotypeprop>

=cut

__PACKAGE__->has_many(
  "genotypeprops",
  "Database::Chado::Schema::Result::Genotypeprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Genotype>

=cut

__PACKAGE__->has_many(
  "genotypes",
  "Database::Chado::Schema::Result::Genotype",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraries

Type: has_many

Related object: L<Database::Chado::Schema::Result::Library>

=cut

__PACKAGE__->has_many(
  "libraries",
  "Database::Chado::Schema::Result::Library",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::LibraryCvterm>

=cut

__PACKAGE__->has_many(
  "library_cvterms",
  "Database::Chado::Schema::Result::LibraryCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraryprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Libraryprop>

=cut

__PACKAGE__->has_many(
  "libraryprops",
  "Database::Chado::Schema::Result::Libraryprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stockprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentStockprop>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stockprops",
  "Database::Chado::Schema::Result::NdExperimentStockprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stocks

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentStock>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stocks",
  "Database::Chado::Schema::Result::NdExperimentStock",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experimentprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperimentprop>

=cut

__PACKAGE__->has_many(
  "nd_experimentprops",
  "Database::Chado::Schema::Result::NdExperimentprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiments

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdExperiment>

=cut

__PACKAGE__->has_many(
  "nd_experiments",
  "Database::Chado::Schema::Result::NdExperiment",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_geolocationprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdGeolocationprop>

=cut

__PACKAGE__->has_many(
  "nd_geolocationprops",
  "Database::Chado::Schema::Result::NdGeolocationprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocol_reagents

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdProtocolReagent>

=cut

__PACKAGE__->has_many(
  "nd_protocol_reagents",
  "Database::Chado::Schema::Result::NdProtocolReagent",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocolprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdProtocolprop>

=cut

__PACKAGE__->has_many(
  "nd_protocolprops",
  "Database::Chado::Schema::Result::NdProtocolprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocols

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdProtocol>

=cut

__PACKAGE__->has_many(
  "nd_protocols",
  "Database::Chado::Schema::Result::NdProtocol",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationships",
  "Database::Chado::Schema::Result::NdReagentRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagentprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdReagentprop>

=cut

__PACKAGE__->has_many(
  "nd_reagentprops",
  "Database::Chado::Schema::Result::NdReagentprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagents

Type: has_many

Related object: L<Database::Chado::Schema::Result::NdReagent>

=cut

__PACKAGE__->has_many(
  "nd_reagents",
  "Database::Chado::Schema::Result::NdReagent",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organismprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Organismprop>

=cut

__PACKAGE__->has_many(
  "organismprops",
  "Database::Chado::Schema::Result::Organismprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Database::Chado::Schema::Result::Phendesc",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_assays

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_assays",
  "Database::Chado::Schema::Result::Phenotype",
  { "foreign.assay_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attrs

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_attrs",
  "Database::Chado::Schema::Result::Phenotype",
  { "foreign.attr_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Database::Chado::Schema::Result::PhenotypeComparisonCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_cvalues

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_cvalues",
  "Database::Chado::Schema::Result::Phenotype",
  { "foreign.cvalue_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhenotypeCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_cvterms",
  "Database::Chado::Schema::Result::PhenotypeCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_observables

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_observables",
  "Database::Chado::Schema::Result::Phenotype",
  { "foreign.observable_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Database::Chado::Schema::Result::Phenstatement",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::PhylonodeRelationship>

=cut

__PACKAGE__->has_many(
  "phylonode_relationships",
  "Database::Chado::Schema::Result::PhylonodeRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonodeprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phylonodeprop>

=cut

__PACKAGE__->has_many(
  "phylonodeprops",
  "Database::Chado::Schema::Result::Phylonodeprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonodes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phylonode>

=cut

__PACKAGE__->has_many(
  "phylonodes",
  "Database::Chado::Schema::Result::Phylonode",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotrees

Type: has_many

Related object: L<Database::Chado::Schema::Result::Phylotree>

=cut

__PACKAGE__->has_many(
  "phylotrees",
  "Database::Chado::Schema::Result::Phylotree",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationships",
  "Database::Chado::Schema::Result::ProjectRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Projectprop>

=cut

__PACKAGE__->has_many(
  "projectprops",
  "Database::Chado::Schema::Result::Projectprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocolparam_datatypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Protocolparam>

=cut

__PACKAGE__->has_many(
  "protocolparam_datatypes",
  "Database::Chado::Schema::Result::Protocolparam",
  { "foreign.datatype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocolparam_unittypes

Type: has_many

Related object: L<Database::Chado::Schema::Result::Protocolparam>

=cut

__PACKAGE__->has_many(
  "protocolparam_unittypes",
  "Database::Chado::Schema::Result::Protocolparam",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocols

Type: has_many

Related object: L<Database::Chado::Schema::Result::Protocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "Database::Chado::Schema::Result::Protocol",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationships",
  "Database::Chado::Schema::Result::PubRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Pubprop>

=cut

__PACKAGE__->has_many(
  "pubprops",
  "Database::Chado::Schema::Result::Pubprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubs

Type: has_many

Related object: L<Database::Chado::Schema::Result::Pub>

=cut

__PACKAGE__->has_many(
  "pubs",
  "Database::Chado::Schema::Result::Pub",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantification_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::QuantificationRelationship>

=cut

__PACKAGE__->has_many(
  "quantification_relationships",
  "Database::Chado::Schema::Result::QuantificationRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantificationprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Quantificationprop>

=cut

__PACKAGE__->has_many(
  "quantificationprops",
  "Database::Chado::Schema::Result::Quantificationprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvtermprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockCvtermprop>

=cut

__PACKAGE__->has_many(
  "stock_cvtermprops",
  "Database::Chado::Schema::Result::StockCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Database::Chado::Schema::Result::StockCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_dbxrefprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockDbxrefprop>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefprops",
  "Database::Chado::Schema::Result::StockDbxrefprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_cvterms

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockRelationshipCvterm>

=cut

__PACKAGE__->has_many(
  "stock_relationship_cvterms",
  "Database::Chado::Schema::Result::StockRelationshipCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationships

Type: has_many

Related object: L<Database::Chado::Schema::Result::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationships",
  "Database::Chado::Schema::Result::StockRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollectionprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stockcollectionprop>

=cut

__PACKAGE__->has_many(
  "stockcollectionprops",
  "Database::Chado::Schema::Result::Stockcollectionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollections

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stockcollection>

=cut

__PACKAGE__->has_many(
  "stockcollections",
  "Database::Chado::Schema::Result::Stockcollection",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stockprop>

=cut

__PACKAGE__->has_many(
  "stockprops",
  "Database::Chado::Schema::Result::Stockprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stocks

Type: has_many

Related object: L<Database::Chado::Schema::Result::Stock>

=cut

__PACKAGE__->has_many(
  "stocks",
  "Database::Chado::Schema::Result::Stock",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studydesignprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studydesignprop>

=cut

__PACKAGE__->has_many(
  "studydesignprops",
  "Database::Chado::Schema::Result::Studydesignprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactors

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studyfactor>

=cut

__PACKAGE__->has_many(
  "studyfactors",
  "Database::Chado::Schema::Result::Studyfactor",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyprop_features

Type: has_many

Related object: L<Database::Chado::Schema::Result::StudypropFeature>

=cut

__PACKAGE__->has_many(
  "studyprop_features",
  "Database::Chado::Schema::Result::StudypropFeature",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyprops

Type: has_many

Related object: L<Database::Chado::Schema::Result::Studyprop>

=cut

__PACKAGE__->has_many(
  "studyprops",
  "Database::Chado::Schema::Result::Studyprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 synonyms

Type: has_many

Related object: L<Database::Chado::Schema::Result::Synonym>

=cut

__PACKAGE__->has_many(
  "synonyms",
  "Database::Chado::Schema::Result::Synonym",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 treatments

Type: has_many

Related object: L<Database::Chado::Schema::Result::Treatment>

=cut

__PACKAGE__->has_many(
  "treatments",
  "Database::Chado::Schema::Result::Treatment",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-06 10:20:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o/cFwi8FP0Jj1w3aNUSeOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
