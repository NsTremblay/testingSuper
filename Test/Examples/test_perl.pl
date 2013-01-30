#!usr/bin/perl

#A simple perl script to write to a file;

use strict; #This pragma introduces strictures to make Perl less permissive
use warnings;
use Path::Class;
use autodie; 

my $dir = dir("/tmp"); # tmp directory
my $file = $dir->file("file.txt"); # tmp/file.txt

#Now to read in the entire contents of a file

my $content = $file->slurp();

my $file_handle = $file->openr();

while( my $line = $file_handle->getline() ) {
	print $line;
}
