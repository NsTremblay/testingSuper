#!/usr/bin/perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Carp qw/croak carp/;
use Config::Simple;

=head1 NAME

$0 - Upload AMR genes and associated meta-data from CARD

=head1 SYNOPSIS

  % ar_genes_db_uploader [options] 

=head1 COMMAND-LINE OPTIONS

 --config         Specify a .conf containing DB connection parameters.
 --fasta          AMR fasta file from the CARD download page.

=head1 DESCRIPTION

This script creates feature entries in the CHADO db for antimicrobial resistance
genes defined by the CARD database. Requires that the Antimicrobial resistance
ontology from the CARD db has been previously loaded (See script ../Database/genodod_add_aro.sh).

=head1 AUTHOR

Matt Whiteside E<lt>mawhites@phac-aspc.gov.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI, $FASTAFILE);

GetOptions(
    'config=s'      => \$CONFIG,
    'fasta=s'       => \$FASTAFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

croak "ERROR: Missing argument. You must supply a configuration filename.\n" . system ('pod2text', $0) unless $CONFIG;
croak "ERROR: Missing argument. You must supply a fasta filename.\n" . system ('pod2text', $0) unless $FASTAFILE;

# Connect to DB and gen schema object
if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
} else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . ':dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS) or croak "ERROR: Could not connect to database.";

# Add/check dummy organism
my $default_organism_row = $schema->resultset('Organism')->find_or_create(
	{
		genus => 'Unclassifed',
		species => 'Unclassifed',
		comment => 'A place-holder organism entry to represent features with no associated organism'
	},
	{
		key => 'organism_c1'
	}
);
my $organism_id = $default_organism_row->organism_id;

# Retrieve common cvterm IDs
# hash: name => cv
my %fp_types = (
	description => 'feature_property',
	synonym => 'feature_property',
	antimicrobial_resistance_gene => 'local',
	source_organism => 'local',
	publication => 'local',
);

my %cvterm_ids;
foreach my $type (keys %fp_types) {
	my $cv = $fp_types{$type};
	my $type_rs = $schema->resultset('Cvterm')->search(
		{
			'me.name' => $type,
			'cv.name' => $cv
		},
		{
			join => 'cv',
			columns => qw/cvterm_id/
		}
	);
	my $type_row = $type_rs->first;
	croak "Featureprop cvterm type $type not in database." unless $type_row;
	my ($cvterm_id) = $type_row->cvterm_id;
	$cvterm_ids{$type} = $cvterm_id;
}

# Add/check required pub
my $default_pub_rs = $schema->resultset('Pub')->find_or_create(
	{
		uniquename => 'The Comprehensive Antibiotic Resistance Database',
		miniref => q|McArthur AG, et al. The comprehensive antibiotic
resistance database. Antimicrob Agents Chemother. 2013 Jul;57(7):3348-57. doi:
10.1128/AAC.00419-13. Epub 2013 May 6. PubMed PMID: 23650175; PubMed Central
PMCID: PMC3697360|,
		type_id => $cvterm_ids{publication},
	},
	{
		key => 'pub_c1'
	}
);
my $pub_id = $default_pub_rs->pub_id;

# Add/check required db
my $default_db_rs = $schema->resultset('Db')->find_or_create(
	{
		name => 'CARD',
		description => 'The Comprehensive Antibiotic Resistance Database',
	},
	{
		key => 'db_c1'
	}
);
my $db_id = $default_db_rs->db_id;

# Retrieve common dbs
my $db_row = $schema->resultset('Db')->find({ name => 'ARO'});
my $aro_db_id = $db_row->db_id;
croak "ERROR: Antimicrobial resistance ontology database (ARO) not found in db table.\n" unless $aro_db_id;


# Add AR genes in fasta file
my $in = Bio::SeqIO->new(-file   => $FASTAFILE,
                         -format => 'fasta');

my $num_proc=0;                             
while (my $entry = $in->next_seq) {
	
	# Attempt to load single sequence.
	# If it fails, load step for gene will be rolled back
	$schema->txn_do(\&load_gene, $entry);
	
	$num_proc++;
	print "$num_proc loaded\n" if $num_proc % 100 == 0;
	
}
print "$num_proc loaded\n";

