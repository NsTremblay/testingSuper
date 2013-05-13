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
use Modules::FormDataGenerator;
umask 0000;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.
Run modes are passed in as <reference name>=><subroutine name>

=cut

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::GenomeUploader");
	$self->start_mode('default');
	$self->run_modes(
		'default'=>'default',
		'genome_uploader'=>'genomeUploader',
		'upload_genome'=>'uploadGenomeFile'
		);
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

sub uploadGenomeFile {
	my $self = shift;
	my $q = $self->query();

	my $logger = Log::Log4perl->get_logger();

	my $genomeFileName = $q->param("genomeFile");
	my $genomeFile = $q->upload("genomeFile");

        #Create a hash to store the form inputs.
        my %fileTags;

        #Here is where we will query for all documents in the form
        #The fields guaranteed to be set by the form are:
        #

        #Genome name is set as the parent of the contig
        my $genomeName = $q->param("genomeName");
        $fileTags{'genome_of'} = $genomeName;
        
        #The rest of these are tagged as attributes. These attributes will be added as feature properties.
        my $aliasName = $q->param("aliasName");
        $fileTags{'alias'} = $aliasName;
        my $isolationDate = $q->param("isolationDate");
        $fileTags{'isolation_date'} = $isolationDate;
        my $hostSource = $q->param("hostSource");
        $fileTags{'host_source'} = $hostSource;
        my $isolationLocation = $q->param("isolationLocation");
        $fileTags{'location'} = $isolationLocation;
        my $speciesName = $q->param("speciesName");
        $fileTags{'organism'} = $speciesName;
        my $serotype = $q->param("serotype");
        $fileTags{'serotype'} = $serotype;
        my $inputPrivacy = $q->param("inputPrivacy");
        $fileTags{'privacy'} = $inputPrivacy;
        #if ($inputPrivacy eq "privateUntil"){
        #	my $privateUntilDate = $q->param("inputPrivateUntilDate");
        #	$fileTags{'privacy'} = $privateUntilDate;
        #}
        #else{
        #}

        #With the optional fields:
        #
        my $description = $q->param("description");
        $fileTags{'description'} = $description;
        my $finished = $q->param("finished");
        $fileTags{'finished'} = $finished;
        my $keywords = $q->param("keywords");
        $fileTags{'keywords'} = $keywords;
        my $molType = $q->param("mol_type");
        $fileTags{'mol_type'} = $molType;
        my $owner = $q->param("owner");
        $fileTags{'owner'} = $owner;
        my $problem = $q->param("problem");
        $fileTags{'problem'} = $problem;
        my $score = $q->param("score");
        $fileTags{'score'} = $score;
        my $status = $q->param("status");
        $fileTags{'status'} = $status;
        my $symbol = $q->param("symbol");
        $fileTags{'symbol'} = $symbol;

        #This would likely cause a conflict if two people are uploading a sequence at the same time.
        #We need to add an id to each file to distinguish one from another.

        my $uploadDir = "../../Sequences/uploaderTemp";

        system("mkdir -m 7777 $uploadDir") == 0 or die $logger->info("System with args failed: $?");
        my $outHandle = IO::File->new('>' . "$uploadDir/$genomeFileName") or die "$!";
        
        my $buffer;
        my $FH = $genomeFile->handle();
        my $bytesread = $FH->read( $buffer, 1024 );
        while ($bytesread) {
        	$outHandle->print($buffer);
        	$bytesread = $FH->read( $buffer, 1024 );
        }
        
        $outHandle->close();
        $self->_processUploadGenome($genomeFileName , $uploadDir , \%fileTags);
        $self->_aggregateGffs($uploadDir , $genomeName);
        #$self->_uploadToDatabase($uploadDir);
        #system("rm -r $uploadDir") == 0 or die $logger->info("System with args failed: $?");
        return $self->redirect('../strain_info');

    }

=head2 _uploadToDatabase

Helper method to upload genome to database

=cut

