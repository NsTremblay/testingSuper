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
use File::Temp qw(tempdir);
use File::Copy qw(copy move);
use IO::CaptureOutput qw(capture_exec);
use Phylogeny::TreeBuilder;
use Bio::SeqIO;

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
 --test            Run in test mode

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
	$conf, $dbh, $lock, $test, $mummer_dir, $muscle_exe, $blast_dir,
	$nr_location, $parallel_exe, $data_directory);

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

$test = 0;
GetOptions(
	'config=s' => \$config,
    'noload' => \$noload,
    'remove_lock'  => \$remove_lock,
    'help' => \$help,
    'email' => \$email_notification,
    'test' => \$test,
) 
or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $help;

# Perform error reporting before dying
#$SIG{__DIE__} = $SIG{INT} = &error_handler;

# Start logger
my $logfile = ">>/home/genodo/logs/pipeline.log";
$logfile = ">>/tmp/pipeline.log" if $test;
Log::Log4perl->easy_init(
	{ 
		level  => ("$DEBUG"), 
		layout => "%P %d %p - %m%n", 
		file   => $logfile
	}
);
 
die "You must supply a configuration filename" unless $config;

# SQL
# Lock
use constant VERIFY_TABLE => "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
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
# Genome names
use constant CREATE_CACHE_TABLE =>
	"CREATE TABLE pipeline_cache (
		tracker_id      int not null,
		chr_num         int not null,
		name            text,
		description     text,
		collection_id   int,
		contig_id       int
	)";
use constant INSERT_CHR => "INSERT INTO pipeline_cache (tracker_id, chr_num, name, description) VALUES (?,?,?,?)";

