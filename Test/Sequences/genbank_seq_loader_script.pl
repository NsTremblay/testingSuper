#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;

#A database loader for downloaded Genbank sequences.
#gmod_fasta2gff3.pl included with Bio::Perl will automatically use the gi/gb tag as a sequence unique identifier.
#The remainder of the fasta header will be appended as an attirbute to the features as they are loaded.
#Each sequences file is associated with a number to identify what genome the uploaded features belong to. 
#We'll store the genome number unsing the attribute 'member_of'.

#An example of a fasta header of a single genome file:
#>gi|190904743|gb|AAJT02000001.1| Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence

#This will be parsed and uploaded into the feature table automatically when gmod_fasta2gff3.pl is called:
	# ID: gi|190904743|gb|AAJT02000001.1|
	#Name: gi|190904743|gb|AAJT02000001.1|
	#Uniquename: gi|190904743|gb|AAJT02000001.1|-<feature_id>

#Along with the following atrtributes in the featureprop table:
	# description: Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence
	# organism: Escherichia coli
	# keywords: Genome Sequence
	# member_of: <genome number>

	my $directoryName = $ARGV[0];
	my $fileNumber = 0;
	my $genomeNumber;
	parseSequences();

	sub parseSequences {
		opendir('' , $directoryName) or die "Couldn't open directory $directoryName , $!\n";
		while (my $file = readdir '')
		{
			print "$file\n";
			if ($file eq "." || $file eq ".."){
			}
			else {
				$fileNumber++;
				moveToFastaFolder($file);
				readInHeaders($file);
				#print "$fileNumber\n";
				#print "$genomeNumber\n";
			}
		}
		closedir '';
	}

	sub moveToFastaFolder {
		my $file = shift;
		if ($file eq "." || $file eq ".."){
		}
		else {
			my $mvArgs = "cp " . "$directoryName/" . "$file" . " fasta/";
			system($mvArgs) == 0 or die "System with $mvArgs failed: $? \n";
			printf "System executed $mvArgs with value %d\n" , $? >> 8;
		}
	}

	sub readInHeaders {
		my $file = shift;
		#my $in = Bio::SeqIO->new(-file => "fasta/" . $file, -format => 'fasta');
		my $in = Bio::SeqIO->new(-file => "$directoryName/" . $file, -format => 'fasta'); 

		while(my $seq = $in->next_seq()) {
			#print "ID: " . $seq->id . "\n";
			#print "Description: " . $seq->desc . "\n";
			appendAtrributes($seq);
		}
	}

	sub  appendAtrributes {
		my $seq = shift;
		my $description = $seq->desc();
		my $keywords = "keywords";
		$genomeNumber  = $fileNumber;
		#print "Description: " . $description . "\n";
		#print "Genome Number: " . $genomeNumber . "\n";
	}

#Parser used for Panseq. 
# sub _getName{
# 	my $self =shift;
# 	my $originalName=shift;

# 	my $newName;
# 	if($originalName =~ m/name=\|(\w+)\|/){
# 		$newName = $1;
# 	}
# 	elsif($originalName =~ m/lcl\|([\w-]*)\|/){
# 		$newName = $1;
# 	}
# 	elsif($originalName =~ m/(ref\|\w\w_\w\w\w\w\w\w|gb\|\w\w\w\w\w\w\w\w|emb\|\w\w\w\w\w\w\w\w|dbj\|\w\w\w\w\w\w\w\w)/){
# 		$newName = $1;
# 	}
# 	elsif($originalName =~ m/(gi\|\d+)\|/){
# 		$newName = $1;
# 	}
# 	elsif($originalName =~ m/^(.+)\|Segment=/){
# 		$newName = $1;
# 	}
# 	elsif($originalName =~ m/^(.+)\|Length=/){
# 		$newName = $1;
# 	}
# 	else{
# 		$newName = $originalName;
# 	}
# 	print $newName;
# }
