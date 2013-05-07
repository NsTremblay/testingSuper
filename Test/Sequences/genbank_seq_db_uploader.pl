#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;

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

parseGenome();

sub parseGenome {
	opendir('' , $directoryName) or die "Couldn't open directory $directoryName , $!\n";

	system("mkdir $directoryName/fastaTemp") == 0 or die "System with args failed: $?";
	system("mkdir $directoryName/gffsTemp") == 0 or die "System with args failed: $?";
	system("mkdir $directoryName/gffsToUpload") == 0 or die "System with args failed: $?";

	while (my $file = readdir '')
	{
		print "$file\n";
		if ($file eq "." || $file eq ".." || $file eq "fastaTemp" || $file eq "gffsTemp" || $file eq "gffsToUpload"){
		}
		else {
			readInHeaders($file);
		}
	}
	system("rm -r $directoryName/fastaTemp") == 0 or die "System with args failed: $?";
	#system("rm -r $directoryName/gffsTemp") == 0 or die "System with args failed: $?";
	system("rm -r $directoryName/gffsToUpload") == 0 or die "System with args failed: $?";

	closedir '';
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
		die "No header found! Killing upload: $!\n"
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
	my $appendArgs = "gmod_fasta2gff3.pl --type contig --attributes \"$attributes\" --gfffilename $directoryName/gffsTemp/out$fileNumber.gff --fasta_dir $directoryName/fastaTemp/";
	system($appendArgs) == 0 or die "System failed with  $appendArgs: $? \n";
	printf "System executed $appendArgs with value %d\n" , $? >> 8;
	unlink "$directoryName/fastaTemp/directory.index";
	unlink "$fastaFileName";
	#system("rm -r $directoryName/fastaTemp/$fastaFileName") == 0 or die "System with args failed: $?";
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
		#print "My tag name: $tagName\n";
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
		else{
			$newName = $originalName;
		}
		$newName =~ s/Escherichia coli//;
		$newName =~ s/,//g;
		$newName =~ s/'//g;
		$newName =~ s/'//g;
		$newName =~ s/str/Str/;
		return $newName;
	}
