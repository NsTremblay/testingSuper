#!/usr/bin/perl

=pod

=head1 NAME

Modules::GenomeUploader

=head1 SNYNOPSIS

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Michael Whiteside, for all their assistance on this project

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::GenomeUploader;

use strict;
use warnings;
use FindBin;
use lib 'FindBin::Bin/../';
use IO::File;
use IO::Dir;
use Bio::SeqIO;
use parent 'Modules::App_Super';
use parent 'CGI::Application';
use Modules::FormDataGenerator;
umask 0000;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.
Run modes are passed in as <reference name>=><subroutine name>

=cut

sub setup {
	my $self=shift;
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::GenomeUploader");
	$self->start_mode('default');
	$self->run_modes(
		'default'=>'default',
		'genome_uploader'=>'genomeUploader',
		'upload_genome'=>'uploadGenome'
		);

	# $self->connectDatabase({
	# 	'dbi'=>'Pg',
	# 	'dbName'=>'chado_db_test',
	# 	'dbHost'=>'localhost',
	# 	'dbPort'=>'5432',
	# 	'dbUser'=>'postgres',
	# 	'dbPass'=>'postgres'
	# 	});

	#NOTE: This connects to the dummy database to test uploading genomes

	$self->connectDatabase({
		'dbi'=>'Pg',
		'dbName'=>'chado_upload_test',
		'dbHost'=>'localhost',
		'dbPort'=>'5432',
		'dbUser'=>'postgres',
		'dbPass'=>'postgres'
		});
}

=head2 default

Default start mode. Must be decalared or CGI:Application will die. 

=cut

