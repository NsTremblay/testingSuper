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
use Bio::SeqIO;

=head1 NAME

$0 - Runs programs to do panseq analyses and load them into the DB for newly submitted genomes

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --config          INI style config file containing DB connection parameters
 --noload          Create bulk load files, but don't actually load them.
 --remove_lock     Remove the lock to allow a new process to run
 --recover         Rebuild all caches
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

# Globals
my ($config, $noload, $recover, $remove_lock, $help, $email_notification,
	$mail_address, $mail_notification_address, $mail_pass, $input_dir,
	$conf, $dbh, $lock, $test, $mummer_dir, $muscle_exe, $blast_dir,
	$nr_location, $parallel_exe, $data_directory, $tmp_dir);
	

$test = 0;
GetOptions(
	'config=s' => \$config,
    'noload' => \$noload,
    'remove_lock'  => \$remove_lock,
    'recover' => \$recover,
    'help' => \$help,
    'email' => \$email_notification,
    'test' => \$test,
) 
or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $help;

# Perform error reporting before dying
$SIG{__DIE__} = $SIG{INT} = 'error_handler';
 
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
use constant FIND_GENOMES => qq/SELECT tracker_id FROM tracker WHERE step = ? AND failed = FALSE/;
use constant UPDATE_GENOME => qq/UPDATE tracker SET step = ? WHERE tracker_id = ?/;
use constant SET_GENOME_JOB => qq/UPDATE tracker SET pid = ? WHERE tracker_id = ?/;
use constant CLOSE_GENOME => qq/UPDATE tracker SET end_date = NOW() WHERE tracker_id = ?/;
use constant FAIL_GENOME => qq/UPDATE tracker SET failed = TRUE WHERE tracker_id = ?/;
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
my $update_step_sth;
my %tracker_step_values = (
	pending => 1,
	processing => 2,
	completed => 3,
	notified => 4
);
my %sequence_checks = (
	min_fragment_hits => 100,
	max_novel_fragments => 1000,
);


################
# MAIN
################

# Initialization
init($config);

INFO "\n\t***Start of analysis pipeline run***";

# Place lock
remove_lock() if $remove_lock;
place_lock();


# Find new sequences
my @tracking_ids = check_uploads();

