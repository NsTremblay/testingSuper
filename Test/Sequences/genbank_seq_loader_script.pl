#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;

#A simple loader that will extract the genome name from a multi fasta file and upload it to the database.
#To keep it simple well just extract the gi/gb name as its unique identifier and store the rest as a description.
#Each file is associated with a number so we know which genomes the features belong to. 
#We'll store the genome number in the  attribute member_of.

#An example of a fasta header of a single genome file:
#>gi|190904743|gb|AAJT02000001.1| Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence

#This will be parsed and uploaded into the feature table:
	# ID: gi|190904743|gb|AAJT02000001.1|
	#Name: gi|190904743|gb|AAJT02000001.1|
	#Uniquename: gi|190904743|gb|AAJT02000001.1|-<feature_id>

#Along with the following atrtributes in the featureprop table:
	# description: Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence
	# organism: Escherichia coli
	# keywords: Genome Sequence
	# member_of: <genome number>

my $directoryName = $ARGV[0];
my $fileNumber = -2;
parseSequences();

sub parseSequences {
opendir('' , $directoryName) or die "Couldn't open directory $directoryName , $!\n";
while (my $file = readdir '')
{
	print "$file\n";
	$fileNumber++;
	readInHeaders($file);
	print "$fileNumber\n";
}
closedir '';
}

sub readInHeaders{
	my $file = shift;
	my $in = Bio::SeqIO->new(-file => "$directoryName/" . $file, -format => 'fasta'); 

	while(my $seq = $in->next_seq() ) {
		#print "ID: " . $seq->id . "\n";
		#print "Description: " . $seq->desc . "\n";
	}
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