sub default {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

=head2 genomeUploader

Run mode for the genome uploader package

=cut

sub genomeUploader {
	my $self = shift;
	my $template = $self->load_tmpl ( 'genome_uploader.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

=head2 uploadGenome

Run mode to upload a user genome.

=cut

sub uploadGenome {
	my $self = shift;
	my $q = $self->query();

	my $genomeFileName = $q->param("genomeFile");
	my $genomeFile = $q->upload("genomeFile");

	#Here is where we will query for all documents in the form
	#The fields guaranteed to be set by the form are:
	#
	my $genomeName = $q->param("genomeName");
	my $aliasName = $q->param("aliasName");
	my $isolationDate = $q->param("isolationDate");
	my $hostSource = $q->param("hostSource");
	my $isolationLocation = $q->param("isolationLocation");
	my $speciesName = $q->param("speciesName");
	my $serotype = $q->param("serotype");
	my $inputPrivacy = $q->param("inputPrivacy");
	if ($inputPrivacy eq "privateUntil"){
		my $privateUntilDate = $q->param("inputPrivateUntilDate");
	}
	else{
	}

	#With the optional fields:
	#
	my $description = $q->param("description");
	my $finished = $q->param("finished");
	my $keywords = $q->param("keywords");
	my $molType = $q->param("mol_type");
	my $owner = $q->param("owner");
	my $problem = $q->param("problem");
	my $score = $q->param("score");
	my $status = $q->param("status");
	my $symbol = $q->param("symbol");

	#This would likely cause a conflict if two people are uploading a sequence at the same time.
	#We need to add an id to each file to distinguish one from another.

	my $uploadDir = "../../Sequences/TempUpload/";
	my $outHandle = IO::File->new('>' . $uploadDir . $genomeFile) or die "$!";
	
	my $buffer;
	my $FH = $genomeFile->handle();
	my $bytesread = $FH->read( $buffer, 1024 );
	while ($bytesread) {
		$outHandle->print($buffer);
		$bytesread = $FH->read( $buffer, 1024 );
	}
	
	$outHandle->close();

	$self->_uploadToDatabase($genomeFileName , $uploadDir);

}

=head2 _uploadToDatabase

Helper method to upload genome to database

=cut

sub _uploadToDatabase {
	my $self  = shift;
	my $genomeFileName = shift;
	my $uploadDir = shift;

	my $fileNumber = 0;

	my $args1 = "mkdir" . " -m 7777 " . "$uploadDir" . "fasta";
	system($args1) == 0 or die $self->logger->info("System with $args1 failed: $?");
	$self->logger->info("System executed $args1 with value: $?");
	
	my $args2 = "mkdir". " -m 7777 " . "$uploadDir" . "gffout" ;
	system($args2) == 0 or die $self->logger->info("System with $args2 failed: $?");
	$self->logger->info("System executed $args2 with value: $?");

	my $in = Bio::SeqIO->new(-file => "$uploadDir" . "$genomeFileName", -format => 'fasta');

	while (my $seq = $in->next_seq()) {
		$fileNumber++;
		my $singleFileName = $seq->id;
		my $singleFastaHeader = Bio::SeqIO->new(-file => '>' . "$uploadDir/fasta/$singleFileName" . ".fasta" , -format => 'fasta') or die $self->logger->info("$!");
		$singleFastaHeader->write_seq($seq) or die $self->logger->info("$!");
		$self->_appendAttributes($singleFileName , $uploadDir , $fileNumber);
	}

	my $args3 = "rm -r $uploadDir" . "fasta";
	system($args3) == 0 or die $self->logger->info("System with $args3 failed: $?");
	$self->logger->info("System executed $args3 with value: $?");

	my $gffOutDir = $uploadDir . 'gffout/';
	my $gffOutFiles = _getFileNamesFromDirectory($gffOutDir);

	foreach my $gffOutFile(@{$gffOutFiles}) {
		my $dbArgs = "gmod_bulk_load_gff3.pl --dbname chado_upload_test --dbuser postgres --dbpass postgres --organism \"Escherichia coli\" --gfffile $gffOutDir" . "$gffOutFile" . " --random_tmp_dir";
		system($dbArgs) == 0 or die $self->logger->info("System failed with $dbArgs: $?");
		$self->logger->info("System executed $dbArgs with value: $?");
	}

	my $args4 = "rm -r $uploadDir" . "gffout";
	system($args4) == 0 or die $self->logger->info("System with $args4 failed: $?");
	$self->logger->info("System executed $args4 with value: $?");

	my $args5 = "rm -r $uploadDir" . "$genomeFileName";
	system($args5) == 0 or die $self->logger->info("System with $args5 failed: $?");
	$self->logger->info("System executed $args5 with value: $?");

}

=head2 _appendAttributes

Tags fasta files with attributes and converts them to .gff files

=cut

sub _appendAttributes {
	my $self = shift;
	my $singleFileName = shift;
	my $uploadDir = shift;
	my $fileNumber = shift;
	my $attributes = "genome_of=test3";
	my $appendArgs = "gmod_fasta2gff3.pl" . " --attributes " . "\"$attributes\"" . " --fasta_dir " . "$uploadDir" . "fasta/" .  " --gfffilename " . "$uploadDir" . "gffout/out" . "$fileNumber" . ".gff";
	system($appendArgs) == 0 or die $self->logger->info("System failed with $appendArgs: $?");
	$self->logger->info("System executed $appendArgs with value: $?");
	unlink "$uploadDir" . "fasta/" . "directory.index";
	unlink "$uploadDir" . "fasta/" . "$singleFileName" . ".fasta";
}

=head2 _getFileNamesFromDirectory

Opens the specified directory, excludes all filenames beginning with '.' and
returns the rest as an array ref.

=cut

sub _getFileNamesFromDirectory {
	my $directory = shift;

	opendir( DIRECTORY, $directory ) or die "cannot open directory $directory $!\n";
	my @dir = readdir DIRECTORY;
	closedir DIRECTORY;

	my @fileNames;
	foreach my $fileName(@dir){
		next if substr( $fileName, 0, 1 ) eq '.';
		push @fileNames, ( $fileName );
	}
	return \@fileNames;
}

1;