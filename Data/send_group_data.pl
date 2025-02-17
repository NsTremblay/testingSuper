#!/usr/bin/env perl 

=head1 NAME

$0 - Send SNP and pangenome presence/absence data file to Giant server for R/Shiny app

=head1 SYNOPSIS

  % send_group_data.pl --config filename --snp1 filepath --snp2 filepath --pg1 filepath --pg2 filepath

=head1 COMMAND-LINE OPTIONS

 --config         Must specify a .conf containing VPN connection parameters, remote filepaths and ssh credentials
 --pg1            Filepath on local machine for pangenome binary matrix data
 --pg2            Filepath on local machine for pangenome function annotations
 [--snp1 ]        Filepath on local machine for snp binary matrix data. OPTIONAL since pangenome can change without altering snp set
 [--snp2 ]        Filepath on local machine for snp function annotations. OPTIONAL since pangenome can change without altering snp set
 
=head1 DESCRIPTION

Connects to VPN, and transfers files. Makes backup of destination file, before copy.

=head1 AUTHOR

Matt Whiteside E<lt>mawhites@phac-aspc.gov.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use strict;
use warnings;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Carp qw/croak carp/;
use Config::Simple;
use Time::HiRes qw( time );
use IO::CaptureOutput qw(capture_exec);
use POSIX;
use constant DATETIME => strftime("%Y-%m-%d_%H-%M-%S", localtime);
use File::Copy;
use Log::Log4perl qw(get_logger);
use WWW::Curl::Easy;
use WWW::Curl::Form;
use Statistics::R;


# Get options
my ($config_filepath, 
	$pg_matrix_file, $pg_functions_file,
	$snps_matrix_file, $snps_functions_file,
	$user, $pass, $addr, $bkp_dir, 
	$callback, $total_size, $current_size
	);

GetOptions(
    'config=s'  => \$config_filepath,
    'pg1=s'     => \$pg_matrix_file,
    'pg2=s'     => \$pg_functions_file,
    'snp1=s'    => \$snps_matrix_file,
    'snp2=s'    => \$snps_functions_file
) or ( system( 'pod2text', $0 ), exit -1 );

my $do_snps = $snps_matrix_file ? 1: 0;

croak "Error: missing argument. You must supply a configuration filepath.\n" . system ('pod2text', $0) unless $config_filepath;
if(my $conf = new Config::Simple($config_filepath)) {
	$user    = $conf->param('shiny.user');
	$pass    = $conf->param('shiny.pass');
	$addr    = $conf->param('shiny.address');
	$bkp_dir = $conf->param('shiny.backupdir');
} else {
	die Config::Simple->error();
}

# Setup logger
my $logger = init($bkp_dir);
$logger->info("<<BEGIN Superphy R/Shiny data file transfer");

# Filenames
my $copy_pgm_file = $bkp_dir . 'superphy_pangenome_matrix_' . DATETIME . '.txt';
my $copy_pgf_file = $bkp_dir . 'superphy_pangenome_functions_' . DATETIME . '.txt';
my $copy_snpm_file = $bkp_dir . 'superphy_snps_matrix_' . DATETIME . '.txt';
my $copy_snpf_file = $bkp_dir . 'superphy_snps_functions_' . DATETIME . '.txt';
my $pgm_file = $bkp_dir . 'superphy_pangenome_matrix.txt';
my $pgf_file = $bkp_dir . 'superphy_pangenome_functions.txt';
my $snpm_file = $bkp_dir . 'superphy_snps_matrix.txt';
my $snpf_file = $bkp_dir . 'superphy_snps_functions.txt';
my $rdata_file = $bkp_dir . "superphy.Rdata";