# Globals



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
	
	# Sync new genome files to analysis server
	#&sync_to_analysis;
	
	# New sequences uploaded, initiate analysis job
	my ($job_id, $job_dir) = init_job();
	#my ($job_id, $job_dir) = ('7JtG72dKRY','/home/matt/tmp/data/new_genomes/7JtG72dKRY');
	
	INFO "Job ID: $job_id";
	
	# Copy new sequence data into analysis directory
	my $meta_dir = $job_dir . '/meta/';
	my $fasta_dir = $job_dir . '/fasta/';
	my $opt_dir = $job_dir . '/opt/';
	my $msa_dir = $job_dir . '/vf_msa/';
	my $tree_dir = $job_dir . '/vf_tree/';
	my $msa_dir2 = $job_dir . '/pg_msa/';
	my $tree_dir2 = $job_dir . '/pg_tree/';
	
	foreach my $d ($meta_dir, $fasta_dir, $opt_dir, $msa_dir, $tree_dir) {
		mkdir $d or die "Unable to create directory $d ($!)";
	}

	foreach my $t (@tracking_ids) {
		# Locate opt file
		my $opt_file = $tmpdir . "genodo-options-$t.cfg";
		
		die "Option file for tracking ID $t not found." unless -e $opt_file;
		
		my $cfg = new Config::Simple($opt_file) or die "Unable to read config file $opt_file";
		
		# Move fasta file
		my $fasta_file = $fasta_dir . "genodo-fasta-$t.ffn";
		copy $cfg->param('load.fastafile'), $fasta_file or die "Unable to copy file $fasta_file ($!)";
		$cfg->param('load.fastafile', $fasta_file) or die "Unable to update config file value load.fastafile ($!).";
		
		# Append tracker ID to fasta header
		rename_sequences($fasta_file, $t);
		
		# Move params file
		my $params_file = $meta_dir . "genodo-form-params-$t.txt";
		copy $cfg->param('load.propfile'), $params_file or die "Unable to copy file $params_file ($!)";
		$cfg->param('load.propfile', $params_file) or die "Unable to update config file value load.propfile ($!).";
		
		# Update and move conf file
		my $new_opt_file = $opt_dir . "genodo-options-$t.cfg";
		$cfg->write($new_opt_file) or die "Unable to write config file to $new_opt_file ($!)\n";
	}
	INFO "New data copied to analysis directory.";
	
	# Check for vf and amr fasta files
	my $qg_dir = $data_directory . 'vf_amr_sequences/';
	my $vf_fasta_file = $qg_dir . 'query_genes.ffn';
	unless(-e $vf_fasta_file) {
		die "AMR/VF gene fasta file missing. Please run:\n".
		"Database/query_gene_fasta.pl --config ../Modules/genodo.cfg --combined $vf_fasta_file.";
	}
	
	INFO "VF/AMR data found.";
	
	# Run VF/AMR detection analysis
	#vf_analysis($job_dir);
	
	# Re-build MSAs and trees
	#combine_alignments($job_dir . '/panseq_vf_amr_results/locus_alleles.fasta', $msa_dir, $tree_dir);
	
	# Check genome directory is up-to-date
	my $g_dir = $data_directory . 'genomes/';
	my $g_file = $g_dir . 'pan-genomes.ffn';
	download_pangenomes($g_file);
	
	# Identify any novel regions for new genomes
	my ($nr_fasta_file, $nr_anno_file) = novel_region_analysis($job_dir, $g_dir);
	
	# Identify known pan-genome regions in new genomes
	if($nr_fasta_file) {
		# If new regions identified, need to add to file of pan-genome regions
		my $g_file2 = $job_dir . '/pan-genomes.ffn';
		copy $g_file, $g_file2 or die "Unable to copy pan-genomes fasta file $g_file to $g_file2 ($!).";
		
		# Add new regions with consistent identifiable names
		my $fasta = Bio::SeqIO->new(-file   => $nr_fasta_file,
                                    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $nr_fasta_file ($!).";
    
    	open my $out, ">>", $g_file2 or die "Unable to append to file $g_file2 ($!).";
    	my $i = 1;
		while (my $entry = $fasta->next_seq) {
			my $seq = $entry->seq;
			print $out ">nr_$i\n$seq\n";
			$i++;
		}
		close $out;
		
		$g_file = $g_file2;
	}
	INFO "Pan-genome region fasta file: $g_file.";
	pangenome_analysis($job_dir, $g_file);
	
	# Re-build MSAs and trees for pan-genome fragments
	#combine_alignments($job_dir . '/panseq_pg_amr_results/locus_alleles.fasta', $msa_dir2, $tree_dir2, $g_file);
	
	
	
	# Load genome data
	#load_genomes(\@tracking_ids, $opt_dir);
	
	# Load VF/AMR results
	#load_vf($job_dir);
	
	# Load pan-genome results
	
	
	
	# Update meta tables
	
	# Update individual genome records
	
	# Remove tmp files
	
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
	die "Invalid configuration file. Missing db parameters." unless $dbuser;
	
	$tmpdir = $conf->param('tmp.dir');
	die "Invalid configuration file. Missing tmpdir parameters." unless $tmpdir;
	$tmpdir = '/home/matt/tmp/' if $test;
	
	$mail_address = $conf->param('mail.address');
	$mail_pass = $conf->param('mail.pass');
	$mail_notification_address = $mail_address;
	die "Invalid configuration file. Missing email parameters." unless $mail_address;
	$mail_notification_address = 'mdwhitesi@gmail.com' if $test;
	
	# Connect to db
	$dbh = DBI->connect(
		$dbstring,
		$dbuser,
		$dbpass,
		{
			AutoCommit => 1,
		}
	) or die "Unable to connect to database";
	
	# Set exe paths
	$muscle_exe = 'muscle';
	$mummer_dir = '/home/ubuntu/MUMer3.23/';
	$blast_dir = '/home/ubuntu/blast/bin/';
	$parallel_exe = '/usr/bin/parallel';
	$data_directory = '/genodo_backup/data/';
	$data_directory = '/home/matt/tmp/data/' if $test;
	$muscle_exe = '/usr/bin/muscle' if $test;
	$mummer_dir = '/home/matt/MUMmer3.23/' if $test;
	$blast_dir = '/home/matt/blast/bin/' if $test;
	$nr_location = $data_directory . 'blast_databases/nr';
	
		
}


