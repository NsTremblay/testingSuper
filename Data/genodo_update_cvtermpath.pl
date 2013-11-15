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

my $geneResults = $schema->resultset('FeatureCvterm')->search(
	{'feature.type_id' => $id},
	{
		join => [{'cvterm' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => {'object' => {'cvterm_relationship_subjects' => 'object'}}}}}}}}}}}}}}, 'feature'],
		#select => ['me.feature_id','cvterm.name', 'me.cvterm_id', 'cvterm.name' , 'cvterm_relationship_subjects.object_id', 'object_7.name'],
		#as => ['gene_id', 'type_name', 'gene_cvterm_id', 'gene_cvterm_name', 'cvterm_parent_id', 'cvterm_parent_name']
	}
	);

my %ontologyTree = $geneResults->all;
# while (my $row = $geneResults->next) {
# 	$ontologyTree{$row->get_column('cvterm_parent_name')} = [] unless exists $ontologyTree{$row->get_column('cvterm_parent_name')};
# 	#$ontologyTree{$row->get_column('gene_cvterm_name')} = [] unless exists $ontologyTree{$row->get_column('gene_cvterm_name')};
# 	#push(@{$ontologyTree{$row->get_column('gene_cvterm_name')}}, $row->get_column('gene_id'));
# }

foreach my $keys (keys %ontologyTree) {
	foreach my $subkeys (keys %{$ontologyTree{$keys}}) {
		print $subkeys . "\n";
	}
}
print scalar(keys %ontologyTree) . "\n";
