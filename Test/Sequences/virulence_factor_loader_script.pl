#!/usr/bin/perl

use strict;
use warnings;
#use IO::File;
use Bio::SeqIO;

#This script should parse the headers for the virluence factors from http://www.mgc.ac.cn/VFs/main.htm
# An example of a fasta header from the multi-fasta file downloaded:

# >R008730 sfaC (ECP_0291) - fimbrial transcription regulator protein FaeA [Escherichia coli str. 536 (UPEC)]

# This should incorporate the tags:
	# ID: R008730 <-- This will automatically be tagged into the gfffile.
	# Name: R008730 <-- This will automatically be tagged into the gfffile.

	#These tags will be incorporated as attributes in the featureprop table:
	# name: sfaC
	# uniquename: ECP_0291
	# description: fimbrial transcription regulator protein FaeA
	# organism: Escherichia coli
	# strain: 536
	# Keywords: Virulence Factor
	# comment: UPEC <- commented out for now since we cannot upload comments into chado
	# mol_type: plasmid <- this may or may not be there so we should just default to mol_type : dna

	my $virulenceFactorFile = 'ecoli_virulence_factors_full';
	my $parsedFile = 'VirulenceFactor';
	my $fileNumber = 0;
	my $fileName;
	my $out;

	readInHeaders();

	sub readInHeaders {
		my $in = Bio::SeqIO->new(-file => $virulenceFactorFile,
								 -format => 'fasta'); #or die "$!\n";

		while(my $seq = $in->next_seq() ) {
			$fileName = $parsedFile.$seq->id.".fasta";
			$fileNumber++;
			$out = Bio::SeqIO->new(-file => '>'.$fileName , -format => 'fasta') or die "$!\n";
			$out->write_seq($seq) or die "$!\n";
			my $seqHeader = $seq->desc;
			parseHeader($seqHeader);
		}
		print $fileNumber . " files have been parsed and uploaded into the database \n";
	}

	sub parseHeader {
		my %_seqHeaders;
		my $seqHeader = shift;
		if ($seqHeader =~ /([a-z]*[A-Z]*[0-9]*)\s\([\w\d\W\D]*\)/ ) {
			my $name = $1;
			my $uniquename = $1;
			$_seqHeaders{'NAME'} = $name;
			$_seqHeaders{'UNIQUENAME'} = $uniquename;
		}
		if ($seqHeader =~ /(\()([\w\d\]*_?[\w\d]*)(\))/) {
			my $uniquename = $2;
			$_seqHeaders{'UNIQUENAME'} = $uniquename;
		}
		if ($seqHeader =~ /\[(Escherichia coli)\s(str\.)\s([\w\d\W\D]*)\s(\()([\w\d\W\D]*)(\))\]/){
			my $organism = $1;
			$_seqHeaders{'ORGANISM'} = $organism;
			my $strain = $3;
			$_seqHeaders{'STRAIN'} = $strain;
			my $comment = $5;
			$_seqHeaders{'COMMENT'} = $comment;
		}
		if ($seqHeader =~ /\s\-\s([w\d\W\D]*)\s(\[)/) {
			my $desc = $1;
			$_seqHeaders{'DESCRIPTION'} = $desc;
		}
		if ($seqHeader =~ /(str\.)\s([\w\d\W\D]*)\s(\()([\w\d\W\D]*)(\))\s(plasmid)\s(.*)\]/) {
			my $plasmid = $7;
			my $strain = $2;
			$_seqHeaders{'MOLTYPE'} = "plasmid";
			$_seqHeaders{'PLASMID'} = $plasmid;
			$_seqHeaders{'ORGANISM'} = "Escherichia coli";
			$_seqHeaders{'STRAIN'} = $strain;
		}
		else {
			$_seqHeaders{'MOLTYPE'} = "dna";
			$_seqHeaders{'PLASMID'} = "none";
		}
		$_seqHeaders{'KEYWORDS'} = "Virulence Factor";
		print %_seqHeaders;
		appendAttributes(\%_seqHeaders);
	}

	sub appendAttributes {
		my $_seqHeaders = shift;
		my $mvArgs = "mv " . " $fileName" . " fasta/";
		system($mvArgs) == 0 or die "System with $mvArgs failed: $? \n";
		printf "System executed $mvArgs with value %d\n", $? >> 8;
		my $attributes = _getAtrributes($_seqHeaders);
		my $args = "gmod_fasta2gff3.pl" . " $fileName" .  " --attributes " . "\"$attributes\"";
		system($args) == 0 or die "System with $args failed: $? \n";
		printf "System executed $args with value %d\n", $? >> 8;
		my $dbArgs = "gmod_bulk_load_gff3.pl --dbname chado_db_test --dbuser postgres --dbpass postgres --organism \"Escherichia coli\" --gfffile out.gff";
		system($dbArgs) == 0 or die "System failed with $dbArgs: $? \n";
		printf "System executed $dbArgs with value %d\n", $? >> 8;
		unlink "fasta/$fileName";
		unlink "fasta/directory.index";
		unlink "out.gff";
	}

	sub _getAtrributes {
		my $_seqHeaders = shift;

		if (($_seqHeaders->{NAME} eq "") || 
			($_seqHeaders->{UNIQUENAME} eq "") || 
			($_seqHeaders->{DESCRIPTION} eq "") || 
			($_seqHeaders->{KEYWORDS} eq "") || 
			($_seqHeaders->{MOLTYPE} eq "") || 
			($_seqHeaders->{PLASMID} eq "") || 
			($_seqHeaders->{ORGANISM} eq "") ||
			($_seqHeaders->{STRAIN} eq "")) 
		{
			print "Name: " . $_seqHeaders->{NAME} . "\n";
			print "Uniquanme: " . $_seqHeaders->{UNIQUENAME} . "\n";
			print "Description: " . $_seqHeaders->{DESCRIPTION} . "\n";
			print "Keywords: " . $_seqHeaders->{KEYWORDS} . "\n";
			print "Mol_Type: " . $_seqHeaders->{MOLTYPE} . "\n";
			print "Plasmid: " . $_seqHeaders->{PLASMID} . "\n";
			print "Organism: " . $_seqHeaders->{ORGANISM} . "\n";
			print "Strain: " . $_seqHeaders->{STRAIN} . "\n";
			print "Unsuccessful header parsing! \n";
			die "!$\n";
		}
		else {
		my $_attributes = "name=".$_seqHeaders->{NAME} . ";".
		"uniquename=". $_seqHeaders->{UNIQUENAME} . ";".
		"description=". $_seqHeaders->{DESCRIPTION} . ";".
		"keywords=". $_seqHeaders->{KEYWORDS} . ";".
		#"comment=". $_seqHeaders->{COMMENT} . ";".
		"mol_type=". $_seqHeaders->{MOLTYPE} . ";".
		"plasmid=". $_seqHeaders->{PLASMID} . ";" .
		"organism=". $_seqHeaders->{ORGANISM} . ";".
		"strain=". $_seqHeaders->{STRAIN};
		print "Header parsed succesfully! \n";
		return $_attributes;
	}
}