if(@tracking_ids) {
	
	INFO scalar(@tracking_ids)." uploaded genomes to analyze.";
	INFO "Tracking IDs: ". join(', ',@tracking_ids);
	
	# Sync new genome files to analysis server
	&sync_to_analysis unless $test;
	
	# New sequences uploaded, initiate analysis job
	my ($job_id, $job_dir) = init_job();
	
	INFO "Job ID: $job_id";
	
	# Copy new sequence data into analysis directory
	my $meta_dir = $job_dir . '/meta/';
	my $fasta_dir = $job_dir . '/fasta/';
	my $opt_dir = $job_dir . '/opt/';
	my $vf_dir = $job_dir . '/vf/';
	my $pg_dir = $job_dir . '/pg/';
	
	foreach my $d ($meta_dir, $fasta_dir, $opt_dir, $vf_dir, $pg_dir) {
		mkdir $d or die "Unable to create directory $d ($!)";
	}

	my @genome_loading_args;
	my $update_job_sth = $dbh->prepare(SET_GENOME_JOB);
	foreach my $t (@tracking_ids) {
		# Locate opt file
		my $opt_file = $input_dir . "genodo-options-$t.cfg";
		
		die "Option file for tracking ID $t not found (file:$opt_file)." unless -e $opt_file;
		
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
		
		push @genome_loading_args, [$t, $new_opt_file];
		
		# Change status of genome to 'in progress'
		$update_step_sth->execute($tracker_step_values{processing}, $t);
		$update_job_sth->execute($job_id,$t);
		
	}
	INFO "New data copied to analysis directory.";
	
	# Check for vf and amr fasta files
	my $qg_dir = $data_directory . 'vf_amr_sequences/';
	my $vf_fasta_file = $qg_dir . 'query_genes.ffn';
	unless(-e $vf_fasta_file) {
		die "AMR/VF gene fasta file missing. Please run:\n".
		"Database/query_gene_fasta.pl --config genodo.cfg --combined $vf_fasta_file.";
	}
	INFO "VF/AMR query gene file detected.";
	
	# Run VF/AMR detection analysis
	vf_analysis($vf_dir, $fasta_dir);
	
	# Re-build MSAs and trees
	align($vf_dir.'/panseq_vf_amr_results/locus_alleles.fasta', $vf_dir);
	
	# Check genome directory is up-to-date
	my $pg_dir1 = $data_directory . 'pangenome_fragments/';
	my $pg_dir2 = $data_directory . 'current_pangenome/';
	my $pg_file = $pg_dir2 . 'pan-genomes.ffn';
	my $core_file = $pg_dir1 . 'core-genomes.ffn';
	my $acc_file = $pg_dir1 . 'accessory-genomes.ffn';
	download_pangenomes($pg_file, $core_file, $acc_file);
	
	# Identify any novel regions for new genomes
	my ($nr_anno_file, $nr_sequences);
	($pg_file, $nr_anno_file, $nr_sequences) = novel_region_analysis($pg_dir, $fasta_dir, $pg_dir2, $pg_file);
	
	# Identify known pan-genome regions in new genomes
	INFO "Pan-genome region fasta file: $pg_file.";
	pangenome_analysis($pg_dir, $fasta_dir, $pg_file);
	
	# Validate sequences
	validate_sequences($nr_sequences,);
	
	# Re-build MSAs and trees for pan-genome fragments
	align($pg_dir.'/panseq_pg_results/locus_alleles.fasta', $pg_dir, 1, $nr_sequences);
	
	# Free up memory
	undef %$nr_sequences;
	
	# Load genome data
	load_genomes(\@genome_loading_args);
	
	# Load VF/AMR results
	load_vf($vf_dir);
	
	# Load pan-genome results
	load_pg($pg_dir);
	
	# Recompute the metadata JSON objects
	recompute_metadata();

	# Update individual genome records, notify users, remove tmp files
	close_out(\@tracking_ids);
	
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
	
	# Start logger
	my $log_dir = $conf->param('dir.log');
	my $logfile = ">>$log_dir/pipeline.log";
	$logfile = ">>/tmp/pipeline.log" if $test;
	Log::Log4perl->easy_init(
		{ 
			level  => ("$DEBUG"), 
			layout => "%P %d %p - %m%n", 
			file   => $logfile
		}
	);
	
	my $dbstring = 'dbi:Pg:dbname='.$conf->param('db.name').
	            ';port='.$conf->param('db.port').
	            ';host='.$conf->param('db.host');
	my $dbuser = $conf->param('db.user');
	my $dbpass = $conf->param('db.pass');
	die "Invalid configuration file. Missing db parameters." unless $dbuser;
	
	$input_dir = $conf->param('dir.seq');
	die "Invalid configuration file. Missing dir.seq parameters." unless $input_dir;
	
	$tmp_dir = $conf->param('tmp.dir');
	die "Invalid configuration file. Missing tmp.dir parameters." unless $tmp_dir;
	
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
	$data_directory = '/home/ubuntu/data/';
	$data_directory = '/home/matt/tmp/data/' if $test;
	$muscle_exe = '/usr/bin/muscle' if $test;
	$mummer_dir = '/home/matt/MUMmer3.23/' if $test;
	$blast_dir = '/home/matt/blast/bin/' if $test;
	$nr_location = '/panseq_results/blast_databases/nr_gammaproteobacteria';
	$nr_location = '/home/matt/blast_databases/nr_gammaproteobacteria' if $test;
	
	$update_step_sth = $dbh->prepare(UPDATE_GENOME);

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
	
	my $sth = $dbh->prepare(FIND_GENOMES);
	$sth->execute($tracker_step_values{pending}); # Step 2 = uploaded data printed to tmp directory
	
	my @tracking_ids;
	
	while (my $row = $sth->fetchrow_arrayref) {
		push @tracking_ids, $row->[0];
	}
	
	return @tracking_ids;	
}