=head2 place_lock

Places a row in the pipeline_status table (creating that table if necessary) 
that will prevent other users/processes from running simultaneous analysis pipeline
while the current process is running.

=cut

sub place_lock {

    # Determine if table exists
    my $sth = $dbh->prepare(VERIFY_TABLE);
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

=head2 sync_to_analysis

=cut

sub sync_to_analysis {
	
	# Run loading script
	my @loading_args = ("sync_remote");
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Data sync'ed to analysis server";
	} else {
		die "Rsync of data director to analysis server failed ($stderr).";
	}
	
}

=head2 sync_to_front

=cut

sub sync_to_front {
	
	# Run loading script
	my @loading_args = ("sync_local");
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Data sync'ed to front-end server";
	} else {
		die "Rsync of data director to front-end server failed ($stderr).";
	}
}

=head2 msa_download

sub msa_download {
	
	# Run loading script
	my @loading_args = ("perl $FindBin::Bin/../Database/msa_fasta.pl",
	'--msa_dir '. $data_directory . 'msa/', 
	'--config '.$config);
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "MSA sequences sucessfully downloaded to analysis directory.";
	} else {
		die "MSA download to analysis directory failed ($stderr).";
	}
}

=cut

=head2 vf_analysis

Run panseq using VF and AMR genes as queryFile

=cut

sub vf_analysis {
	my $job_dir = shift;
	
	# Create configuration file for panseq run
	
	my $pan_cfg_file = $job_dir . '/vf.conf';
	my $fasta_file = $data_directory . 'vf_amr_sequences/query_genes.ffn';
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out 
qq|queryDirectory	$job_dir/fasta/
queryFile	$fasta_file
baseDirectory	$job_dir/panseq_vf_amr_results/
numberOfCores	8
mummerDirectory	$mummer_dir
blastDirectory	$blast_dir
minimumNovelRegionSize	0
novelRegionFinderMode	no_duplicates
muscleExecutable	$muscle_exe
fragmentationSize	0
percentIdentityCutoff	90
coreGenomeThreshold	0
runMode	pan
|;
	close $out;
	
	# Run panseq
	my @loading_args = ("perl /home/ubuntu/Panseq/lib/panseq.pl",
	$pan_cfg_file);
	
	$loading_args[0] = "perl /home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl" if $test;
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Panseq VF/AMR analysis completed successfully.";
	} else {
		die "Panseq VF/AMR analysis failed ($stderr).";
	}

}

=head2 novel_region_analysis

Run panseq to identify novel pan-genome regions in new genomes

=cut

sub novel_region_analysis {
	my ($job_dir, $genome_dir) = @_;

	# Create configuration file for panseq run
	
	my $pan_cfg_file = $job_dir . '/nr.conf';
	my $result_dir = "$job_dir/panseq_nr_results/";
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out 
qq|queryDirectory	$job_dir/fasta/
referenceDirectory	$genome_dir
baseDirectory	$result_dir
numberOfCores	8
mummerDirectory	$mummer_dir
blastDirectory	$blast_dir
minimumNovelRegionSize	1000
novelRegionFinderMode	no_duplicates
muscleExecutable	$muscle_exe
percentIdentityCutoff	90
runMode	novel
|;
	close $out;
	
	# Run panseq
	my @loading_args = ("perl /home/ubuntu/Panseq/lib/panseq.pl",
	$pan_cfg_file);
	
	$loading_args[0] = "perl /home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl" if $test;
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Panseq novel region analysis completed successfully.";
	} else {
		die "Panseq novel region analysis failed ($stderr).";
	}
	
	# If new novel regions
	my $nr_fasta_file = $result_dir . 'novelRegions.fasta';
	my $nr_anno_file = $result_dir . 'anno.txt';
	if(-s $nr_fasta_file) {
		#blast_new_regions($nr_fasta_file, $nr_anno_file);
		return($nr_fasta_file, $nr_anno_file);
	} else {
		return();
	}
	
}

