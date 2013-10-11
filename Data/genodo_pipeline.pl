#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Config::Simple;
use FindBin;
use lib "$FindBin::Bin/..";
use Time::HiRes qw( time );
use Log::Log4perl qw(:easy);
use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Carp;
use DBI;
use File::Temp qw( tempdir );

=head1 NAME

$0 - Runs programs to do panseq analyses and load them into the DB for newly submitted genomes

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --config          INI style config file containing DB connection parameters
 --noload          Create bulk load files, but don't actually load them.
 --remove_lock     Remove the lock to allow a new process to run
 --help            Detailed manual pages
 --email           Send email notification when script terminates unexpectedly

=head1 DESCRIPTION

	

=head2 NOTES

=over

=item Transactions

This application will, by default, try to load all of the data at

=back

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 error_handler

  Print error to log, send error flag to DB table and then send email notification

=cut

# Globals
my ($config, $noload, $remove_lock, $help, $email_notification,
	$mail_address, $mail_notification_address, $mail_pass, $tmpdir,
	$conf, $dbh, $lock);

sub error_handler {
	# Log
	my $m = "Abnormal termination.";
	$m = @_ if @_;
	FATAL("$m");
	warn "$m";
    
    # DB
    if ($dbh && $dbh->ping && $lock) {
        update_status(-1);
    }
    
    # Email
    if($email_notification) {
    	my $transport = Email::Sender::Transport::SMTP::TLS->new(
		    host     => 'smtp.gmail.com',
		    port     => 587,
		    username => $mail_address,
		    password => $mail_pass,
		);
		
		my $message = Email::Simple->create(
		    header => [
		        From           => $mail_address,
		        To             => $mail_notification_address,
		        Subject        => 'Genodo Pipelin Abnormal Termination',
		        'Content-Type' => 'text/plain'
		    ],
		    body => "Genodo pipeline died on: ".localtime()."\n\nError: $m\n.",
		);
		
		sendmail( $message, {transport => $transport} );
    }
    
    # Exit
    exit(1);
}

# Perform error reporting before dying
#BEGIN {  };
#$SIG{__DIE__} = $SIG{INT} = &error_handler;

# Start logger
#my $logfile = ">>/home/genodo/logs/pipeline.log";
my $logfile = ">>/tmp/pipeline.log";
Log::Log4perl->easy_init(
	{ 
		level  => ("$DEBUG"), 
		layout => "%P %d %p - %m%n", 
		file   => $logfile
	}
);
 
GetOptions(
	'config=s' => \$config,
    'noload' => \$noload,
    'remove_lock'  => \$remove_lock,
    'help' => \$help,
    'email' => \$email_notification,
) 
or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $help;

die "You must supply a configuration filename" unless $config;

# SQL
# Lock
use constant VERIFY_LOCK_TABLE => "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
use constant CREATE_LOCK_TABLE =>
	"CREATE TABLE pipeline_status (
		name        varchar(100),
		starttime   timestamp not null default now(),
		status      int default 0,
		job         varchar(10) default null
	)";
use constant FIND_LOCK => "SELECT name,starttime,status FROM pipeline_status WHERE status = 0";
use constant ADD_LOCK =>  "INSERT INTO pipeline_status (name) VALUES (?)";
use constant REMOVE_LOCK => "DELETE FROM pipeline_status WHERE name = ?";
use constant UPDATE_LOCK => "UPDATE pipeline_status SET status = ? WHERE name = ?";
use constant INSERT_JOB => "UPDATE pipeline_status SET job = ? WHERE name = ?";
# Genomes
use constant FIND_JOBS => qq/SELECT tracker_id FROM tracker WHERE step = ? AND failed = FALSE/;


# Globals
#my $data_directory = '/genodo_backup/data/';
my $data_directory = '/tmp/';


################
# MAIN
################


# Initialization
init($config);

INFO "Start of analysis pipeline run.";

# Place lock
remove_lock() if $remove_lock;
place_lock();

# Find new sequences
my @tracking_ids = check_uploads();

if(@tracking_ids) {
	
	INFO scalar(@tracking_ids)." uploaded genomes to analyze.";
	INFO "Tracking IDs: ". join(', ',@tracking_ids);
	
	# New sequences uploaded, initiate analysis job
	my ($job_id, $job_input_dir) = init_job();
	
	INFO "Job ID: $job_id";
	
	# Copy data into analysis directory
	my $meta_dir = $job_input_dir . '/meta/';
	my $fasta_dir = $job_input_dir . '/fasta/';
	my $opt_dir = $job_input_dir . '/opt/';
	
	foreach my $d ($meta_dir, $fasta_dir, $opt_dir) {
		mkdir $d or die "Unable to create directory $d ($!)";
	}
	
	foreach my $t (@tracking_ids) {
		
	}
	
	
	# Copy to analysis server
	
	
	# Run pan-genome analysis
	
	# Run VF/AMR detection analysis
	
	# Copy to web server
	
	# Load pan-genome results
	
	# Load VF/AMR results
	
	# Update individual genome records
	
} else {
	
	INFO "No uploaded genomes at this time.";
}

