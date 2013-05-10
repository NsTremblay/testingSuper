#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use File::Basename;

#A database loader for downloaded Genbank sequences.
#gmod_fasta2gff3.pl included with Bio::Perl will automatically use the gi/gb tag as a sequence unique identifier for each contig of a multi fasta file.

#The very first fasta header is parsed for the genome name.
#This name is uploaded to the db in the feature table as a contig_collection (Parent).

#The contigs of the genome are related to the contig_collection by tagging it as its Parent when converting from fasta to gff

#The relationships indicating that a contig is part_of a contig_collection is stored in the feature_relationship table.

#contig_collection vs contig are distinguished from eachother in the feature table through a different type_id.

#We also want to store property attributes with each of the contigs such as if they are plasmids or not and their privacy level:
	# description: Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence
	# privacy: Public (by defualt these are public becuse they are not specific to a user)
	# keywords: Genome Sequence
	# mol_type: dna/plasmid

# This method of storage will provide the capability to enter in additional information about the genome, if needed at a later time.

my $directoryName = $ARGV[0];

#This is set globally after parsing the first fasta header
my $genomeName;
my $genomeNumber = 0;

parseGenome();

sub parseGenome {
	opendir(GENOMEDIR , $directoryName) or die "Couldn't open directory $directoryName , $!\n";
	system("mkdir $directoryName/fastaTemp") == 0 or die "System with args failed: $?";
	system("mkdir $directoryName/gffsTemp") == 0 or die "System with args failed: $?";
	system("mkdir $directoryName/gffsToUpload") == 0 or die "System with args failed: $?";
	while (my $file = readdir GENOMEDIR)
	{
		print "$file\n";
		if ($file eq "." || $file eq ".." || $file eq "fastaTemp" || $file eq "gffsTemp" || $file eq "gffsToUpload"){
		}
		else {
			$genomeNumber++;
			readInHeaders($file);
			aggregateGffs();
		}
	}	
	uploadSequences();
	system("rm -r $directoryName/fastaTemp") == 0 or die "System with args failed: $?";
	system("rm -r $directoryName/gffsTemp") == 0 or die "System with args failed: $?";
	system("rm -r $directoryName/gffsToUpload") == 0 or die "System with args failed: $?";
	closedir GENOMEDIR;
}

sub readInHeaders {
	my $file = shift;
	my $in = Bio::SeqIO->new(-file => "$directoryName/$file" , -format => 'fasta');
	my $fileNumber = 0;
	my $firstHeader = $in->next_seq();
	if ($firstHeader) {
		$fileNumber++;
		setGenomeName($firstHeader , $fileNumber);
		while (my $seq = $in->next_seq()) {
			$fileNumber++;
			appendAttributes($seq , $fileNumber);
		}
	}
	else {
		#No sequence found, so it breaks to the next file
		next;
	}
}

sub setGenomeName {
	my $firstSeq = shift;
	my $fileNumber = shift;
	$genomeName = parseName($firstSeq);
	print "$genomeName\n";
	appendAttributes($firstSeq , $fileNumber);
}

sub appendAttributes {
	my $fastaSeq = shift;
	my $fileNumber = shift;
	my $fastaId = $fastaSeq->id;
	my $fastaDescription = $fastaSeq->desc;
	my $fastaFileName = "$directoryName/fastaTemp/fasta$fileNumber.fasta";
	my $fastaFile = Bio::SeqIO->new(-file => '>' . "$fastaFileName" , -format => 'fasta') or die "$!\n";
	$fastaFile->write_seq($fastaSeq) or die "$!\n";
	my $mol_type;
	if ($fastaDescription =~ /(P|p)lasmid/) {
		$mol_type = "plasmid";
	}
	else {
		$mol_type = "dna";
	}
	my $attributes = "description=$fastaDescription;keywords=Genome Sequence;mol_type=$mol_type;Parent=$genomeName";
	my $appendArgs = "gmod_fasta2gff3.pl --type contig --attributes \"$attributes\" --gfffilename $directoryName/gffsTemp/tempout$fileNumber.gff --fasta_dir $directoryName/fastaTemp/";
	system($appendArgs) == 0 or die "System failed with  $appendArgs: $? \n";
	printf "System executed $appendArgs with value %d\n" , $? >> 8;
	unlink "$directoryName/fastaTemp/directory.index";
	unlink "$fastaFileName";
}

