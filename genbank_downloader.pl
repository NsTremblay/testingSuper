#!/usr/bin/perl

use strict;
use warnings;
use Bio::DB::GenBank;
use Bio::SeqIO;

#A simple Perl script to download files from Genbank and store it in the local directory.
#Can alter the format depending on whether you want Fasta or Genbank outputs.

#TODO: Allow for batch downloads:
#	users can provide a text file with a list of sequences to be donloaded all at once.
#TODO: Convert .gbk or .fasta files directly to .gff automatically
#TODO: Upload batches of .gff files to Chado db.

my $file_name;
my $file_type;

print "Enter the Accession number of the GenBank file to download:";
$file_name = <>;
chomp($file_name);
print "Do you want a Genbank or Fasta file?";
$file_type = <>;
chomp($file_type);
$file_type = lc($file_type);
if ($file_type eq 'fasta') {
	get_file($file_type);
}
elsif ($file_type eq 'genbank') {
	get_file($file_type);
}
else {
	print "You have entered an invalid file type. \n";
	0;
}

sub get_file {
	my $file_format;
	$file_format = $file_type;
	my $gb = Bio::DB::GenBank->new();
	my $seq = $gb->get_Seq_by_acc($file_name);
	my $output = Bio::SeqIO->new(-file=> '>' . $file_name . '.' . $file_type , -format=>$file_type);
	$output->write_seq($seq);
}