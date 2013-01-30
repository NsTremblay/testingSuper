#!/usr/bin/perl

use strict;
use warnings;
use Bio::DB::GenBank;
use Bio::SeqIO;
use Carp;

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
process_file($file_type);


sub process_file {
    @_ = $file_type;
    if ($file_type eq 'fasta') {
	   download_file($file_type);
}
    elsif ($file_type eq 'genbank') {
        download_file($file_type);
}
    else {
	   print "You have entered an invalid file type. \n";
	   0;
}
}

sub download_file {
	@_ = $file_type;
	my $gb_connect = Bio::DB::GenBank->new();
	my $file = $gb_connect->get_Seq_by_acc($file_name) // Carp::carp;
	my $output = Bio::SeqIO->new(-file=> '>' . $file_name . '.' . $file_type , -format=>$file_type);
	$output->write_seq($file);
    print $file_name . '.' . $file_type . " has been downloaded \n";
}