=head2 pangenome_analysis

Run panseq to identify existing/known pan-genome regions in new genomes

=cut

sub pangenome_analysis {
	my ($job_dir, $genome_file) = @_;

	# Create configuration file for panseq run
	
	my $pan_cfg_file = $job_dir . '/pg.conf';
	my $result_dir = "$job_dir/panseq_pg_results/";
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out
qq|queryDirectory	$job_dir/fasta/
queryFile	$genome_file
baseDirectory	$result_dir
numberOfCores	8
mummerDirectory	$mummer_dir
blastDirectory	$blast_dir
minimumNovelRegionSize	1000
novelRegionFinderMode	no_duplicates
muscleExecutable	$muscle_exe
fragmentationSize	1000
percentIdentityCutoff	90
coreGenomeThreshold	0
runMode	pan
storeAlleles	1
|;
	close $out;
	
	# Run panseq
	my @loading_args = ("perl /home/ubuntu/Panseq/lib/panseq.pl",
	$pan_cfg_file);
	
	$loading_args[0] = "perl /home/matt/workspace/c_panseq/live/Panseq/lib/panseq.pl" if $test;
		
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Panseq pan-genome analysis completed successfully.";
	} else {
		die "Panseq pan-genome analysis failed ($stderr).";
	}
}

=head2 rename_sequences

Label sequences as upl_tracker_#|contig_# in fasta file
Original names are stored in the pipeline_cache table.

Ordering is important

=cut
sub rename_sequences {
	my ($fasta_file, $tracker_id) = @_;
	
	# Determine if table exists
    my $sth = $dbh->prepare(VERIFY_TABLE);
    $sth->execute('pipeline_cache');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists) {
       INFO "Creating cache table.\n";
       $dbh->do(CREATE_CACHE_TABLE);
    }
    
	my $insert_query = $dbh->prepare(INSERT_CHR);
	my $tmp_file = $tmpdir . 'genodo-pipeline-tmp.ffn';
	
	open (my $out, ">", $tmp_file) or die "Unable to write to file $tmp_file ($!).";
	
	my $in = Bio::SeqIO->new(-file   => $fasta_file,
                             -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $fasta_file ($!).";
    
    my $contig_num = 1;                          
	while (my $entry = $in->next_seq) {
		my $name = $entry->display_id;
		my $desc = $entry->description;
		my $seq = $entry->seq;
		
		$insert_query->execute($tracker_id,$contig_num,$name,$desc) or die "Unable to insert chr name/description into DB cache ($!).";
		print $out ">lcl|upl_$tracker_id|$contig_num\n$seq\n\n";
		$contig_num++;
	}
	
	close $out;
	
	move($tmp_file, $fasta_file) or die "Unable to move tmp file to $fasta_file ($!).";
}

=head2 combine_alignments

Using muscle's profile alignment add the new sequences to the existing alignments
and build trees

