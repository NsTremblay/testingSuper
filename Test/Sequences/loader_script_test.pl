#!/usr/bin/perl

use strict;
use warnings;
use IO::File;

#NOTE: This code works, but is still buggy and needs to be tightened up and tested thoroughly before using in production.
#       See the accompanying readme for instructions on how to use this script.

my $filename = $ARGV[0];
my $attributes = "";
main();

sub main {
        _readInAttributes();
####Do not modify anything past this line####
my @args = ("gmod_fasta2gff3.pl" . " --attributes " . '"'.$attributes.'"');
system(@args) == 0 or die "System with @args failed: $? \n";
printf "System executed @args with value %d\n", $? >> 8;
}

sub _readInAttributes {
        my $newFH = IO::File->new('<' . $filename)      or die "$!\n";
        while(my $line = $newFH->getline) {
                #_setKeyVal($line);
                _appendAttributes($line);
        }
}

# sub _setKeyVal {
#       my $line = shift;
#       if ($line =~ /(^[\w]+)\t(([\w]+;?[^\n]+))/m) {
#               #create key val hash pairs
#               print "$1=$2";
#       }
# }

sub _appendAttributes {
        my $line = shift;
        if ($line =~ /(^[\w]+)\t(([\w]+;?[^\n]+))/s) {
                $attributes = "$attributes". "$1=$2" . ";" ;
        }
}