sub parseName {
	#$_singleFileName is the seq->id of the first header.
	my $_fastaHeader = shift;
	my $_singleFileName = $_fastaHeader->id;
	my $_singleFileDescription = $_fastaHeader->desc;
	my $tagName;
	if ($_singleFileName =~ /(|gb|)([A-Z][A-Z][A-Z][A-Z])/){
		$tagName = $2;
	}
	else{
		$tagName = "";
	}
	my $newName;
	my $originalName = $_singleFileDescription;
	if ($originalName =~ /(Escherichia coli)([\w\d\W\D]*)(,)?(complete)/){
		$newName = $2;
	}
	elsif($originalName =~ /(Escherichia coli)([\w\d\W\D]*)(WGS)/){
		$newName = "$tagName -$2";
	}
	elsif ($originalName =~ /(Escherichia coli)([\w\d\W\D]*)\s([\w\d\W\D]*)(,)/) {
		$newName = $2;
		if ($newName eq "") {
			$newName = "$tagName -$3";
		}
		else {
			$newName = "$tagName -$2";
		}
	}
	elsif($originalName =~ m/name=\|(\w+)\|/){
		$newName = $1;
	}
	elsif($originalName =~ m/lcl\|([\w-]*)\|/){
		$newName = $1;
	}
	elsif($originalName =~ m/(ref\|\w\w_\w\w\w\w\w\w|gb\|\w\w\w\w\w\w\w\w|emb\|\w\w\w\w\w\w\w\w|dbj\|\w\w\w\w\w\w\w\w)/){
		$newName = $1;
	}
	elsif($originalName =~ m/(gi\|\d+)\|/){
		$newName = $1;
	}
	elsif($originalName =~ m/^(.+)\|Segment=/){
		$newName = $1;
	}
	elsif($originalName =~ m/^(.+)\|Length=/){
		$newName = $1;
	} else {
		$newName = $originalName;
	}
	$newName =~ s/Escherichia coli//;
	$newName =~ s/,//g;
	$newName =~ s/'//g;
	$newName =~ s/'//g;
	$newName =~ s/str/Str/;
	return $newName;
}

sub aggregateGffs {
	opendir (TEMP , "$directoryName/gffsTemp/") or die "Couldn't open directory $directoryName/gffsTemp/ , $!\n";
	while (my $file = readdir TEMP)
	{
		writeOutFile($file);
		unlink "$directoryName/gffsTemp/$file";
	}
	mergeFiles();
	closedir TEMP;
}

sub writeOutFile {
	my $file = shift;
	my $tempTagFile = "$directoryName/gffsToUpload/tempTagFile";
	my $tempSeqFile = "$directoryName/gffsToUpload/tempSeqFile";
	open my $in, '<' , "$directoryName/gffsTemp/$file" or die "Can't read $file: $!";
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
	return ($tempTagFile , $tempSeqFile);
}

sub mergeFiles {
	#Merge tempFiles into a single gff file and append the parent name to the file.
	my $tempTagFile = "$directoryName/gffsToUpload/tempTagFile";
	my $tempSeqFile = "$directoryName/gffsToUpload/tempSeqFile";
	if ($tempTagFile && $tempSeqFile) {
		my $genomeFileName = "out$genomeNumber.gff";
		open my $inTagFile, '<' , $tempTagFile or die "Can't read $tempTagFile: $!";
		open my $inSeqFile, '<' , $tempSeqFile or die "Can't read $tempSeqFile: $!";
		open my $out, '>>' , "$directoryName/gffsToUpload/$genomeFileName";
		print $out "$genomeName	.	contig_collection	.	.	.	.	.	ID=$genomeName;Name=$genomeName\n";
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
	opendir (GFF , "$directoryName/gffsToUpload") or die "Couldn't open directory $directoryName/gffsToUpload , $!\n";
	my ($dbName , $dbUser , $dbPass) = hashConfigSettings();
	while (my $gffFile = readdir GFF) {
		if ($gffFile eq "." || $gffFile eq "..") {
		}
		else {
			my $dbArgs = "gmod_bulk_load_gff3.pl --dbname $dbName --dbuser $dbUser --dbPass $dbPass --organism \"Escherichia coli\" --gfffile $directoryName/gffsToUpload/$gffFile";
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
