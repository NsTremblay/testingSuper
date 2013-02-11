#!/usr/bin/perl

use strict;
use warnings;
use IO::File;

# A test script to run the Bio::Perl command gmod_fasta2gff3.pl and tag attributes to each fasta entry
# 	This will allow for more information to be documented in the fasta file so more tags can be 
#	populated once its loaded into the chado database.


# We can create a hash table with the attributes that we want to have tagged in with the fasta file.

my %attributes;
my $filename = $ARGV[0];

_readInAttributes();

#my $attributes = '"organism=Escherichia coli;serotype=O157:H7"';

####Do not modify anything past this line####

#my $attributes = _addAttributes(%attributes);

#my @args = ("gmod_fasta2gff3.pl" . " --attributes " . $attributes);

#system(@args) == 0 or die "System with @args failed: $? \n";
#printf "System executed @args with value %d\n" , $? >> 8;


sub _readInAttributes {
	my $newFH = IO::File->new('<' . $filename)	or die "$!\n";
	while(my $line = $newFH->getline) {
		#Assign the key-val pair into the hash table.
		_setKeyVal($line);
	}
}

sub _printAttributes{
for (keys %attributes) {
	print "$_ = $attributes{$_}\n"; 
	}
}

sub _setKeyVal {
	my $line = shift;
	if ($line =~ /(^[\w]+)\t(\w+)/m){
		#Still a work in progress
		print "$1=$2\n";
	}
}