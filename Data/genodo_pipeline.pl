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
	$conf, $dbh, $lock, $test);

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
my $data_directory = '/genodo_backup/data/';
$data_directory = '/home/matt/tmp/data/' if $test;


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
	my $msa_dir = $job_dir . '/msa/';
	my $tree_dir = $job_dir . '/tree/';
	
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
	my $g_file = $data_directory . 'pangenomes/pan-genomes.ffn';
	download_pangenomes($g_file);
	
	# Identify any novel regions for new genomes
	novel_region_analysis($job_dir);
	
	
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
	my $muscle_exe = 'muscle';
	my $mummer_dir = '/home/ubuntu/MUMer3.23/';
	my $blast_dir = '/usr/bin/';
	$muscle_exe = '/usr/bin/muscle' if $test;
	$mummer_dir = '/home/matt/MUMmer3.23/' if $test;
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
	my $job_dir = shift;

	# Create configuration file for panseq run
	
	my $pan_cfg_file = $job_dir . '/nr.conf';
	my $genome_dir = $data_directory . "pangenomes/";
	my $muscle_exe = 'muscle';
	my $mummer_dir = '/home/ubuntu/MUMer3.23/';
	my $blast_dir = '/usr/bin/';
	$muscle_exe = '/usr/bin/muscle' if $test;
	$mummer_dir = '/home/matt/MUMmer3.23/' if $test;
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out 
qq|queryDirectory	$job_dir/fasta/
referenceDirectory	$genome_dir
baseDirectory	$job_dir/panseq_nr_results/
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
	
	# SQL prep
	my $sql = 
qq/SELECT f.feature_id, f.residues, f.md5checksum, r2.object_id
FROM feature f, feature_relationship r1, feature_relationship r2, cvterm t1, cvterm t2, cvterm t3 
WHERE f.type_id = t1.cvterm_id AND r1.type_id = t2.cvterm_id AND r2.type_id = t3.cvterm_id AND
t1.name = 'allele' AND t2.name = 'similar_to' AND t3.name = 'part_of' AND
f.feature_id = r1.subject_id AND f.feature_id = r2.subject_id AND r1.object_id = ?
/;

	my $sql2 = 
qq/SELECT f.feature_id, f.residues, f.md5checksum, r2.object_id
FROM private_feature f, private_feature_relationship r1, private_feature_relationship r2, cvterm t1, cvterm t2, cvterm t3 
WHERE f.type_id = t1.cvterm_id AND r1.type_id = t2.cvterm_id AND r2.type_id = t3.cvterm_id AND
t1.name = 'allele' AND t2.name = 'similar_to' AND t3.name = 'part_of' AND
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
		my ($query_id, $query_name) = ($locus =~ m/(\d+)\|(.+)/);
		
		# Record locus
		print $rec "$locus\n";
		
		# Retrieve the alignments for other sequences in the DB
		$sth1->execute($query_id);
		$sth2->execute($query_id);
		my $row = $sth1->fetchrow_arrayref;
		my $row2 = $sth2->fetchrow_arrayref;
		
		my $msa_file = $msa_dir . "$query_id.aln";
		
		my $num_seq = 0;
		
		if($row || $row2) {
			# Previous alleles exist
			# Discard panseq alignment
			# Add individual sequences to existing alignments
			
			# Print out existing alignment to tmp file
			my $aln_file = $msa_dir . "init.aln";
			open(my $aln, ">", $aln_file) or die "Unable to write to file $aln_file ($!)";
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
			
			# Align sequences one at a time
			my $seq_file = $msa_dir . "seq.fna";
			while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
				my $header = $1;
				my $seq = $2;
				
				$seq =~ s/_//g; # Remove gaps
				
				# Print to tmp file
				open(my $seqo, ">", $seq_file) or die "Unable to write to file $seq_file ($!)";
				print $seqo ">$header\n$seq\n";
				close $seqo;
				
				# Run muscle 
				my @loading_args = ("muscle", "-profile -in1 $aln_file -in2 $seq_file -out $aln_file");
				my $cmd = join(' ',@loading_args);
				my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
				unless($success) {
					die "Muscle profile alignment failed for query gene ID $query_id and sequence $header ($stderr).";
				}
				$num_seq++;
			}
			
			# move tmp file to final location
			move $aln_file, $msa_file or die "Unable to move $aln_file file to $msa_file ($!)";
			
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




