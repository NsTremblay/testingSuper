#!/usr/bin/perl

use strict;
use warnings;
use IO::File;

my $attributes;
my $filename = $ARGV[0];

sub main {
_readInAttributes();
####Do not modify anything past this line####
#my $attributes = _addAttributes(%attributes);
my @args = ("gmod_fasta2gff3.pl" . " --attributes " . $attributes);
system(@args) == 0 or die "System with @args failed: $? \n";
printf "System executed @args with value %d\n" , $? >> 8;
}

sub _readInAttributes {
	my $newFH = IO::File->new('<' . $filename)	or die "$!\n";
	while(my $line = $newFH->getline) {
		_appendAttributes($line);
	}
}

# sub _printAttributes{
# for (keys %attributes) {
# 	print "$_ = $attributes{$_}\n"; 
# 	}
# }

sub _setKeyVal {
	my $line = shift;
	if ($line =~ /(^[\w]+)\t(([\w]+;?[^\n]+))/m) {
		print "$1=$2\n";
	}
}

sub _appendAttributes {
	my $line = shift;
	if ($line =~ /(^[\w]+)\t(([\w]+;?[^\n]+))/m) {
		my $attributes = "$1=$2";
	}
}