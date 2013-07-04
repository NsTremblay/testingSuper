#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long;
use Carp;
use Config::Simple;
use POSIX qw(strftime);
use FindBin;
use IO::CaptureOutput qw(capture_exec);

=head1 NAME

$0 - Calls multiple scripts for loading and analyzing a user uploaded genome. Notifies user when complete.

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --options-file			file containing the arguments needed for the various scripts 

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Load arguments
my ($OPTFILE, $DEBUG, $RECOVER
);

GetOptions(
	'optfile=s'=> \$OPTFILE,
    'debug'   => \$DEBUG,
    'recover' => \$RECOVER
);

## Initialization

# Read master config file
croak "You must supply a options filename" unless $OPTFILE;
my $opt = new Config::Simple($OPTFILE) or croak "Cannot read config file $OPTFILE (" . Config::Simple->error() .')';

my $tracking_id = $opt->param('main.tracking_id');
croak "Missing main.tracking_id option in options file." unless $tracking_id;


# Connect to Chado DB
my $dbConfigFile = $opt->param('load.configfile');
croak "Missing load.configfile option in options file." unless $dbConfigFile;

my ($dbh, $tmp_dir) = connect_db($dbConfigFile);


# Tmp files that need to be deleted at end of program
my @remove_tmp_files = ($opt->param('load.fastafile'), $opt->param('load.propfile'), $OPTFILE);


# Common sql statements
my $sql = qq/UPDATE tracker SET step = ? WHERE tracker_id = $tracking_id/;
my $update_step_sth = $dbh->prepare($sql);


# Keep track of progress in tracker table
my $next_step = 2;


# If recovering from a previous failed run, 
# reset the failed column in the tracker table
if($RECOVER) {
	my $sql = qq/UPDATE tracker SET failed = FALSE WHERE tracker_id = $tracking_id/;
	$dbh->do($sql);
}

## Loading

# Check for other loading scripts currently running.
# Only one can run at a time,
# so wait until no more in queue before running.
$sql = qq/SELECT count(*) FROM tracker WHERE step = 1 AND failed = FALSE AND tracker_id < $tracking_id/;
my $sth = $dbh->prepare($sql);

$sth->execute();
my ($num_ahead) = $sth->fetchrow_array();

while($num_ahead) {
	sleep(30); # wait 30 sec before trying again
	
	$sth->execute();
	($num_ahead) = $sth->fetchrow_array();
}

# In front of the line

# Run loading script
my @loading_args = ("perl $FindBin::Bin/genodo_fasta_loader.pl", '--webupload',
	"--tracking_id $tracking_id",
	'--fastafile '.$opt->param('load.fastafile'), 
	'--configfile '.$opt->param('load.configfile'),
	'--propfile '.$opt->param('load.propfile'),
	$opt->param('load.addon_args'));
	
push @loading_args, '--remove_lock --recreate_cache' if $RECOVER;

my $cmd = join(' ',@loading_args);
my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);

if($success) {
	# Update step
	$update_step_sth->execute(++$next_step);
} else {
	my $err_msg = "Loading script failed\n $stderr";
	handle_error($dbh, $tracking_id, $err_msg);
	exit(1);
}



## Termination

# Sign off in tracking job
my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
$sql = qq/UPDATE tracker SET end_date = '$now' WHERE tracker_id = $tracking_id/;
$dbh->do($sql);

# Delete tmp files
clean_up(@remove_tmp_files);


#############
## Subs
#############

=head2 connect_db

Establish DBI connection and return
DBI handle.  Connection parameters are
passed in INI-style config file.

Also returns tmp
directory in config file

=cut

sub connect_db {
	my $dbConfigFile = shift;
	
	# Read db connection parameters config file
	my ($tmp_dir, $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI);
	if(my $db_conf = new Config::Simple($dbConfigFile)) {
		$DBNAME    = $db_conf->param('db.name');
		$DBUSER    = $db_conf->param('db.user');
		$DBPASS    = $db_conf->param('db.pass');
		$DBHOST    = $db_conf->param('db.host');
		$DBPORT    = $db_conf->param('db.port');
		$DBI       = $db_conf->param('db.dbi');
		$tmp_dir = $db_conf->param('tmp.dir');
	} else {
		die Config::Simple->error();
	}
	croak "Missing DB connection parameters in configuration file $dbConfigFile." unless $DBNAME;

	# Connect to DB
	my $dbh = DBI->connect(
		"dbi:Pg:dbname=$DBNAME;port=$DBPORT;host=$DBHOST", $DBUSER,$DBPASS,
		{ AutoCommit => 1, RaiseError => 1 }
	) or croak "Unable to connect to database";
	
	croak "Missing tmp directory in configuration file $dbConfigFile." unless $tmp_dir; 
	
	return($dbh, $tmp_dir);
}

=head2 clean_up

Delete a list of files. Called at
end to remove tmp files.

=cut

sub clean_up {
	my @files = @_;
	
	foreach my $file (@files) {
		unlink $file or carp "Error removing ".$file;
	}
}

=head2 handle_error

Error occurred. Clean up and update tracker table in DB.

=cut

sub handle_error {
	my ($dbh, $tracking_id, $err) = @_;
	
	# Update tracking table in DB
	my $sql = qq/UPDATE tracker SET failed = TRUE WHERE tracker_id = $tracking_id/;
	$dbh->do($sql);
	
	# Save error in a tmp file
	my $err_file = $tmp_dir.'genodo-error-'.$tracking_id.'.txt';
	
	$err_file = $opt->param('main.error_file') if $opt && $opt->param('main.error_file');
	
	open(ERR, ">$err_file") or croak "Unable to write to file $err_file ($!).\n";
	print ERR "# Job $tracking_id Error\n# " . localtime .
			  "\nError Description:\n------------\n$err\n------------\n";
	close ERR;
	
}



