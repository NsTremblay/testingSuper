#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use File::Basename;
use Config::Simple;
use DBI;

my $panseqFile = $ARGV[0];

##This script needs to be changed. Should be used to upload only newly found panseq fragments.

#db connection params
my $CONFIGFILE = "$FindBin::Bin/../Modules/genodo.cfg";
die "Unable to locate config file, or does not exist at specified location." unless $CONFIGFILE;

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

readInHeaders();

sub readInHeaders {
	my $in = Bio::SeqIO->new(-file => "$panseqFile", -format => 'fasta');
	my $out;
	my $panSeqNum = 0;
	open my $panseqFeatureTable, '>', "$FindBin::Bin/panseqFeatureTable.txt" or die "$!";
	while (my $seq = $in->next_seq()) {
		$panSeqNum++;
		my ($fragmentID, $fragmentName) = parseFragmentId($seq->id);
		next if $fragmentID eq "" || !defined($fragmentID);
		my $fragseq = $seq->seq;
		my $seqLength = $seq->length;
		writeOutFeatureTableFormat($fragmentID, $fragmentName, $fragseq, $seqLength, $cvterm_id, $panseqFeatureTable);
	}
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
	print $fh "\t\t13\t$panseqName\t$panseqId\t$panseq\t$panseqLength\t\t$cvterm_id\ttrue\t\t\t\n" or die "Couldn't write to file: $!";
}