=cut
sub combine_alignments {
	my $allele_file = shift;
	my $msa_dir = shift;
	my $tree_dir = shift;
	my $nr_sequences = shift;
	
	my $add_pang = 0;
	$add_pang = 1 if $nr_sequences;
	
	my ($sql_type1, $sql_type2, $pang_sth);
	if($add_pang) {
		# Perform pan-genome fragment alignments
		
		# Load the reference pan-genome alignment sequences from the DB
		my $sql = 
qq/SELECT f.residues, f.md5checksum
FROM feature f, cvterm t
WHERE f.type_id = t.cvterm_id AND
t.name = 'pangenome' AND f.feature_id = ?
/;
		$sql_type1 = 'locus';
		$sql_type2 = 'derives_from';
		
		$pang_sth = $dbh->prepare($sql);
			
	} else {
		
		$sql_type1 = 'allele';
		$sql_type2 = 'similar_to';
	}
	
	# SQL prep
	my $sql = 
qq/SELECT f.feature_id, f.residues, f.md5checksum, r2.object_id
FROM feature f, feature_relationship r1, feature_relationship r2, cvterm t1, cvterm t2, cvterm t3 
WHERE f.type_id = t1.cvterm_id AND r1.type_id = t2.cvterm_id AND r2.type_id = t3.cvterm_id AND
t1.name = '$sql_type1' AND t2.name = '$sql_type2' AND t3.name = 'part_of' AND
f.feature_id = r1.subject_id AND f.feature_id = r2.subject_id AND r1.object_id = ?
/;

	my $sql2 = 
qq/SELECT f.feature_id, f.residues, f.md5checksum, r2.object_id
FROM private_feature f, private_feature_relationship r1, private_feature_relationship r2, cvterm t1, cvterm t2, cvterm t3 
WHERE f.type_id = t1.cvterm_id AND r1.type_id = t2.cvterm_id AND r2.type_id = t3.cvterm_id AND
t1.name = '$sql_type1' AND t2.name = '$sql_type2' AND t3.name = 'part_of' AND
f.feature_id = r1.subject_id AND f.feature_id = r2.subject_id AND r1.object_id = ?
/;

	my $sth1 = $dbh->prepare($sql);
	my $sth2 = $dbh->prepare($sql2);
	
	# Tree building obj
	my $tb = Phylogeny::TreeBuilder->new();
	
	# Keep record of alleles found in this run
	my $loc_file = $msa_dir . "loci.txt";
	open(my $rec, ">", $loc_file) or die "Unable to write to file $loc_file ($!)";
	
	# Iterate through query gene blocks
	open (my $in, "<", $allele_file) or die "Unable to read file $allele_file";
	local $/ = "\nLocus ";
	
	while(my $locus_block = <$in>) {
		$locus_block =~ s/^Locus //;
		my ($locus) = ($locus_block =~ m/^(\S+)/);
		my ($ftype, $query_id, $query_name) = ($locus =~ m/(\w_)*(\d+)\|(.+)/);
		
		# Record locus
		print $rec "$locus\n";
		
		# Retrieve the alignments for other sequences in the DB
		
		my ($seq_row1, $seq_row2, $pang_ref_seq, $pang_nr_seq);
		if($add_pang) {
			# Look up pangenome alignments sequences: cache or DB.
			if($ftype eq 'nr_') {
				# New pan-genome fragement, get unaligned sequence from cache
				$pang_nr_seq = $nr_sequences->{$query_id};
				$query_id = "nr_$query_id";
				
				die "There is no corresponding sequence for the novel pan-genome region $query_id." unless $pang_nr_seq;
				
			} else {
				# Old pan-genome fragement, get aligned sequence from DB
				$pang_sth->execute($query_id);
				($pang_ref_seq, my $md5) = $pang_sth->fetchrow_array();
				die "There is no corresponding alignment sequence for the pan-genome region $query_id in the DB." unless $pang_ref_seq;
				$sth1->execute($query_id);
				$sth2->execute($query_id);
				$seq_row1 = $sth1->fetchrow_arrayref;
				$seq_row2 = $sth2->fetchrow_arrayref;
				
			}
		} else {
			# Look up allele alignment sequences in DB
			$sth1->execute($query_id);
			$sth2->execute($query_id);
			$seq_row1 = $sth1->fetchrow_arrayref;
			$seq_row2 = $sth2->fetchrow_arrayref;
		}
		
		my $msa_file = $msa_dir . "$query_id.aln";
		
		my $num_seq = 0;
		
		if($row || $row2 || $pang_ref_seq) {
			# Previous alleles exist
			# Discard panseq alignment
			# Add individual sequences to existing alignments
			# Special Case: if aligning pan-genome fragments, always need to
			# align reference to the loci discovered in this run.
			
			# Print out existing alignment to tmp file
			my $aln_file = $msa_dir . "init.aln";
			open(my $aln, ">", $aln_file) or die "Unable to write to file $aln_file ($!)";
			if($pang_ref_seq) {
				print $aln ">pg_$query_id\n$pang_ref_seq\n";
			}
			if($row) {
				do {
					my ($allele_id, $seq, $md5, $cc_id) = @$row;
					print $aln ">public_$cc_id|$allele_id\n$seq\n";
					$num_seq++;
				} while($row = $sth1->fetchrow_arrayref);
			}
			if($row2) {
				do {
					my ($allele_id, $seq, $md5, $cc_id) = @$row2;
					print $aln ">private_$cc_id|$allele_id\n$seq\n";
					$num_seq++;
				} while($row2 = $sth2->fetchrow_arrayref);
			}
			close $aln;
			
			# Align new sequences one at a time to existing alignment
			my $seq_file = $msa_dir . "seq.fna";
			my @loading_args = ($muscle_exe, "-profile -in1 $aln_file -in2 $seq_file -out $aln_file");
			my $cmd = join(' ',@loading_args);
			
			while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
				my $header = $1;
				my $seq = $2;
				
				$seq =~ s/-//g; # Remove gaps
				
				# Print to tmp file
				open(my $seqo, ">", $seq_file) or die "Unable to write to file $seq_file ($!)";
				print $seqo ">$header\n$seq\n";
				close $seqo;
				
				# Run muscle
				my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
				unless($success) {
					die "Muscle profile alignment failed for query gene ID $query_id and sequence $header ($stderr).";
				}
				$num_seq++;
			}
		
			# move tmp file to final location
			move $aln_file, $msa_file or die "Unable to move $aln_file file to $msa_file ($!)";
			
		} elsif($pang_nr_seq) {
			# Discovered new region, so need to build alignment that includes the pan-genome region
			
			my $seq_file = $msa_dir . "seq.fna";
			my @loading_args = ($muscle_exe, "-in $seq_file -out $msa_file");
			my $cmd = join(' ',@loading_args);
			
			# Print to tmp file
			my $seq_file 
			open(my $seqo, ">", $seq_file) or die "Unable to write to file $seq_file ($!)";
			print $seqo ">$query_id\n$pang_nr_seq\n";
			close $seqo;
			
			while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
				my $header = $1;
				my $seq = $2;
				
				$seq =~ s/-//g; # Remove gaps
				
				open(my $seqo, ">", $seq_file) or die "Unable to write to file $seq_file ($!)";
				print $seqo ">$header\n$seq\n";
				close $seqo;
			}
				
			my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
			unless($success) {
					die "Muscle profile alignment failed for new pangenome region $query_id ($stderr).";
			}
			$num_seq++;
		} else {
			# No previous alleles
			# Use alignment generated by panseq
			
			open(my $out, ">", $msa_file) or die "Unable to write to file $msa_file ($!)";
			
			while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
				my $header = $1;
				my $seq = $2;
				
				# Print to tmp file
				print $out ">$header\n$seq\n";
				$num_seq++;
			}
			
			close $out;
		}
		
		# Build tree if enough allele sequences
		if($num_seq > 2) {
			my $tree_file = $tree_dir . "$query_id.phy";
			$tb->build_tree($msa_file, $tree_file);
		}
	}
	close $in;
	close $rec;

}

