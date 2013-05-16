#!/usr/bin/perl

use strict;
use warnings;

use IO::File;
use IO::Dir;
use Bio::SeqIO;

#Test appending line to a file

#For example:

##gff-version 3
#this file generated from /usr/local/bin/gmod_fasta2gff3.pl
# -> Want to insert line here. (Line#3)
#gi|190900051|gb|AAJT02000289.1|	.	contig	1	1009	.	.	.	ID=gi|190900051|gb|AAJT02000289.1|;Name=gi|190900051|gb|AAJT02000289.1|;Parent=AAJT

my $fileName = 'out.gff';

open my $in, '<', $fileName or die "Cant read the file: $!";
open my $out, '>', "$fileName.new" or die "Cant write to the file: $!";

while (<$in>) {
	print $out $_;
	last if $. == 1;
}

my $line = <$in>;
print $out "AAJT	.	contig_collection	.	.	.	.	.	ID=AAJT;Name=AAJT\n";

while (<$in>) {
	print $out $_;
}

close $out;