# Termination
remove_lock();

INFO "End of analysis pipeline run.";

################
# SUBROUTINES
################


=head2 init

  Process config file and connect to DB

=cut

sub init {
	my $config_file = shift; 
	
	# Process config file 
	unless($conf = new Config::Simple($config_file)) {
	die Config::Simple->error();
	}
	
	my $dbstring = 'dbi:Pg:dbname='.$conf->param('db.name').
	            ';port='.$conf->param('db.port').
	            ';host='.$conf->param('db.host');
	my $dbuser = $conf->param('db.user');
	my $dbpass = $conf->param('db.pass');
	croak "Invalid configuration file. Missing db parameters." unless $dbuser;
	
	$tmpdir = $conf->param('tmp.dir');
	croak "Invalid configuration file. Missing tmpdir parameters." unless $tmpdir;
	
	$mail_address = $conf->param('mail.address');
	$mail_pass = $conf->param('mail.pass');
	$mail_notification_address = 'mdwhitesi@gmail.com';
	croak "Invalid configuration file. Missing email parameters." unless $mail_address;
	
	# Connect to db
	$dbh = DBI->connect(
		$dbstring,
		$dbuser,
		$dbpass,
		{
			AutoCommit => 1,
		}
	) or croak "Unable to connect to database";
		
}


=head2 place_lock

Places a row in the pipeline_status table (creating that table if necessary) 
that will prevent other users/processes from running simultaneous analysis pipeline
while the current process is running.

=cut

sub place_lock {

    # Determine if table exists
    my $sth = $dbh->prepare(VERIFY_LOCK_TABLE);
    $sth->execute('pipeline_status');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists) {
       INFO "Creating lock table.\n";
       $dbh->do(CREATE_LOCK_TABLE);
       
    } else {
    	# check for existing lock
	    my $select_query = $dbh->prepare(FIND_LOCK);
	    $select_query->execute();
	
	    if(my @result = $select_query->fetchrow_array) {
			my ($name,$time,$status) = @result;
			my ($progname,$pid)  = split /\-/, $name;
	
	       	die "Cannot establish lock. There is another process running with process id $pid (started: $time, status: $status).";
		}
	}
    
    my $pid = $$;
	my $name = "$0-$pid";
    
	my $insert_query = $dbh->prepare(ADD_LOCK);
	$insert_query->execute($name);
	
	$lock = $name;

    return;
}

sub remove_lock {

	my $select_query = $dbh->prepare(FIND_LOCK);
    $select_query->execute();

    my $delete_query = $dbh->prepare(REMOVE_LOCK);

    if(my @result = $select_query->fetchrow_array) {
		my ($name,$time,$status) = @result;

		$delete_query->execute($name) or die "Removing the lock failed.";
		
    } else {
    	DEBUG "Could not find row in pipeline_status table. Lock was not removed.";
    }
    
    $lock = 0;
    
    return;
}

sub update_status {
	my $status = shift;
	
    my $update_query = $dbh->prepare(UPDATE_LOCK);
	$update_query->execute($status, $lock) or die "Updating status failed.";
}


=head2 job_id

  Find novel ID for new job. ID is used as directory.

=cut

sub init_job {
	
	my $job_dir = tempdir('XXXXXXXXXX', DIR => $data_directory . 'new_genomes/' );
	my ($job_id) = $job_dir =~ m/\/(\w{10})$/; 
	
	my $update_query = $dbh->prepare(INSERT_JOB);
	$update_query->execute($job_id, $lock) or die "Inserting job ID into status table failed.";
	
	return ($job_id, $job_dir);
}


=head2 check_uploads

  Check for newly uploaded genomes that have not been analyzed.

=cut

sub check_uploads {
	
	my $sth = $dbh->prepare(FIND_JOBS);
	$sth->execute(2); # Step 2 = uploaded data printed to tmp directory
	
	my @tracking_ids;
	
	while (my $row = $sth->fetchrow_arrayref) {
		push @tracking_ids, $row->[0];
	}
	
	return @tracking_ids;	
}