=head2 download_pangenomes

Make sure the pan-genome file is up-to-date

=cut

sub download_pangenomes {
	my ($genome_file) = @_;
	
	INFO "Downloading pan-genomes into data directory file $genome_file.";
	
	my $sql = 
qq/SELECT f.feature_id
FROM feature f, cvterm t1 
WHERE f.type_id = t1.cvterm_id AND t1.name = 'pangenome'
/;

	my $sql2 = 
qq/SELECT f.feature_id, f.residues
FROM feature f
WHERE f.feature_id IN (
/;

	my $sth1 = $dbh->prepare($sql);
	
	# Determine which pan-genome loci are missing in data directory
	my %genomes;
	my @missing;
	
	# Retrieve IDs for pan-genome loci in DB
	$sth1->execute();
	while(my ($id) = $sth1->fetchrow_array) {
		$genomes{$id}=0;
		
	}
	
	# Check against genomes in file
	if(-e $genome_file) {
		open my $in, "<", $genome_file or die "Unable to read genome fasta file $genome_file ($!).";
		local $/ = "\n>";
		while(my $block = <$in>) {
			my ($header, $seq) = split(/\n/, $block);
			
			my ($pg_id) = ($header =~ m/pg_(\d+)/);
			
			$genomes{$pg_id} = 1 if length $seq;
			
		}
		close $in;
	}
	
	foreach my $id (keys %genomes) {
		push @missing, $id unless $genomes{$id};
	}
	
	
	my $num = scalar @missing;
	INFO "$num pan-genome sequences need to be dowloaded.";
	
	if(@missing) {
		$sql2 .= join(',',@missing);
		$sql2 .= ')';
		my $sth2 = $dbh->prepare($sql2);
		$sth2->execute();
		
		open my $out, ">>", $genome_file or die "Unable to append to genome fasta file $genome_file ($!).";
		while(my ($pgid,$seq) = $sth2->fetchrow_array) {
			
			$seq =~ s/-//g; # Remove gaps
			print $out ">pg_$pgid\n$seq\n";
		}
		close $out;
	}

	INFO "Pan-genome download completed and appended to file.";

}

=head2 load_vf

Load the results from the panseq VF/AMR detection analysis

=cut

sub load_vf {
	my $job_dir = shift;
	
	INFO "Loading amr/vf into DB";
	
	my @loading_args = ("perl $FindBin::Bin/../Sequences/pipeline_allele_loader.pl",
		'--dir '.$job_dir, 
		'--config '.$config);
			
	push @loading_args, '--noload --remove_lock --recreate_cache' ;#if $RECOVER;
	
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "AMR/VF data loaded successfully."
	} else {
		die "Loading of amr/vf data failed ($stderr).";
	}
}

