#!/usr/bin/env/perl

use warnings;
use strict;
use IO::File;
use SubstituteWord;

#&main();
&test2();

sub test2{
	my $subWord = SubstituteWord->new(
		'firstName'=>'Akiff',
		'lastName'=>'Manji',
		'fileName'=>'random.txt'
	);


	my $subWord2 = SubstituteWord->new(
		'firstName'=>'Chad',
		'lastName'=>'Laing',
		'fileName'=>'randasegasdg.txt'
	);


	print $subWord->firstName;
	print $subWord2->firstName;
}

sub main{
	my $team_number = 42;
	my $filename = 'data.txt';

	#< read
	#> write (replace)
	#>> write (append)

	open(my $fh, '<', $filename) or die "cannot open 'filename' $!";

	my $found; 					#initialize the variable but dont assign it to anything

	while (<$fh>) {
		my $line = $_;
		#printFunction($line);
	}
	close $fh;
	#die "cannot find 'Team $team_number' " unless ($found);

	my $newFH = IO::File->new('<' . $filename) or die "$!";

	while(my $line = $newFH->getline){
		#printFunction($line);
	}


	$newFH->close();

}

sub printFunction{
	my $line = shift;

	if ($line =~ m/Perl/) {
		print $line . "\n";
	}
}

