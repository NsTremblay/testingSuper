#!/usr/bin/env perl

use strict;
use warnings;
use Bio::DB::GenBank;
use Bio::DB::Query::GenBank;
use IO::File;

my $inputFile = $ARGV[0];

my $inFH = IO::File->new('<' . $inputFile) or die "$!";

my %vf;
my @searchKeys;

while(my $line = $inFH->getline()){
    unless($line =~ m/^>/){
        next;
    }
    $line =~ s/\R//g;

    my @la = split(/\s+/, $line);

    if($la[0] =~ m/>(.+)/){
        push @searchKeys, $la[1];
        my $geneName = $1;
        $vf{$la[1]}->{geneName}=$geneName;

        #get the start / stop positions
        if(!defined $la[2]){
            $vf{$la[1]}->{'start'}=1;
            $vf{$la[1]}->{'stop'}='all';
        }
        elsif($la[2] =~ m/(\d+)(\-+|_+)(\d+)/){
            $vf{$la[1]}->{'start'}=$1;
            $vf{$la[1]}->{'stop'}=$3;
        }
        else{
            print "Could not parse start / stop positions $la[2]\n$line";
            exit(1);
        }
    }
    else{
        print "Could not find gene name\n";
        exit(1);
    }
    last;
}


my $query = Bio::DB::Query::GenBank->new(
        -db=>'nucleotide',
        -ids=>\@searchKeys
    );


my $gb = Bio::DB::GenBank->new();
my $stream = $gb->get_Stream_by_query($query);

my $counter=0;
while(my $seq = $stream->next_seq()){
    print('>' . $vf{$searchKeys[$counter]}->{geneName}  . ' ' . $seq->desc() .
        ' [' . $searchKeys[$counter] . ' ' . $vf{$searchKeys[$counter]}->{start} . '-' . 
        $vf{$searchKeys[$counter]}->{stop} . "]\n" . 
        $seq->subseq($vf{$searchKeys[$counter]}->{start},$vf{$searchKeys[$counter]}->{stop}) . "\n");
}
continue{
    $counter++;
}


$inFH->close();