=head2 sync_to_analysis

=cut

sub sync_to_analysis {
	
	# Run copy script
	my $cmd = "/home/ubuntu/sync/sync_local";
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Data sync'ed to analysis server";
	} else {
		die "Rsync of data director to analysis server failed ($stderr).";
	}
	
}

=head2 vf_analysis

Run panseq using VF and AMR genes as queryFile

=cut

sub vf_analysis {
	my ($vf_dir, $fasta_dir) = @_;
	
	# Create configuration file for panseq run
	
	my $pan_cfg_file = $vf_dir . 'vf.conf';
	my $fasta_file = $data_directory . 'vf_amr_sequences/query_genes.ffn';
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out 
qq|queryDirectory	$fasta_dir
queryFile	$fasta_file
baseDirectory	$vf_dir/panseq_vf_amr_results/
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
storeAlleles	1
addMissingQuery	1
nameOrId	name
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
	my ($job_dir, $fasta_dir, $pangenome_dir, $pangenome_file) = @_;

	# Create configuration file for panseq run
	
	my $pan_cfg_file = $job_dir . '/nr.conf';
	my $result_dir = "$job_dir/panseq_nr_results/";
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out 
qq|queryDirectory	$fasta_dir
referenceDirectory	$pangenome_dir
baseDirectory	$result_dir
numberOfCores	1
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
	
	# Check for new novel regions
	my $nr_fasta_file = $result_dir . 'novelRegions.fasta';
	my $nr_anno_file = $result_dir . 'anno.txt';
	if(-s $nr_fasta_file) {
		# New regions identified, need to add to file of pan-genome regions
		# And provide with consistent identifiable names
		
		my %nr_sequences;
		
		# Renaming
		my $renamed_file = $job_dir . '/pan-genomes.ffn';
		my $fasta = Bio::SeqIO->new(-file   => $nr_fasta_file,
                                    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $nr_fasta_file ($!).";
    
    	open my $out, ">", $renamed_file or die "Unable to write to file $renamed_file ($!).";
    	my $i = 1;
		while (my $entry = $fasta->next_seq) {
			my $seq = $entry->seq;
			my $header = "nr_$i";
			print $out ">$header\n$seq\n";
			$i++;
			$nr_sequences{$header} = $seq;
		}
		close $out;
		
		# Run blast on these new pangenome regions
		blast_new_regions($renamed_file, $nr_anno_file);
		
		# Add the pangenome regions currently in DB to pangenome file
		system("cat $pangenome_file >> $renamed_file") == 0 or die "Unable to concatentate old pangenome file $pangenome_file to new pangenome file $renamed_file ($!).\n";
		
		return($renamed_file, $nr_anno_file, \%nr_sequences);
	} else {
		# No new pangenome fragments found, can use existing pangenome file in next step
		return($pangenome_file, undef, undef);
	}
	
}

=head2 pangenome_analysis

Run panseq to identify existing/known pan-genome regions in new genomes

=cut

sub pangenome_analysis {
	my ($pg_dir, $fasta_dir, $pangenome_file) = @_;

	# Create configuration file for panseq run
	
	my $pan_cfg_file = $pg_dir . '/pg.conf';
	my $result_dir = "$pg_dir/panseq_pg_results/";
	
	open(my $out, '>', $pan_cfg_file) or die "Cannot write to file $pan_cfg_file ($!).\n";
	print $out
qq|queryDirectory	$fasta_dir
queryFile	$pangenome_file
baseDirectory	$result_dir
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
storeAlleles	1
addMissingQuery	0
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
	my $tmp_file = $tmp_dir . 'genodo-pipeline-tmp.ffn';
	
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


=head2 align

Alignments, tree building and SNP calculations are done in a separate script
run in parallel. This method prepares the inputs for the parallel script and
runs it.

=cut
sub align {
	my $allele_file = shift;
	my $root_dir = shift;
	my $is_pg = shift;
	my $nr_sequences = shift;
	
	my %fragment_counts;
	
	# Create directory tree for results/inputs
	my $new_dir = $root_dir . 'new/';
	my $fasta_dir = $root_dir . 'fasta/';
	my $tree_dir = $root_dir . 'tree/';
	my $perl_dir = $root_dir . 'perl_tree/';
	my $ref_dir = $root_dir . 'refseq/';
	my $snp_dir = $root_dir . 'snp_alignments/';
	my $pos_dir = $root_dir . 'snp_positions/';
	
	my @create_Ds = ($new_dir, $fasta_dir, $tree_dir, $perl_dir);
	push @create_Ds, ($ref_dir, $snp_dir, $pos_dir) if $is_pg;
	
	foreach my $d (@create_Ds)  {
		mkdir $d or die "Unable to create directory $d ($!)";
	}
	
	# Prepare queries
	my ($sql_type1, $sql_type2);
	if($is_pg) {
		$sql_type1 = 'locus';
		$sql_type2 = 'derives_from';
	} else {
		$sql_type1 = 'allele';
		$sql_type2 = 'similar_to';
	}
	
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
	
	my $pub_sth = $dbh->prepare($sql);
	my $pri_sth = $dbh->prepare($sql2);
	
	my $ref_sth;
	if($is_pg) {
		
		my $sql = 
		qq/SELECT f.residues, f.md5checksum
		FROM feature f, cvterm t
		WHERE f.type_id = t.cvterm_id AND
		t.name = 'pangenome' AND f.feature_id = ?
		/;

		$ref_sth = $dbh->prepare($sql);
	}
	
	# Keep record of alignment jobs
	my $job_file = $root_dir . "jobs.txt";
	open(my $rec, ">", $job_file) or die "Unable to write to file $job_file ($!)";

	# Iterate through query gene blocks
	open (my $in, "<", $allele_file) or die "Unable to read file $allele_file";
	local $/ = "\nLocus ";
	
	while(my $locus_block = <$in>) {
		$locus_block =~ s/^Locus //;
		my ($locus) = ($locus_block =~ m/^(\S+)/);
		my ($ftype, $query_id) = ($locus =~ m/(\w+_)*(\d+)/);
		my $is_nr = $ftype eq 'nr_' ? 1 : 0;
		
		if($is_nr) {
			$query_id = $locus;
		}
		
		# Number of alleles/loci
		my $num_seq = 0;
		
		# Retrieve the alignments for other sequences in the DB
		# If pangenome region is novel, don't need to do this.
		unless($is_nr) {
			my $msa_file = $fasta_dir . "$query_id.ffn";
			open(my $aln, ">", $msa_file) or die "Unable to write to file $msa_file ($!)";
			
			$pub_sth->execute($query_id);
			while(my $row = $pub_sth->fetchrow_arrayref) {
				my ($allele_id, $seq, $md5, $cc_id) = @$row;
				print $aln ">public_$cc_id|$allele_id\n$seq\n";
				$num_seq++;
			}
			
			$pri_sth->execute($query_id);
			while(my $row = $pri_sth->fetchrow_arrayref) {
				my ($allele_id, $seq, $md5, $cc_id) = @$row;
				print $aln ">private_$cc_id|$allele_id\n$seq\n";
				$num_seq++;
			}
			
			close $aln;
		}
		
		
		# Print the reference pangenome fragnment sequence (needed for SNP computation)
		if($is_pg) {
			my $ref_file = $ref_dir . "$query_id\_ref.ffn";
			open(my $ref, ">", $ref_file) or die "Unable to write to file $ref_file ($!)";
			
			my $refheader = "refseq_$query_id";
			my $refseq;
			if($is_nr) {
				$refseq = $nr_sequences->{$query_id};
	
			} else {
				$ref_sth->execute($query_id);
				($refseq, my $md5) = $ref_sth->fetchrow_array();
				WARN "Reference pangenome fragment $query_id has no loci in the DB." unless $num_seq;
			}
			
			die "Missing sequence for reference pangenome fragment $query_id." unless $refseq;
			
			print $ref ">$refheader\n$refseq\n";
			
			close $ref;
		}
		
		# Print the new alleles/loci added in this run
		my $prev_alns;
		my $aln_file;
		
		if($num_seq) {
			# Need to align new alleles/loci sequences with previous alignments 
			$aln_file = $new_dir . "$query_id.ffn";
			$prev_alns = 1;
		} else {
			# No previous alignments, just use current panseq alignment
			$aln_file = $fasta_dir . "$query_id.ffn";
			$prev_alns = 0;
		}
		
		open(my $seqo, ">", $aln_file) or die "Unable to write to file $aln_file ($!)";
		while($locus_block =~ m/\n>(\S+)\n(\S+)/g) {
			my $header = $1;
			my $seq = $2;
			
			$seq =~ tr/-//; # Remove gaps
			
			# Print to tmp file
			print $seqo ">$header\n$seq\n";
			
			# Track fragment counts to basic checks on uploaded sequences
			if($is_pg) {
				my $is_novel = $is_nr ? 'novel' : 'seen';
				$fragment_counts{$header}{$is_novel}++
			}
			
			$num_seq++;
		}
		close $seqo;
		
		# Record job
		my ($do_tree, $do_snp) = (0,0);
		# Build tree if enough allele sequences
		if($num_seq > 2) {
			$do_tree = 1;
		}
		if($num_seq > 1 && $is_pg && $ftype eq 'pgcor_') {
			$do_snp = 1;
		}
		print $rec join("\t", $query_id, $do_tree, $do_snp, $prev_alns)."\n";
		
	}
	close $in;
	close $rec;
	
	# Check sequence is not too novel and has some overlap with existing genomes
	if($is_pg) {
		foreach my $genome (keys %fragment_counts) {
			my $num_novel = $fragment_counts{$genome}{'novel'};
			my $num_overlap = $fragment_counts{$genome}{'seen'};
			die "Genome $genome has large portion that is novel in comparison to DB genomes ($num_novel novel genome fragments)."
				unless $num_novel < $sequence_checks{max_novel_fragments};
			die "Genome $genome has little overlap with other genomes in DB ($num_overlap genome fragment matches)."
				unless $num_overlap > $sequence_checks{min_fragment_hits};
		}
	}
	
	# Run parallel alignment program
	my @loading_args = ("perl $FindBin::Bin/../Sequences/parallel_tree_builder.pl",
		'--dir '.$root_dir);
			
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Parallel sequence alignment and tree building script completed successfully.";
	} else {
		die "Parallel sequence alignment and tree building script failed ($stderr).";
	}

}

=head2 download_pangenomes

Make sure the pan-genome files are up-to-date

=cut

sub download_pangenomes {
	my ($genome_file, $core_file, $acc_file) = @_;
	
	INFO "Downloading pangenome fragments into data directory file $genome_file.";
	
	# If there is no core pan-genomes file, download,
	# however this set is stable across runs
	unless (-e $core_file && -s $core_file) {
		my $sql = 
		qq/SELECT f.feature_id, f.residues
		FROM feature f, cvterm t1, cvterm t2, feature_cvterm ft
		WHERE f.type_id = t1.cvterm_id AND t1.name = 'pangenome'
		  AND f.feature_id = ft.feature_id AND ft.cvterm_id = t2.cvterm_id
		  AND t2.name = 'core_genome' AND ft.is_not = FALSE
		/;
		
		open my $out, ">", $core_file or die "Unable to write core pan-genome sequences to file $core_file ($!).";
		my $sth = $dbh->prepare($sql);
		
		# Retrieve core pan-genome fragments in DB
		$sth->execute();
		while(my ($id, $seq) = $sth->fetchrow_array) {
			$seq =~ s/-//g; # Remove gaps
			print $out ">pgcor_$id\n$seq\n";
		}
		
		close $out;
		
		INFO "Downloaded core pangenome fragments into file $core_file.";
		
	} else {
		INFO "Using core pangenomes in file $core_file.";
	}
	
	# Check if accessory genomes are up-to-date
	my $sql = 
	qq/SELECT f.feature_id
	FROM feature f, cvterm t1, cvterm t2, feature_cvterm ft
	WHERE f.type_id = t1.cvterm_id AND t1.name = 'pangenome'
	  AND f.feature_id = ft.feature_id AND ft.cvterm_id = t2.cvterm_id
	  AND t2.name = 'core_genome' AND ft.is_not = TRUE
	/;

	my $sql2 = 
	qq/SELECT f.feature_id, f.residues
	FROM feature f
	WHERE f.feature_id IN (
	/;

	my $sth1 = $dbh->prepare($sql);
	
	# Determine which accessory pan-genome fragments are missing
	my %genomes;
	my @missing;
	
	# Retrieve IDs for pan-genome loci in DB
	$sth1->execute();
	while(my ($id) = $sth1->fetchrow_array) {
		$genomes{$id}=0;
	}
	
	# Check against genomes in file
	if(-e $acc_file) {
		
		my $fasta = Bio::SeqIO->new(-file   => $acc_file,
                                    -format => 'fasta') or die "Unable to open Bio::SeqIO stream to $acc_file ($!).";
    
		while (my $entry = $fasta->next_seq) {
			my $seq = $entry->seq;
			my $header = $entry->display_id;
			
			my ($pg_id) = ($header =~ m/pgacc_(\d+)/);
			$genomes{$pg_id} = 1;
		}	
	}
	
	foreach my $id (keys %genomes) {
		push @missing, $id unless $genomes{$id};
	}
	
	
	my $num = scalar @missing;
	INFO "$num accessory pan-genome sequences need to be dowloaded.";
	
	if(@missing) {
		$sql2 .= join(',',@missing);
		$sql2 .= ')';
		my $sth2 = $dbh->prepare($sql2);
		$sth2->execute();
		
		open my $out, ">>", $acc_file or die "Unable to append to pangenome fasta file $acc_file ($!).";
		while(my ($pgid,$seq) = $sth2->fetchrow_array) {
			
			$seq =~ s/-//g; # Remove gaps
			print $out ">pgacc_$pgid\n$seq\n";
		}
		close $out;
	}
	INFO "New accessory pangenome sequences downloaded and appended to file $acc_file.";
	
	my $syscmd = "cat $core_file $acc_file > $genome_file";
	
	system($syscmd) == 0 or die "Unable to concatenate files $core_file and $acc_file into pangenome sequences file $genome_file ($!)";

	INFO "Pan-genome sequences in file $genome_file up-to-date.";
}

=head2 load_vf

Load the results from the panseq VF/AMR detection analysis

=cut

sub load_genomes {
	my $uploads = shift;
	
	# Load each genome into DB
	foreach my $tmparray (@$uploads) {
		my ($tracking_id, $optfile) = @$tmparray;
		my $opt = new Config::Simple($optfile) or die "Cannot read config file $optfile (" . Config::Simple->error() .')';
		
		# Run loading script
		my @loading_args = ("perl $FindBin::Bin/../Sequences/genodo_fasta_loader.pl", '--webupload',
			"--tracking_id $tracking_id",
			'--fasta '.$opt->param('load.fastafile'), 
			'--config '.$opt->param('load.configfile'),
			'--attributes '.$opt->param('load.propfile'));
	
		push @loading_args, '--noload' if $noload;
		push @loading_args, '--remove_lock' if $remove_lock;
		push @loading_args, '--recreate_cache' if $recover;

		my $cmd = join(' ',@loading_args);
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
		
		if($success) {
			INFO "Genome $tracking_id data loaded successfully."
		} else {
			die "Loading of Genome $tracking_id data failed ($stderr).";
		}
	}

	INFO "Loading of all genome data into DB completed.";
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
			
	push @loading_args, '--noload' if $noload;
	push @loading_args, '--remove_lock' if $remove_lock;
	push @loading_args, '--recreate_cache' if $recover;
	push @loading_args, '--save_tmpfiles' if $test;
	
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
	my $num_cores = 8;
	my $filesize = -s $new_fasta;
	my $blocksize = int($filesize/$num_cores)+1;
	$blocksize = $blocksize > 1500000 ? 1500000 : $blocksize;
	my $blast_cmd = "$blast_dir/blastx -evalue 0.0001 -outfmt ".'\"6 qseqid qlen sseqid slen stitle\" '."-db $nr_location -max_target_seqs 1 -query -";
	my $parallel_cmd = "cat $new_fasta | $parallel_exe --gnu -j $num_cores --block $blocksize --recstart '>' --pipe $blast_cmd > $blast_file";
	
	INFO "Running parallel BLAST: $parallel_cmd";
	
	#unless($test) {
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($parallel_cmd);
	
		if($success) {
			INFO "New pan-genome region BLAST job completed successfully."
		} else {
			die "New pan-genome region BLAST job failed ($stderr).";
		}
#	} else {
#		`touch $blast_file`;
#	}
	
}

=head2 load_pg

Load the results from the panseq pangenome analysis

=cut

sub load_pg {
	my $job_dir = shift;
	
	INFO "Loading pangenome into DB";
	
	my @loading_args = ("perl $FindBin::Bin/../Sequences/pipeline_pangenome_loader.pl",
		'--dir '.$job_dir, 
		'--config '.$config);
			
	push @loading_args, '--noload' if $noload;
	push @loading_args, '--remove_lock' if $remove_lock;
	push @loading_args, '--recreate_cache' if $recover;
	
	my $cmd = join(' ',@loading_args);
	my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
	
	if($success) {
		INFO "Pangenome data loaded successfully."
	} else {
		die "Loading of pangenome data failed ($stderr).";
	}
}

=head2 recompute_metadata 

Recompute the json objects that contain genomes and their properties

=cut

sub recompute_metadata {
	
	INFO "Loading Metadata into DB";
	
	unless($noload) {
		my @loading_args = ("perl $FindBin::Bin/../Database/load_meta_data.pl",
		'--config '.$config);
		
		my $cmd = join(' ',@loading_args);
		my ($stdout, $stderr, $success, $exit_code) = capture_exec($cmd);
		
		if($success) {
			INFO "Metadata JSON objects loaded successfully."
		} else {
			die "Loading of Metadata JSON objects failed ($stderr).";
		}
	}
}

=head2 close_out

Update status for individual uploads, email users, delete tmp files

=cut

sub close_out {
	my $tracking_ids = shift;
	
	INFO "Updating genome status in DB caches";
	
	my $close_sth = $dbh->prepare(CLOSE_GENOME);
	foreach my $tracker_id (@$tracking_ids) {
		$update_step_sth->execute($tracker_step_values{completed}, $tracker_id);
		$close_sth->execute($tracker_id);
	}
	
	INFO "Emailing users";
	send_email(2);
}

=head2 send_email

Call program that sends various email notifications - probably doesn't need to
be separate program

=cut
sub send_email {
	my $type = shift;
	
	my @loading_args = ('perl /home/genodo/computational_platform/Data/email_notification.pl',
		'--config /home/genodo/config/genodo.cfg', "--notify $type");
		
	if($test) {
		@loading_args = ('perl /home/matt/workspace/a_genodo/sandbox/Data/email_notification.pl',
		'--config /home/matt/workspace/a_genodo/config/genodo.cfg', "--notify $type")
	}
		
	my $cmd = join(' ',@loading_args);
	system($cmd);
}

=head2 error_handler

  Print error to log, send error flag to DB table and then send email notification

=cut

sub error_handler {
	# Log
	my $m = "Abnormal termination.";
	$m = "[ERROR] @_\n" if @_;
	FATAL("$m");
	warn "$m";
    
    # DB
    if ($dbh && $dbh->ping && $lock) {
        update_status(-1);
    }
    
    # Email
    if($email_notification) {
    	send_email(1);
    }
    
    # Exit
    exit(1);
}


