#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use IO::File;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use File::Basename;
use Config::Simple;
use Carp qw/croak carp/;
use DBI;

=head1 NAME

$0 - Processes a fasta file of pangenome sequence fragments and uploads into the feature table of the database specified in the config file.

=head1 SYNOPSIS
	
	% genodo_pangenome_bulk_loader.pl [options]

=head1 COMMAND-LINE OPTIONS

	--panseq_file		Specify a panseq multifasta (.fasta) file
	--config 			Specify a valid config file with db connection params.

=head1 DESCRIPTION

Perl script to process and upload a .fasta file of pangenome fragments into the feature table of the database speicified in the config file.

For each sequence in the file the script will parse the fasta headers of the form >lcl|1000000001|lcl|public_100112|public_100263_(1..202)
to obtain the panseq_id : 1000000001 and the panseq_name: public_100112|public_100263_(1..202) and will process the data into the right format for
the feature table in the database. After sequences are properly formated, data is bulk copied into the database. 

NOTE: This script should only be run to upload pangenome sequences for the first time into the database. 
It will not check if the sequences are already present in the database.

=head1 AUTHOR

Akiff Manji

=cut

my ($panseqFile, $CONFIGFILE);

GetOptions(
	'panseq_file=s' => \$panseqFile,
	'config=s' => \$CONFIGFILE
	) or ( system( 'pod2text', $0 ), exit -1 );

croak "Missing argument. You must supply a panseq fasta file\n" . system('pod2text', $0) unless $panseqFile;
croak "Missing argument. You must supply a valid config file\n" . system('pod2text', $0) unless $CONFIGFILE;

#db connection params
my ($dbname, $dbuser, $dbpass, $dbhost, $dbport, $DBI, $TMPDIR);

if(my $db_conf = new Config::Simple($CONFIGFILE)) {
	$dbname    = $db_conf->param('db.name');
	$dbuser    = $db_conf->param('db.user');
	$dbpass    = $db_conf->param('db.pass');
	$dbhost    = $db_conf->param('db.host');
	$dbport    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
	$TMPDIR    = $db_conf->param('tmp.dir');
} 
else {
	die Config::Simple->error();
}

die "Invalid configuration file." unless $dbname;

my $dbh = DBI->connect(
	"dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
	$dbuser,
	$dbpass,
	{AutoCommit => 0, TraceLevel => 0}
	) or die "Unable to connect to database: " . DBI->errstr;

my $cvterm_id = getpangenomeTypeId();
die "Invalid cvterm_id." unless $cvterm_id;

my $formattedTable = "$FindBin::Bin/panseqFeatureTable.txt";
open my $panseqFeatureTable, '>', $formattedTable or die "$!";

readInHeaders();
copyToDatabase($formattedTable);
unlink($formattedTable);

sub readInHeaders {
	my $in = Bio::SeqIO->new(-file => "$panseqFile", -format => 'fasta');
	my $out;
	my $panSeqNum = 0;
	while (my $seq = $in->next_seq()) {
		$panSeqNum++;
		my ($fragmentID, $fragmentName) = parseFragmentId($seq->id);
		next if $fragmentID eq "" || !defined($fragmentID);
		my $fragseq = $seq->seq;
		my $seqLength = $seq->length;
		writeOutFeatureTableFormat($fragmentID, $fragmentName, $fragseq, $seqLength, $cvterm_id, $panseqFeatureTable);
	}
	print $panseqFeatureTable "\\.\n\n";
	$panseqFeatureTable->autoflush;
	close $panseqFeatureTable;
}

sub parseFragmentId {
	my $seqHeader = shift;
	my ($fragId, $fragName) = "";
	$fragId = $1 if $seqHeader =~ /lcl\|([\d]*)\|/;
	$fragName = $1 if $seqHeader =~ /\|lcl\|(.*)/;
	return ($fragId, $fragName);
}

sub getpangenomeTypeId {
	my $sth = $dbh->prepare('SELECT cvterm_id FROM cvterm WHERE name = ?')
	or die "Couldn't prepare statement: " . $dbh->errstr;
	my $cvType = "pangenome";
	$sth->execute($cvType) or die "Couldn't execute statement: " . $sth->errstr;
	my $_cvterm_id;
	while (my @data = $sth->fetchrow_array()) {
		$_cvterm_id = $data[0];
	}
	return $_cvterm_id;
}

sub writeOutFeatureTableFormat {
	my ($panseqId, $panseqName, $panseq, $panseqLength, $cvterm_id, $fh) = @_;
	print $fh "13\t$panseqName\t$panseqId\t$panseq\t$panseqLength\t$cvterm_id\ttrue\n" or die "Couldn't write to file: $!";
}

sub copyToDatabase {
	my $_formattedTable = shift;

	$dbh->do('COPY feature(organism_id, name, uniquename, residues, seqlen, type_id, is_analysis) FROM STDIN');

	open my $fh, '<', $_formattedTable or die "Cannot open $_formattedTable: $!";
	seek($fh, 0, 0);

	while (<$fh>) {
		if (! ($dbh->pg_putcopydata($_))) {
			$dbh->pg_putcopyend;
			$dbh->rollback;
			$dbh->disconnect;
			die "Error calling pg_putcopydata: $!"; 
		}
	}
	print "pg_putcopydata completed successfully";
	$dbh->pg_putcopyend() or die "Error calling pg_putcopyend: $!";
	$dbh->commit;
	$dbh->disconnect;
}