sub _processUploadGenome {
	my ($self, $genomeFileName , $uploadDir , $fileTags) = @_;
	#print STDERR ref($fileTags) . "\n";
	#print STDERR ref(%{$fileTags}) . "\n";

	my $logger = Log::Log4perl->get_logger();

        #Hash reference to the tags that need to be printed to each fasta file.
        my %fileTags = %{$fileTags};
        
        my $fileNumber = 0;
        
        #Get genome name
        my $genomeName  = $fileTags->{'genome_of'};
        
        my $atts = "";
        foreach my $key (keys %fileTags) {
        	if (!($fileTags->{$key})) {
        	}
        	else {
        		$atts = $atts . $key ."=" . $fileTags->{$key} . ";";
        	}
        }
        my $attributes = $atts . "Parent=$genomeName";
        #print STDERR $attributes . "\n";

        #Make temp files
        system("mkdir -m 7777 $uploadDir/fastaTemp") == 0 or die $logger->info("System with args failed: $?");
        system("mkdir -m 7777 $uploadDir/gffsTemp") == 0 or die $logger->info("System with args failed: $?");
        system("mkdir -m 7777 $uploadDir/gffsToUpload") == 0 or die $logger->info("System with args failed: $?");

        my $in = Bio::SeqIO->new(-file => "$uploadDir/$genomeFileName", -format => 'fasta');

        while (my $seq = $in->next_seq()) {
        	$fileNumber++;
        	my $singleFileName = $seq->id;
        	my $singleFastaHeader = Bio::SeqIO->new(-file => '>' . "$uploadDir/fastaTemp/$singleFileName" . ".fasta" , -format => 'fasta') or die $logger->info("$!");
        	$singleFastaHeader->write_seq($seq) or die $logger->info("$!");
        	$self->_appendAttributes($singleFileName , $uploadDir , $fileNumber , $attributes);
        }
    }

=head2 _appendAttributes

Tags fasta files with attributes and converts them to .gff files

=cut

sub _appendAttributes {
	my ($self , $singleFileName , $uploadDir , $fileNumber , $_attributes) = @_;
	my $logger = Log::Log4perl->get_logger();
        #$_attributes =~ s/;$//;
        my $appendArgs = "gmod_fasta2gff3.pl --type contig --attributes \"$_attributes\" --fasta_dir $uploadDir/fastaTemp/ --gfffilename $uploadDir/gffsTemp/out$fileNumber.gff";
        system($appendArgs) == 0 or die $logger->info("System failed with $appendArgs: $?");
        $logger->info("System executed $appendArgs with value: $?");
        unlink "$uploadDir/fastaTemp/directory.index";
        unlink "$uploadDir/fastaTemp/$singleFileName.fasta";
    }

=head2 _aggregateGffs

Aggregates temp gff files into a single file and appends the parent name.

=cut

sub _aggregateGffs {
	my ($self , $uploadDir , $genomeName) = @_;
	my $gffOutDir = "$uploadDir/gffsToUpload";
	my $gffsTempDir = "$uploadDir/gffsTemp";
	my $tempTagFile = "$gffOutDir/tempTagFile";
	my $tempSeqFile = "$gffOutDir/tempSeqFile";

	opendir (TEMP , "$gffsTempDir") or die "cannot open directory $gffOutDir , $!\n";
	while (my $file = readdir TEMP)
	{
		$self->_writeOutFile($file, $uploadDir, $gffsTempDir, $gffOutDir, $tempTagFile, $tempSeqFile);
		unlink "$gffsTempDir/$file"; 
	}
	$self->_mergeFiles($uploadDir, $gffOutDir, $tempTagFile, $tempSeqFile, $genomeName);
	closedir TEMP;
}

=head2 _writeOutFile

Helper function to _aggregateGffs(). Writes out single gff files into a single gff file to be uploaded

=cut

sub _writeOutFile {
	my ($self, $file, $uploadDir, $gffsTempDir, $gffOutDir, $tempTagFile, $tempSeqFile) = @_;
	open my $in , '<' , "$gffsTempDir/$file" or die "Can't write to the file: $!";
	open my $outTags , '>>' , "$tempTagFile" or die "Can't write to the file: $!";
	open my $outSeqs , '>>' , "$tempSeqFile" or die "Can't write to the file: $!";

	while (<$in>) {
		if ($. == 3) {
			print $outTags $_;
		}
		if ($. == 5 || $. == 6){
			print $outSeqs $_;
		}
		else{
		}
	}
	close $outTags;
	close $outSeqs;
}

=head2 _mergeFiles

Helper function to _aggregateGffs(). Writes out single gff files into a single gff file to be uploaded

=cut

sub _mergeFiles {
	my ($self , $uploadDir , $gffOutDir , $tempTagFile , $tempSeqFile , $genomeName) = @_;
	if ($tempTagFile && $tempSeqFile) {
		my $outFileName = "out$genomeName.gff";
		open my $inTagFile , '<', $tempTagFile or die "Can't read $tempTagFile: $!";
		open my $inSeqFile , '<', $tempSeqFile or die "Can't read $tempSeqFile: $!";
		open my $out , '>>', "$gffOutDir/$outFileName";
		
		print $out "$genomeName	.	contig_collection	.	.	.	.	.	ID=$genomeName;Name=$genomeName\n";
		while (my $line = <$inTagFile>) {
			print $out $line;
		}
		close $inTagFile;
		print $out "##FASTA\n";
		while (my $line = <$inSeqFile>) {
			print $out $line;
		}
		close $inSeqFile;
		close $out;
		#unlink "$tempTagFile";
		unlink "$tempSeqFile";
	}
	else {
	}
}

=head2 _uploadToDataBase

Uploads the aggregated gff file to the database.

=cut

sub _uploadToDatabase {

}

1;