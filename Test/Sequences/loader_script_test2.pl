#!/usr/bin/perl

use strict;
use warnings;

my $lineno = 1;

while (<>) {
   print $lineno++;
   print ": $_";
}