sub load_gene {
	my ($fasta_seq) = @_;
	
	my $card_accession = $fasta_seq->display_id;
	
	# Parse header, isolating key segments
	my ($header, $organism) = ($fasta_seq->desc =~ m/^(.+) \[(.+)\]$/);
	$header =~ s/E\. col/E\.col/g;
	my @columns = split(/\. /, $header); # Hopefully this is safe, header delimiting is really poor (. appear in words too!)
	my @ontology_annos;
	my @synonyms;
	my @descriptions;
	my $name = shift @columns;
	
	# Check if sequence is in database
	my $uniquename = "$name ($card_accession)";
	
	unless($schema->resultset('Feature')->find({uniquename => $uniquename})) {
		
		# Parse rest of header
		while(my $col_entry = pop @columns) {
			if($col_entry =~ m/ARO\:/) {
				next if $col_entry =~ m/ARO:1000001/; # Don't need to record term as being a part of the ARO ontology
				push @ontology_annos, $col_entry;
			} elsif($col_entry =~ m/\s|QUINOLONE/ || length($col_entry) > 10) {
				# Descriptions are longer strings often with spaces
				# This is what we have to resort to due to a poor FASTA header specification
				push @descriptions, $col_entry;
				
			} else {
				push @synonyms, $col_entry;
			}
		}
		
		# Create/retrieve organism
		# Store this as a featureprop, there isnt a good
		# system in the organism table for storing strain info
		# which is essential for identifying bacteria.
		# Currently all AR gene organisms are stored as 'Unclassified'
		# but this should be safe as they should all have uniquenames
		# and unique accessions with no collisions between the different
		# 'Unclassified' species.
		
		# Create/retrieve dbxref
		my $dbxref = $schema->resultset('Dbxref')->find_or_create(
			{
				accession => $card_accession,
				version => '',
				db_id => $db_id
			},
			{
				key => 'dbxref_c1'
			}
		);
		
		# Create feature
		my $feature = $schema->resultset('Feature')->create(
			{
				organism_id => $organism_id,
				dbxref_id => $dbxref->dbxref_id,
				name => $name,
				uniquename => $uniquename,
				residues => $fasta_seq->seq(),
				seqlen => $fasta_seq->length(),
				type_id => $cvterm_ids{antimicrobial_resistance_gene}
			}
		);
		
		# Create feature_cvterms for ARO terms
		my $rank=0;
		foreach my $term (@ontology_annos) {
			my ($acc) = ($term =~ m/ARO\:(\d+)/);
			
			# find cvterm matching the ARO temr
			my $term_rs = $schema->resultset('Cvterm')->search(
				{
					'dbxref.accession' => $acc,
					'dbxref.db_id' => $aro_db_id,
				},
				{
					join => 'dbxref'
				}
			);
			
			my @matching = $term_rs->all;
			die "ERROR: ARO term ARO:$acc not found in dbxref table." unless @matching;
			die "ERROR: Multiple ARO terms matching ARO:$acc found in cvterm table." unless @matching == 1;
			
			my $term = shift @matching;
			
			$schema->resultset('FeatureCvterm')->create(
				{
					feature_id => $feature->feature_id,
					cvterm_id => $term->cvterm_id,
					pub_id => $pub_id,
					rank => $rank
				}
			);
			
			$rank++;
			
		}
		
		# Create featureprops
		
		# Add source organism property
		$schema->resultset('Featureprop')->create(
			{
				feature_id => $feature->feature_id,
				type_id => $cvterm_ids{source_organism},
				value => $organism,
				rank => 0
			}
		);
		
		# Add description properties
		$rank = 0;
		foreach my $d (@descriptions) {
			$schema->resultset('Featureprop')->create(
				{
					feature_id => $feature->feature_id,
					type_id => $cvterm_ids{description},
					value => $d,
					rank => $rank
				}
			);
			$rank++;
		}
		
		# Add synonym properties
		$rank = 0;
		foreach my $s (@synonyms) {
			$schema->resultset('Featureprop')->create(
				{
					feature_id => $feature->feature_id,
					type_id => $cvterm_ids{synonym},
					value => $s,
					rank => $rank
				}
			);
			$rank++;
		}
		
	}
	
}
=cut
# Feature property types associated with AMR genes
# save under local cv linked to Genodo DB

