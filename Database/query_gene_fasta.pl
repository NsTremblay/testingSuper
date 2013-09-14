#!/usr/bin/env perl 
use strict;
use warnings;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Carp qw/croak carp/;
use Config::Simple;


=head1 NAME

$0 - Downloads all Antimicrobial Resistance Gene sequences from the db into a single multi-fasta file. 

=head1 SYNOPSIS

  % query_gene_fasta.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --config         Specify a .conf containing DB connection parameters.
 --output         Specify an output fasta file.

=head1 DESCRIPTION

Script to download all Antimicrobial Resistance Gene sequences from the database to a single multi-fasta file, 
to use for generating vir/amr data and the phylogenetic tree, etc.

Sequences will have the tag:
>feature_id|<uniquename>

=head1 AUTHOR

Akiff Manji, Matt Whiteside

=cut

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI, $OUTPUT);

GetOptions(
	'config=s'  => \$CONFIG,
	'output=s'	=> \$OUTPUT,
) or ( system( 'pod2text', $0 ), exit -1 );

# Connect to DB
croak "Missing argument. You must supply a configuration filename.\n" . system ('pod2text', $0) unless $CONFIG;
croak "Missing argument. You must supply an output directory.\n" . system ('pod2text', $0) unless $OUTPUT;
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

# Obtain all query genes
my $query_gene_rs = $schema->resultset('Feature')->search(
	{
        'type.name' => "antimicrobial_resistance_gene"
	},
	{
		column  => [qw/feature_id uniquename residues/],
		join    => ['type'],
	}
);

# Write to FASTA file
open(my $out, ">", $OUTPUT) or die "Error: unable to write to file $OUTPUT ($!)\n";

while (my $gene = $query_gene_rs->next) {
	print $out '>' . $gene->feature_id . '|' . $gene->uniquename . "\n" . $gene->residues . "\n\n";
}

close $out;