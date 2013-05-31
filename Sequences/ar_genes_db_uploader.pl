#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin/../";
use File::Basename;


my $ARFile = $ARGV[0];
my $ARName;
my $ARNumber = 0;
my $ARFileName;