# Copy to archival filepaths
copy($pg_matrix_file, $copy_pgm_file) or croak "Error: unable to make copy of file $pg_matrix_file called $copy_pgm_file ($!).\n";
copy($pg_functions_file, $copy_pgf_file) or croak "Error: unable to make copy of file $pg_functions_file called $copy_pgf_file ($!).\n";
if($do_snps) {
	copy($snps_matrix_file, $copy_snpm_file) or croak "Error: unable to make copy of file $snps_matrix_file called $copy_snpm_file ($!).\n";
	copy($snps_functions_file, $copy_snpf_file) or croak "Error: unable to make copy of file $snps_functions_file called $copy_snpf_file ($!).\n";
}
$logger->info("Copied files:\n\t$copy_pgm_file,\n\t$copy_pgf_file,\n\t$copy_snpm_file,\n\t$copy_snpf_file");


# Symlink
my @files = ([$pgm_file, $copy_pgm_file], [$pgf_file, $copy_pgf_file]);
push @files, [$snpm_file, $copy_snpm_file], [$snpf_file, $copy_snpf_file] if $do_snps;

foreach my $fset (@files) {
	my $f = $fset->[0];
	my $copy = $fset->[1];
	if(-e $f) {
		unlink $f;
	}
	symlink($copy, $f) or croak "Error: unable to create link to from $f to file $copy ($!).\n";
}

&rsave();

&upload();

$logger->info("END>>");

###############
## Subs
###############

# Setup logging
sub init {
	my $dir = shift;

    # config
    my $conf = q(
        log4perl.logger                    = INFO, FileApp
        log4perl.appender.FileApp          = Log::Log4perl::Appender::File
        log4perl.appender.FileApp.filename = ).$dir.q(send_group_data.log
        log4perl.appender.FileApp.layout   = PatternLayout
        log4perl.appender.FileApp.layout.ConversionPattern = %d> %m%n
    );

    # Initialize logging behaviour
    Log::Log4perl->init(\$conf);

    # Obtain a logger instance
    my $logger = get_logger();
   
   return $logger;
}

# Convert to R binary file
sub rsave {

	my $R = Statistics::R->new();
	
	my @rcmds = (
		qq/r_binary <- as.matrix(read.table('$pgm_file', header=TRUE, sep="\t", check.names=FALSE, row.names=1))/,
		qq/df_region_meta <- read.table('$pgf_file',header=TRUE, sep="\t", check.names=FALSE, row.names=1)/,
		# qq/m_binary <- NULL/, 
		# qq/df_marker_meta <- NULL/,
		qq/m_binary <- as.matrix(read.table('$snpm_file', header=TRUE, sep="\t", check.names=FALSE, row.names=1))/, 
		qq/df_marker_meta <- read.table('$snpf_file',header=TRUE, sep="\t", check.names=FALSE, row.names=1)/,
		q/print('SUCCESS')/
	);

	# Load matrix and function files
	my $rs = $R->run(@rcmds);

	unless($rs =~ m'SUCCESS') {
		$logger->logdie("Error: R read.table failed ($rs).\n");
	} else {
		$logger->info('Data loaded into R')
	}

	# Convert to R binary file
	my $rcmd = qq/save(r_binary,df_region_meta,m_binary,df_marker_meta,file='$rdata_file')/;
	my $rs2 = $R->run($rcmd, q/print('SUCCESS!')/);

	unless($rs =~ m'SUCCESS') {
		$logger->logdie("Error: R save failed ($rs).\n");
	} else {
		$logger->info('R data saved in binary format')
	}

}

# Transfer R binary file to R/Shiny server using cURL
sub upload {

	my $curl = WWW::Curl::Easy->new();
	my $curlf = WWW::Curl::Form->new();

	$curl->setopt(CURLOPT_HEADER,1);
    $curl->setopt(CURLOPT_URL, $addr);

	$curlf->formaddfile($rdata_file, 'shinydata', "multipart/form-data");

	$curl->setopt(CURLOPT_HTTPPOST, $curlf);

	# Do POST
	my $retcode = $curl->perform;

	# Return code
    if ($retcode == 0) {
    	$logger->info("cURL transfer complete.");

        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
       
        unless($response_code eq '201') {
        	$logger->logdie("Recieved unexpected HTTP response: $response_code.");

    	} else {
    		$logger->info("Recieved HTTP response $response_code.");
    	}

    } else {
		# Error code, type of error, error message
    	$logger->logdie("cURL transfer failed ($retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
    }

}



