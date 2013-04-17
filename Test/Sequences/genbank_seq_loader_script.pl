#!/usr/bin/perl

use strict;
use warnings;
use IO::File;
use IO::Dir;
use Bio::SeqIO;

#A database loader for downloaded Genbank sequences.
#gmod_fasta2gff3.pl included with Bio::Perl will automatically use the gi/gb tag as a sequence unique identifier.
#The remainder of the fasta header will be appended as an attirbute to the features as they are loaded.
#Each sequences file is associated with a number to identify what genome the uploaded features belong to. 
#We'll store the genome number unsing the attribute 'member_of'.

#An example of a fasta header of a single genome file:
#>gi|190904743|gb|AAJT02000001.1| Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence

#This will be parsed and uploaded into the feature table automatically when gmod_fasta2gff3.pl is called:
	# ID: gi|190904743|gb|AAJT02000001.1|
	#Name: gi|190904743|gb|AAJT02000001.1|
	#Uniquename: gi|190904743|gb|AAJT02000001.1|-<feature_id>

#Along with the following atrtributes in the featureprop table:
	# name: Escherichia coli B7A
	# description: Escherichia coli B7A gcontig_1112495748542, whole genome shotgun sequence
	# organism: Escherichia coli
	# keywords: Genome Sequence
	# member_of: <genome number>
	# mol_type: dna

	my $directoryName = $ARGV[0];
	my $fileNumber = 0;
	my $genomeNumber;
	parseSequences();

	sub parseSequences {
		opendir('' , $directoryName) or die "Couldn't open directory $directoryName , $!\n";
		while (my $file = readdir '')
		{
			print "$file\n";
			if ($file eq "." || $file eq ".."){
			}
			else {
				$fileNumber++;
				mkNewFastaFolder();
				copyFastaFile($file);
				readInHeaders($file);
				uploadGenomeToDb();
				unlink $file;
				unlinkFastaFolder();
				unlink "out.gff";
			}
		}
		closedir '';
	}

	sub mkNewFastaFolder {
		my $mkDirArgs = "mkdir fasta";
		system($mkDirArgs) == 0 or die "System with $mkDirArgs failed: $? \n";
		printf "System executed $mkDirArgs with value %d\n" , $? >> 8;
	}

	sub unlinkFastaFolder {
		my $unlinkDirArgs = "rm -r fasta";
		system($unlinkDirArgs) == 0 or die "System with $unlinkDirArgs failed: $? \n";
		printf "System executed $unlinkDirArgs with value %d\n" , $? >> 8;
	}

	sub copyFastaFile {
		my $file = shift;
		if ($file eq "." || $file eq ".."){
		}
		else {
			my $cpArgs = "cp " . "$directoryName/" . "$file" . " .";
			system($cpArgs) == 0 or die "System with $cpArgs failed: $? \n";
			printf "System executed $cpArgs with value %d\n" , $? >> 8;
		}
	}

	sub readInHeaders {
		my $file = shift;
		my $in = Bio::SeqIO->new(-file => "$file" , -format => 'fasta');
		#my $in = Bio::SeqIO->new(-file => "$directoryName/" . $file, -format => 'fasta'); 

		while(my $seq = $in->next_seq()) {
			my $singleFileName = $seq->id;
			my $description = $seq->desc();
			my $singleFastaHeader = Bio::SeqIO->new(-file => '>'."fasta/$singleFileName" . ".fasta" , -format => 'fasta') or die "$!\n";
			$singleFastaHeader->write_seq($seq) or die "$!\n";
			appendAtrributes($seq , $singleFileName , $description);
		}
	}

	sub  appendAtrributes {
		my $seq = shift;
		my $singleFileName = shift;
		my $description = shift;
		print $singleFileName;
		my $nameAttribute = _getName($seq, $singleFileName);
		if ($nameAttribute eq "") {
			die "Errorparsing $singleFileName $!\n";
		}
		else{
			my $keywords = "keywords";
			$genomeNumber  = $fileNumber;
			my $attributes = "organism=Escherichia coli" . ";" . "genome_of=$nameAttribute" . ";" . "description=$description" . ";" . "keywords=Genome Sequence" . ";" . "mol_type=dna" . ";" . "member_of=$genomeNumber";
			my $appendArgs = "gmod_fasta2gff3.pl" . " --attributes " . "\"$attributes\"";
			unlink "fasta/directory.index";
			system($appendArgs) == 0 or die "System failed with  $appendArgs: $? \n";
			printf "System executed $appendArgs with value %d\n" , $? >> 8;
		}
	}

	#Some sequence files may be empty and as a result wont produce an out.gff file. If an out.gff file is not present, the db uploader will throw up. So we specify to skip the file.
	sub uploadGenomeToDb {
		my $outFileHandle = IO::File->new();
		if ($outFileHandle->open("< out.gff")) {
			my $dbArgs = "gmod_bulk_load_gff3.pl --dbname chado_db_test --dbuser postgres --dbpass postgres --organism \"Escherichia coli\" --gfffile out.gff";
			system($dbArgs) == 0 or die "System failed with $dbArgs: $? \n";
			printf "System executed $dbArgs with value %d\n", $? >> 8;
		}
		else{
		}
	}

	#The first two lines should take care of the complete genome seqences. These will be individually added to the db.
	sub _getName {
		my $seq = shift;
		my $singleFileName = shift;
		my $tagName;
		if ($singleFileName =~ /(|gb|)([A-Z][A-Z][A-Z][A-Z])/){
			$tagName = $2;
		}
		else{
			$tagName = "";
		}
		print "My tag name: $tagName\n";
		my $newName;
		my $originalName = $seq->desc;
		if ($originalName =~ /(Escherichia coli)([\w\d\W\D]*)(,)?(complete)/){
			$newName = $2;
			$newName =~ s/Escherichia coli//;
			$newName =~ s/,//;
			$newName =~ s/'//;
			$newName =~ s/'//;
			$newName =~ s/str./Str./;
			print "Name : $newName\n";
		}
		elsif($originalName =~ /(Escherichia coli)([\w\d\W\D]*)(WGS)/){
			$newName = "$tagName -$2";
			print "Name : $newName\n"
		}
		elsif ($originalName =~ /(Escherichia coli)([\w\d\W\D]*)\s([\w\d\W\D]*)(,)/) {
			$newName = $2;
			if ($newName eq "") {
				$newName = "$tagName -$3";
				print "Name : $newName\n"
			}
			else {
				$newName = "$tagName -$2";
				print "Name : $newName\n"
			}
		}
		else{
			$newName = $originalName;
			$newName =~ s/Escherichia coli//;
			print "Name : $newName\n"
		}
		return $newName;
	}
