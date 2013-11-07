#!/usr/bin/env perl

use strict;
use warnings;
use Bio::DB::EUtilities;
use IO::File;

my $file = '/home/chad/moria/Results/genodo_function.out';
my $outFile = '/home/chad/genodo_anno.txt';
my $inFH = IO::File->new('<' . $file) or die "Could not open $file $!";

my %idHash;
my %uniqueGis;

while(my $line = $inFH->getline()){
	my @la = split('\t',$line);
	my $gi;
	
	if($la[1] =~ m/gi\|(\d+)\|/){
		$gi = $1;
	}
	$idHash{$la[0]}=$gi;
	$uniqueGis{$gi}=1;
}

my @ids = keys %uniqueGis;
my $outFH = IO::File->new('>' . $outFile) or die "Could not open $outFile";
my @batchIds;
my $counter=0;
my %giFunction;
my $totalCount=0;

foreach my $id(@ids){
	push @batchIds,$id;
	$counter++;
	$totalCount++;
	
	if($counter==2000 || $totalCount == scalar(@ids)){
		print "Batch\n";
	}
	else{
		next;
	}
	
	my $factory = Bio::DB::EUtilities->new(
		-eutil=>'esummary',
		-email=>'chadlaing@gmail.com',
		-db=>'protein',
		id=>\@batchIds,
	);

	while(my $summary = $factory->next_DocSum()){	
		while (my $item = $summary->next_Item('flattened'))  {
	        # not all Items have content, so need to check...
	        if($item->get_name eq 'Title' && $item->get_content){
	        	#$outFH->print($summary->get_id . "\t" . $idHash{$summary->get_id} . "\t" . $item->get_content . "\n");
	        	$giFunction{$summary->get_id}=$item->get_content;
	        }
	    }
	}
	
	@batchIds=();
	$counter=0;
}

my $locusCounter=0;
foreach my $locus(sort keys %idHash){
	$locusCounter++;
	$outFH->print($locusCounter . "\t" . $locus . "\t" . $idHash{$locus} . "\t" . $giFunction{$idHash{$locus}} . "\n");
}