my $cv = $schema->resultset('Cv')->find({ name => 'local' });
my $cv_id = $cv->cv_id;
my $db_id = $schema->resultset('Db')->find({ name => 'Genodo' })->db_id;

unless($db_id) {
	croak "ERROR: Cannot find the default database Genodo.";
}
unless($cv) {
	croak "ERROR: Cannot find the default ontology local. ".
		" A local ontology should have been initialized during the CHADO DB installation.\n";
}

my @local_terms = qw/serotype strain isolation_host isolation_location isolation_date isolation_latlng
	syndrome severity isolation_source isolation_age pmid virulence_factor antimicrobial_resistance_gene/;
foreach my $term (@local_terms) {
	
	my $term_hash = {
			name => $term,
			cv_id => $cv_id,
			is_obsolete => 0,
			is_relationshiptype => 0,
			dbxref => {
				db_id => $db_id,
				accession => $term
			}
		};
	
	my $row = $schema->resultset('Cvterm')->find_or_new($term_hash, { key => 'cvterm_c1' });
	
	unless($row->in_storage) {
		print "Adding local ontology term $term\n";
		$row->insert;
	}
}




use IO::File;
use IO::Dir;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use File::Basename;


my $ARFile = $ARGV[0];
my $ARName;
my $ARNumber = 0;
my $ARFileName;

parseARFactors();

sub parseARFactors {
	system("mkdir ARFastaTemp") == 0 or die "Sytem with args failed: $?\n";
	system("mkdir ARgffsTemp") == 0 or die "Sytem with args failed: $?\n";
	system("mkdir ARgffsToUpload") == 0 or die "Sytem with args failed: $?\n";
	readInHeaders();
	aggregateGffs();
	uploadSequences();
	system("rm -r ARFastaTemp") == 0 or die "System with args failed: $?\n";
	system("rm -r ARgffsTemp") == 0 or die "System with args failed: $?\n";
	system("rm -r ARgffsToUpload") == 0 or die "System with args failed: $?\n";
	print $ARNumber . " AR genes have been parsed and uploaded to the database \n";
}

sub readInHeaders {
	my $in = Bio::SeqIO->new(-file => "$ARFile" , -format => 'fasta');
	my $out;
	while (my $seq = $in->next_seq()) {
		$ARFileName = "ARgene" . $seq->id . ".fasta";
		$ARNumber++;
		$out = Bio::SeqIO->new(-file => '>' . "ARFastaTemp/$ARFileName" , -format => 'fasta') or die "$!\n";
		$out->write_seq($seq) or die "$!\n";
		my $seqHeader = $seq->desc();
		my $attributeHeaders = parseHeader($seqHeader);
		appendAtrributes($attributeHeaders);
	}
}

sub parseHeader {
	#If you change these to say add more attibutes then you must alter the getAttributes() sub
	my $_seqHeader = shift;
	my %_seqHeaders;
	if ($_seqHeader =~ /(\[)([\w\d\W\D]*)(\])/) {
		my $organism = $2;
		$_seqHeaders{'ORGANISM'} = $organism;
	}
	else {
	}
	$_seqHeaders{'KEYWORDS'} = "Antimicrobial Resistance";
	$_seqHeader =~ s/\./,/g;
	$_seqHeader =~ s/(\[)([\w\d\W\D]*)(\])//g;
	$_seqHeaders{'DESCRIPTION'} = $_seqHeader;

	return \%_seqHeaders;
}

sub appendAtrributes {
	my $attHeaders = shift;
	my $attributes = getAttributes($attHeaders);
	my $args = "gmod_fasta2gff3.pl" . " $ARFileName" . " --type gene" . " --attributes " . "\"$attributes\"" . " --fasta_dir ARFastaTemp " . "--gfffilename ARgffsTemp/tempout$ARNumber.gff";
	system($args) == 0 or die "System with $args failed: $? \n";
	printf "System executed $args with value %d\n", $? >> 8;
	unlink "ARFastaTemp/$ARFileName";
	unlink "ARFastaTemp/directory.index";
}

