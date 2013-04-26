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
use parent 'Modules::App_Super';
use parent 'CGI::Application';
use Modules::FormDataGenerator;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.
Run modes are passed in as <reference name>=><subroutine name>

=cut

sub setup {
	my $self=shift;
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::StrainInfo");
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

	#my $formDataGenerator = Modules::FormDataGenerator->new();
	#$formDataGenerator->dbixSchema($self->dbixSchema);
	#my $genomeUploadFormRef = $formDataGenerator->getGenomeUploadFormData();
	#$template->param(GENOMEUPLOADFORMDATA=>$genomeUploadFormRef);
	return $template->output();
}

=head2

Run mode to upload a user genome.

=cut

sub uploadGenome {

}

1;