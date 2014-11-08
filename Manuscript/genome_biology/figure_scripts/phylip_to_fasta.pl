#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;

my $inputFile = $ARGV[0];

my $inFH = IO::File->new('<' . $inputFile) or die "$!";

while(my $line = $inFH->getline){
	if(($inFH->input_line_number == 1) || ($line eq '')){
		next;
	}
	$line =~ s/\R//;
	
	my ($name,$seq);
	if($line =~ m/(^\S+)\s+(\S+)/){
		$name = $1;
		$seq = $2;
	}
	else{
		print STDERR "No sequence found!";
		exit(1);
	}

	print '>' . $name . "\n" . $seq . "\n";
}

$inFH->close();