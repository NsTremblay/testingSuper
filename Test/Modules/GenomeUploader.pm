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
use lib "$FindBin::Bin/../";
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
    $self->logger(Log::Log4perl->get_logger());
    $self->logger->info("Logger initialized in Modules::GenomeUploader");
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

=head2

Assigns all values to class functions

=cut

sub _initialize {
    my $self = shift;
    my $q = $self->query();
    my %fileTags = $q->Vars;
    my $genomeFile = 
    $self->_genomeFile($q->upload("genome_file"));
    $self->_genomeFileName($fileTags{'genome_file'});
    $self->_genomeName($fileTags{'genome_of'});
    $self->_uploadDir("$FindBin::Bin/../../Sequences/uploaderTemp");
    $self->_formInputs(\%fileTags);
}

=head2

Stores a genome file for the module

=cut

sub _genomeFile {
    my $self = shift;
    $self->{'_genomeFile'} = shift //return $self->{'_genomeFile'};
}

=head2

Stores a genome file name for the module

=cut

sub _genomeFileName {
    my $self = shift;
    $self->{'_genomeFileName'} = shift //return $self->{'_genomeFileName'};
}

=head2

Stores a genome name for the module

=cut

sub _genomeName {
    my $self = shift;
    $self->{'_genomeName'} = shift // return $self->{'_genomeName'};
}

=head2

Stores an upload directory for the module

=cut

sub _uploadDir {
    my $self = shift;
    $self->{'_uploadDir'} = shift // return $self->{'_uploadDir'};
}

=head2

Stores all inputs passed from the form

=cut

sub _formInputs {
    my $self = shift;
    $self->{'_formInputs'} = shift // return $self->{'_formInputs'};
}

=head2 uploadGenome

Run mode to upload a user genome.

=cut

sub uploadGenomeFile {
    my $self = shift;

    $self->_initialize();
    $self->config_file("$FindBin::Bin/../../Modules/chado_upload_test.cfg");

    system("mkdir -m 7777 " . $self->_uploadDir) == 0 or die $self->logger->info("System with args failed: $?");
    my $outHandle = IO::File->new('>' . $self->_uploadDir . "/" . $self->_genomeFileName) or die "$!";

    my $buffer;
    my $FH = $self->_genomeFile->handle();
    my $bytesread = $FH->read( $buffer, 1024 );
    while ($bytesread) {
        $outHandle->print($buffer);
        $bytesread = $FH->read( $buffer, 1024 );
    }

    $outHandle->close();
    $self->_processUploadGenome();
    $self->_aggregateGffs();
    $self->_uploadToDatabase(dbi => $self->config_param('db.dbi'),
        dbName => $self->config_param('db.name'),
        dbHost => $self->config_param('db.host'),
        dbPort => $self->config_param('db.port'),
        dbUser => $self->config_param('db.user'),
        dbPass => $self->config_param('db.pass'));
    system("rm -r " . $self->_uploadDir) == 0 or die $self->logger->info("System with args failed: $?");
    return $self->redirect('../strain_info');

}

=head2 _uploadToDatabase

Helper method to upload genome to database

=cut

sub _processUploadGenome {
    my $self=shift;
    my $fileNumber = 0;
    my %fileTags = %{$self->_formInputs};
    my $atts = "";
    foreach my $key (keys %fileTags) {
        if (!($fileTags{$key})) {    
        }
        else {
            $atts = $atts . $key ."=" . $fileTags{$key} . ";";
        }
    }
    my $attributes = $atts . "Parent=" . $self->_genomeName;

    system("mkdir -m 7777 " . $self->_uploadDir ."/fastaTemp") == 0 or die $self->logger->info("System with args failed: $?");
    system("mkdir -m 7777 " . $self->_uploadDir . "/gffsTemp") == 0 or die $self->logger->info("System with args failed: $?");
    system("mkdir -m 7777 " . $self->_uploadDir . "/gffsToUpload") == 0 or die $self->logger->info("System with args failed: $?");

    my $in = Bio::SeqIO->new(-file => $self->_uploadDir . "/" . $self->_genomeFileName, -format => 'fasta');

    while (my $seq = $in->next_seq()) {
        $fileNumber++;
        my $singleFileName = $seq->id;
        my $singleFastaHeader = Bio::SeqIO->new(-file => '>' . $self->_uploadDir . "/fastaTemp/$singleFileName.fasta" , -format => 'fasta') or die $self->logger->info("$!");
        $singleFastaHeader->write_seq($seq) or die $self->logger->info("$!");
        $self->_appendAttributes($singleFileName , $fileNumber , $attributes);
    }
}

