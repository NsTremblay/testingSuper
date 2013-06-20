#!/usr/bin/perl

use strict;
use warnings;
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
	my $configLocation = "$FindBin::Bin/../Modules/chado_upload_test.cfg";
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
