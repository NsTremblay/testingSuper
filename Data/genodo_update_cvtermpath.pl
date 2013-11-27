#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use IO::File;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Carp qw/croak carp/;
use Config::Simple;
use DBIx::Class::ResultSet;
use DBIx::Class::Row;
use List::MoreUtils qw/ uniq /;

=head1 NAME

$0 - Updates the cvtermpath table with relfexive transitive closures of cvterms of the database specified in the config file.

=head1 SYNOPSIS 

	% genodo_update_cvtermpath.perl

=head1 COMMAND-LINE OPTIONS

	--data_type		Specify whether cvterms coorespond to vir or amr.
	--config 		Specify a valid config file with db connection params.

=head1 DESCRIPTION

=head1 AUTHOR

Akiff Manji

=cut

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI, $dataType);

GetOptions(
	'data_type=s'   => \$dataType,
	'config=s'      => \$CONFIG,
	) or ( system( 'pod2text', $0 ), exit -1 );

# Connect to DB
croak "Missing argument. You must supply a configuration filename.\n" . system ('pod2text', $0) unless $CONFIG;
croak "Missing argument. You must supply a data type (vir, amr)\n" . system ('pod2text', $0) unless $dataType;

if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
} 
else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . ':dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS) or croak "Could not connect to database.";

my $cvterm = $schema->resultset('Cvterm')->find({'me.name' => 'antimicrobial_resistance_gene'});
my $id = $cvterm->cvterm_id;
die unless $id;

# my $geneResults = $schema->resultset('FeatureCvterm')->search(
# 	{'feature.type_id' => $id},
# 	{
# 		#join => [{'cvterm' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => 'object'}}}}}}}}}}}}}}, 'feature'],
# 		#select => ['me.feature_id','cvterm.name', 'me.cvterm_id', 'cvterm.name' , 'cvterm_relationship_subjects.object_id', 'object_7.name'],
# 		#as => ['gene_id', 'type_name', 'gene_cvterm_id', 'gene_cvterm_name', 'cvterm_parent_id', 'cvterm_parent_name']
# 	}
# 	);

#Categories will have the form:
# %categores = (
# 	'unclassified' => {
# 		{ 
# 			type_id => [feature_id..], here the type_id is the cvterm_id of the gene.
# 		}
# 	},
#
### Otherwise the has should have the form:
#
#	'parent_name' => {
#		parent_id => '###',
#			'subcategories' => {
#				cvterm_name => {
#				cvterm_id => '###',
#				genes => {type_id = []}
#			}
#		}
#	}
# )


my %unclassifiedIds;

#Bottom -> Up:
my $amrGeneResutls = $schema->resultset('FeatureCvterm')->search(
	{},
	{

		select => ['me.feature_id', 'me.cvterm_id'],
		as => ['feature_id', 'type_id']
	}
	);

my %categories;
$categories{'unclassified'} = {};


while (my $row = $amrGeneResutls->next) {
	$categories{'unclassified'}->{$row->get_column('type_id')} = [] unless exists $categories{'unclassified'}->{$row->get_column('type_id')};
	push(@{$categories{'unclassified'}->{$row->get_column('type_id')}}, $row->get_column('feature_id'));
	$unclassifiedIds{$row->get_column('type_id')} = undef;
}

#while (keys {%$categories{'unclassified'}}) != 0) {
# 	##Find the parent
# }

sub FindParent {
	##Key is to only remove the key if the parent_id is "process or component of antibiotic biology or chemistry"
	my $unclassifiedIds = shift;
}

my @wantedCategories = (
	'antibiotic molecule',
	'determinant of antibiotic resistance',
	'antibiotic target'
	);

my %categoryIds;
getCategoryIds(\@wantedCategories);

sub getCategoryIds {
	my $wantedCategories = shift;
	my $categoryResults = $schema->resultset('Cvterm')->search(
		{'dbxref.accession' => '1000001', 'subject.name' => $wantedCategories},
		{
			join => [
			'dbxref',
			{'cvterm_relationship_objects' => {'subject' => [{'cvterm_relationship_objects' => 'subject'}, 'dbxref']}}
			],
			select => ['me.dbxref_id', 'subject.cvterm_id', 'subject.name', 'subject_2.cvterm_id', 'subject_2.name', 'dbxref_2.accession'],
			as => ['parent_dbxref_id', 'broad_category_id', 'broad_category_name', 'refined_category_id', 'refined_category_name', 'accession']
		}
		);

	while (my $row = $categoryResults->next) {
		my %subcategory;
		$subcategory{'cvterm_id'} = $row->get_column('refined_category_id');
		$subcategory{'genes'} = {};
		$categories{$row->get_column('broad_category_name')}->{'subcategories'} = {} unless exists $categories{$row->get_column('broad_category_name')}->{'subcategories'};
		$categories{$row->get_column('broad_category_name')}->{'subcategories'}->{$row->get_column('refined_category_name')} = \%subcategory;
		$categories{$row->get_column('broad_category_name')}->{'parent_id'} = $row->get_column('broad_category_id');
		$categoryIds{$row->get_column('refined_category_id')} = undef;
	}
}

foreach my $x (keys %categories) {
	print "$x: \n" . join("\t", keys %{$categories{$x}}) . "\n\n";
}

print scalar(keys %unclassifiedIds) . "\n";
print scalar(keys %categoryIds) . "\n";