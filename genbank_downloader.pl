#!/usr/bin/perl

use strict;
use warnings;
use Bio::DB::GenBank;
use Bio::SeqIO;

#A simple Perl script to download files from Genbank and store it in the local directory.

my $file_name;

print "Enter the Accession number of the GenBank file to download:";
$file_name = <>;
chomp($file_name);
my $gb = Bio::DB::GenBank->new();
my $seq = $gb->get_Seq_by_acc($file_name);
my $o = Bio::SeqIO->new(-file=> '>' . $file_name . '.gbk', -format=>'genbank');
$o->write_seq($seq);