=head2 blast_new_regions

	Assign annotations to new pan-genome regions by BLASTx against the NR DB
	
=cut

sub blast_new_regions {
	my $new_fasta = shift;
	my $blast_file = shift; 
	
	# Run BLAST
	my $blast_cmd = "$blast_dir/blastx -evalue 0.0001 -outfmt ".'\"6 qseqid qlen sseqid slen stitle\" '."-db $nr_location -max_target_seqs 1 -query -";
	my $parallel_cmd = "cat $new_fasta | $parallel_exe --gnu -j 8 --block 1500k --recstart '>' --pipe $blast_cmd > $blast_file";
	
	INFO "Running parallel BLAST: $parallel_cmd";
	
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($parallel_cmd);
	
	if($success) {
		INFO "New pan-genome region BLAST job completed successfully."
	} else {
		die "New pan-genome region BLAST job failed ($stderr).";
	}
}

sub find_snps {
	my $ref_seq = shift;
	my $ref_id = shift;
	my $comp_seq = shift;
	my $contig_collection = shift;
	my $contig = shift;
	
	# Iterate through each aligned sequence, identifying mismatches
	my $l = length($ref_seq)-1;
	my $ref_pos = 0;
	my $comp_pos = 0;
		
	for my $i (0 .. $l) {
        my $c1 = substr($comp_seq, $i, 1);
        my $c2 = substr($comp_seq, $i, 1);
        	
        $comp_pos++ unless $c1 eq '-'; # don't count gaps as a position
        $ref_pos++ unless $c2 eq '-'; # don't count gaps as a position
        	
        if($c1 ne $c2) {
        	# Found snp
        	$chado->handle_snp($ref_id, $c2, $ref_pos, $contig_collection, $contig, $c1, $comp_pos);
        }
	}
    
	
}