=head2 _appendAttributes

Tags fasta files with attributes and converts them to .gff files

=cut

sub _appendAttributes {
    my ($self , $_singleFileName , $_fileNumber , $_attributes) = @_;
    my $appendArgs = "gmod_fasta2gff3.pl --type contig --attributes \"$_attributes\" --fasta_dir " . $self->_uploadDir . "/fastaTemp/ --gfffilename " . $self->_uploadDir . "/gffsTemp/out$_fileNumber.gff";
    system($appendArgs) == 0 or die $self->logger->info("System failed with $appendArgs: $?");
    $self->logger->info("System executed $appendArgs with value: $?");
    unlink $self->_uploadDir . "/fastaTemp/directory.index";
    unlink $self->_uploadDir . "/fastaTemp/$_singleFileName.fasta";
}

=head2 _aggregateGffs

Aggregates temp gff files into a single file and appends the parent name.

=cut

sub _aggregateGffs {
    my $self = shift;
    my $gffsTempDir = $self->_uploadDir . "/gffsTemp";
    opendir (TEMP , $self->_uploadDir . "/gffsTemp") or die "cannot open directory , $!\n";
    while (my $file = readdir TEMP)
    {
        $self->_writeOutFile($file);
        unlink $self->_uploadDir . "/gffsTemp/$file"; 
    }
    $self->_mergeFiles();
    closedir TEMP;
}

=head2 _writeOutFile

Helper function to _aggregateGffs(). Writes out single gff files into a single gff file to be uploaded

=cut

sub _writeOutFile {
    my ($self, $file) = @_;
    open my $in , '<' , $self->_uploadDir . "/gffsTemp/$file" or die "Can't write to the file: $!";
    open my $outTags , '>>' , $self->_uploadDir . "/gffsToUpload/tempTagFile" or die "Can't write to the file: $!";
    open my $outSeqs , '>>' , $self->_uploadDir . "/gffsToUpload/tempSeqFile" or die "Can't write to the file: $!";

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
    my $self = shift;
    if ($self->_uploadDir . "/gffsToUpload/tempTagFile" && $self->_uploadDir . "/gffsToUploadtempSeqFile") {
        my $outFileName = "out" . $self->_genomeName . ".gff";
        open my $inTagFile , '<', $self->_uploadDir . "/gffsToUpload/tempTagFile" or die "Can't read file: $!";
        open my $inSeqFile , '<', $self->_uploadDir . "/gffsToUpload/tempSeqFile" or die "Can't read file: $!";
        open my $out , '>>', $self->_uploadDir . "/gffsToUpload/$outFileName";

        print $out $self->_genomeName . "	.	contig_collection	.	.	.	.	.	ID=" . $self->_genomeName . ";Name=" . $self->_genomeName . "\n";
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
        unlink $self->_uploadDir . "/gffsToUpload/tempTagFile";
        unlink $self->_uploadDir . "/gffsToUpload/tempSeqFile";
    }
    else {
    }
}

=head2 _uploadToDataBase

Uploads the aggregated gff file to the database.

=cut

sub _uploadToDatabase {
    my $self = shift;
    my %paramsRef = @_;
    opendir (GFF, $self->_uploadDir . "/gffsToUpload") or die "Can't open directory, $!\n";
    while (my $gffFile = readdir GFF) {
        if ($gffFile eq "." || $gffFile eq "..") {
        }
        else {
            my $dbArgs = "gmod_bulk_load_gff3.pl --dbname " . $paramsRef{'dbName'} . " --dbuser " . $paramsRef{'dbUser'} . " --dbPass " . $paramsRef{'dbPass'} . " --organism \"Escherichia coli\" --gfffile " . $self->_uploadDir . "/gffsToUpload/$gffFile --random_tmp_dir";
            system($dbArgs) == 0 or die "System failed with $dbArgs: $? \n";
            $self->logger->info("System executed $dbArgs with value: $?");
        }
    }
    closedir GFF;
}

1;