sub getAttributes {
	#At this point the only attributes are organism, description and keywords
	my $_attHeaders = shift;
	my $_attributes = "organism=" . $_attHeaders->{ORGANISM} . ";" .
	"description=" . $_attHeaders->{DESCRIPTION} . ";" . 
	"keywords=" . $_attHeaders->{KEYWORDS} . ";" . 
	"biological_process=antimicrobial resistance";
	return $_attributes;
}

sub aggregateGffs {
	opendir (TEMP , "ARgffsTemp") or die "Couldn't open the directory ARgffsTemp , $!\n";
	while (my $file = readdir TEMP)
	{
		writeOutFile($file);
		unlink "ARgffsTemp/$file";
	}
	mergeFiles();
	closedir TEMP;
}

sub writeOutFile {
	my $file = shift;
	my $tempTagFile = "ARgffsToUpload/tempTagFile";
	my $tempSeqFile = "ARgffsToUpload/tempSeqFile";
	open my $in , '<' , "ARgffsTemp/$file" or die "Can't read $file: $!";
	open my $outTags, '>>' , $tempTagFile or die "Cant write to the $tempTagFile: $!";
	open my $outSeqs, '>>' , $tempSeqFile or die "Cant write to the $tempSeqFile: $!";
	#Need to print out line 3 and (5 + 6) specifically
	while (<$in>) {
		if ($. == 3) {
			print $outTags $_;
		}
		if ($. == 5 || $. == 6){
			print $outSeqs $_;
		}
		else{
		}
	}
	close $outTags;
	close $outSeqs;
}

sub mergeFiles {
	#Merge tempFiles into a single gff file.
	my $tempTagFile = "ARgffsToUpload/tempTagFile";
	my $tempSeqFile = "ARgffsToUpload/tempSeqFile";
	if ($tempTagFile && $tempSeqFile) {
		my $genomeFileName = "out.gff";
		open my $inTagFile, '<' , $tempTagFile or die "Can't read $tempTagFile: $!";
		open my $inSeqFile, '<' , $tempSeqFile or die "Can't read $tempSeqFile: $!";
		open my $out, '>>' , "ARgffsToUpload/$genomeFileName";
		while (my $line = <$inTagFile>) {
			print $out $line;
		}
		close $inTagFile;
		print $out "##FASTA\n";
		while (my $line = <$inSeqFile>) {
			print $out $line;
		}
		close $inSeqFile;
		close $out;
		unlink "$tempTagFile";
		unlink "$tempSeqFile";
	}
	else {
	}
}

sub uploadSequences {
	opendir (GFF , "ARgffsToUpload") or die "Couldn't open directory ARgffsToUpload , $!\n";
	my ($dbName , $dbUser , $dbPass) = hashConfigSettings();
	while (my $gffFile = readdir GFF) {
		if ($gffFile eq "." || $gffFile eq "..") {
		}
		else {
			my $dbArgs = "gmod_bulk_load_gff3.pl --dbname $dbName --dbuser $dbUser --dbPass $dbPass --organism \"Escherichia coli\" --gfffile ARgffsToUpload/$gffFile";
			system($dbArgs) == 0 or die "System failed with $dbArgs: $? \n";
			printf "System executed $dbArgs with value %d\n", $? >> 8;
		}
	}
	closedir GFF;
}

sub hashConfigSettings {
	my $configLocation = "$FindBin::Bin/../Modules/chado_db_test.cfg";
	open my $in, '<' , $configLocation or die "Cannot open $configLocation: $!\n";
	my ($dbName , $dbUser , $dbPass);
	while (my $confLine = <$in>) {
		if ($confLine =~ /name = ([\w\d]*)/){
			$dbName = $1;
			next;
		}
		if ($confLine =~ /user = ([\w\d]*)/){
			$dbUser = $1;
			next;
		}
		if ($confLine =~ /pass = ([\w\d]*)/){
			$dbPass = $1;
			next;
		}
		else{
		}
	}
	return ($dbName , $dbUser , $dbPass);
}
=cut