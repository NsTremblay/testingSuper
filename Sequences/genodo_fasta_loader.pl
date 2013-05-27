#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Adapter;
use Getopt::Long;
#use Data::Dumper;
use Pod::Usage;
use Carp;
#use URI::Escape;
use Sys::Hostname;
use Config::Simple;
use POSIX qw(strftime);

=head1 NAME

$0 - loads multi-fasta file into a genodo's chado database. Fasta file contains genomic or shotgun contig sequences.

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --fastafile       Fasta file to load sequence from
 --propfile        Data::Dumper file containing hash of parent genome properties
 --configfile      INI style config file containing DB connection parameters
 --noload          Create bulk load files, but don't actually load them.
 --recreate_cache  Causes the uniquename cache to be recreated
 --remove_lock     Remove the lock to allow a new process to run
 --save_tmpfiles   Save the temp files used for loading the database
 --manual          Detailed manual pages

=head1 DESCRIPTION



=head2 How Fasta is stored in chado

Here is summary of how GFF3 data is stored in chado:

=over

=item Column 1 (reference sequence)

The reference sequence for the feature becomes the srcfeature_id
of the feature in the featureloc table for that feature.  That featureloc 
generally assigned a rank of zero if there are other locations associated
with this feature (for instance, for a match feature), the other locations
will be assigned featureloc.rank values greater than zero.

=item Column 2 (source)

The source is stored as a dbxref.  The chado instance must of an entry
in the db table named 'GFF_source'.  The script will then create a dbxref
entry for the feature's source and associate it to the feature via
the feature_dbxref table.

=over

=item Assigning feature.name, feature.uniquename

The values of feature.name and feature.uniquename are assigned 
according to these simple rules:

=over 

=item If there is an ID tag, that is used as feature.uniquename

otherwise, it is assigned a uniquename that is equal to
'auto' concatenated with the feature_id.

=back

=item Assigning feature_relationship entries

All Parent tagged features are assigned feature_relationship
entries of 'part_of' to their parent features.  Derived_from
tags are assigned 'derived_from' relationships.  Note that
parent features must appear in the file before any features
use a Parent or Derived_from tags referring to that feature.

=item Alias tags

Alias values are stored in the synonym table, under
both synonym.name and synonym.synonym_sgml, and are
linked to the feature via the feature_synonym table.

=item Dbxref tags

Dbxref values must be of the form 'db_name:accession', where 
db_name must have an entry in the db table, with a value of 
db.name equal to 'DB:db_name'; several database names were preinstalled
with the database when 'make prepdb' was run.  Execute 'SELECT name
FROM db' to find out what databases are already availble.  New dbxref
entries are created in the dbxref table, and dbxrefs are linked to
features via the feature_dbxref table.

=back

=back

=head2 NOTES

=over

=item Loading fasta file

When the --fastafile is provided with an argument that is the path to
a file containing fasta sequence, the loader will attempt to update the
feature table with the sequence provided.  Note that the ID provided in the
fasta description line must exactly match what is in the feature table
uniquename field.  Be careful if it is possible that the uniquename of the
feature was changed to ensure uniqueness when it was loaded from the
original GFF.  Also note that when loading sequence from a fasta file, 
loading GFF from standard in is disabled.  Sorry for any inconvenience.

=item Transactions

This application will, by default, try to load all of the data at
once as a single transcation.  This is safer from the database's
point of view, since if anything bad happens during the load, the 
transaction will be rolled back and the database will be untouched.  
The problem occurs if there are many (say, greater than a 2-300,000)
rows in the GFF file.  When that is the case, doing the load as 
a single transcation can result in the machine running out of memory
and killing processes.  If --notranscat is provided on the commandline,
each table will be loaded as a separate transaction.

=item The run lock

The bulk loader is not a multiuser application.  If two separate
bulk load processes try to load data into the database at the same
time, at least one and possibly all loads will fail.  To keep this from
happening, the bulk loader places a lock in the database to prevent
other gmod_bulk_load_gff3.pl processes from running at the same time.
When the application exits normally, this lock will be removed, but if
it crashes for some reason, the lock will not be removed.  To remove the
lock from the command line, provide the flag --remove_lock.  Note that
if the loader crashed necessitating the removal of the lock, you also
may need to rebuild the uniquename cache (see the next section).

=item The uniquename cache

The loader uses the chado database to create a table that caches
feature_ids, uniquenames, type_ids, and organism_ids of the features
that exist in the database at the time the load starts and the
features that will be added when the load is complete.  If it is possilbe
that new features have been added via some method that is not this
loader (eg, Apollo edits or loads with XORT) or if a previous load using
this loader was aborted, then you should supply
the --recreate_cache option to make sure the cache is fresh.

=item Sequence

By default, if there is sequence in the GFF file, it will be loaded
into the residues column in the feature table row that corresponds
to that feature.  By supplying the --nosequence option, the sequence
will be skipped.  You might want to do this if you have very large
sequences, which can be difficult to load.  In this context, "very large"
means more than 200MB.

Also note that for sequences to load properly, the GFF file must have
the ##FASTA directive (it is required for proper parsing by Bio::FeatureIO),
and the ID of the feature must be exactly the same as the name of the
sequence following the > in the fasta section.

=back

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Adapted from original package developed by 
Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($CONFIGFILE, $FASTAFILE, $PROPFILE, $NOLOAD,
    $RECREATE_CACHE, $SAVE_TMPFILES,
    $MANPAGE, $DEBUG,
    $REMOVE_LOCK,
    $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $DBI,
    $VACUUM,
    $WEBUPLOAD);

GetOptions(
	'configfile=s'=> \$CONFIGFILE,
    'fastafile=s'=> \$FASTAFILE,
    'propfile=s'=> \$PROPFILE,
    'noload'     => \$NOLOAD,
    'recreate_cache'=> \$RECREATE_CACHE,
    'remove_lock'   => \$REMOVE_LOCK,
    'save_tmpfiles'=>\$SAVE_TMPFILES,
    'manual'   => \$MANPAGE,
    'debug'   => \$DEBUG,
    'vacuum'  => \$VACUUM,
    'webupload' => \$WEBUPLOAD
) 

or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 2, -exitval => 1) if $MANPAGE;

$SIG{__DIE__} = $SIG{INT} = 'cleanup_handler';

croak "You must supply an fasta filename" unless $FASTAFILE;

# Load database connection info from config file
die "You must supply a configuration filename" unless $CONFIGFILE;
if(my $db_conf = new Config::Simple($CONFIGFILE)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
} else {
	die Config::Simple->error();
}
croak "Invalid configuration file." unless $DBNAME;

# Load the hash containing parent genome feature properties
# Values defined in the user form
croak "You must supply a genome properties filename" unless $PROPFILE;
my ($genome_feature_properties, $upload_params) = load_input_parameters($PROPFILE);

my ($f, $fp, $dx) = validate_genome_properties($genome_feature_properties);

# Initialize the chado adapter
my %argv;

  $argv{fastafile}      = $FASTAFILE;
  $argv{dbname}         = $DBNAME;
  $argv{dbuser}         = $DBUSER;
  $argv{dbpass}         = $DBPASS;
  $argv{dbhost}         = $DBHOST;
  $argv{dbport}         = $DBPORT;
  $argv{dbi}            = $DBI;
  $argv{noload}         = $NOLOAD;
  $argv{recreate_cache} = $RECREATE_CACHE;
  $argv{save_tmpfiles}  = $SAVE_TMPFILES;
  $argv{web_upload}     = $WEBUPLOAD;
  $argv{vacuum}         = $VACUUM;
  $argv{debug}          = $DEBUG;
  
my $chado = Sequences::Adapter->new(%argv);


# Lock table so no one else can upload
$chado->remove_lock() if $REMOVE_LOCK;
$chado->place_lock();
my $lock = 1;


# Prepare tmp files for storing upload data
$chado->file_handles();


# Save data for inserting into database
warn "Preparing data for inserting into the $DBNAME database\n";
warn "(This may take a while ...)\n";

## Create upload entry, if private?
if($WEBUPLOAD) {
	validate_upload_parameters($upload_params);
	
	$chado->handle_upload(category     => $upload_params->{category},
	                      upload_date  => $upload_params->{upload_date},
	                      login_id     => $upload_params->{login_id},
	                      release_date => $upload_params->{release_date},
	                      tag          => $upload_params->{tag});
}


# Create parent feature: contig_collection
contig_collection($f, $fp, $dx);


# Create child features from FASTA file (i.e. contigs)
my $in = Bio::SeqIO->new(-file   => $FASTAFILE,
                         -format => 'fasta');
                              
while (my $entry = $in->next_seq) {
	
	contig($entry);
}


# Finalize and load into DB

$chado->end_files();

$chado->flush_caches();

$chado->load_data() unless $NOLOAD;

$chado->remove_lock();

exit(0);


=cut

=head2 cleanup_handler

=over

=item Usage

  cleanup_handler

=item Function

Removes table lock and any entries added to the uniquename change in tmp table.

=item Returns

void

=item Arguments

filename of Data::Dumper file containing data hash.

=back

=cut

sub cleanup_handler {
    warn "@_\nAbnormal termination, trying to clean up...\n\n" if @_;  #gets the message that the die signal sent if there is one
    if ($chado && $chado->dbh->ping) {
        
        $chado->cleanup_tmp_table;
        if ($lock) {
            warn "Trying to remove the run lock (so that --remove_lock won't be needed)...\n";
            $chado->remove_lock; #remove the lock only if we've set it
        }
        
        print STDERR "Exiting...\n";
    }
    exit(1);
}

=cut

=head2 load_input_parameters

=over

=item Usage

  my $properties_hash = load_input_parameters($filename)

=item Function

loads hash produced by Data::Dumper with genome properties and upload user settings.

=item Returns

A hash of containing property types and values

=item Arguments

filename of Data::Dumper file containing data hash.

=back

=cut

sub load_input_parameters {
	my $file = shift;
	
	open(IN, "<$PROPFILE") or die "Error: unable to read file $PROPFILE ($!).\n";

    local($/) = "";
    my($str) = <IN>;
    
    close IN;
    
    my $contig_collection_properties;
    my $upload_parameters;
    eval $str;
    
    return ($contig_collection_properties, $upload_parameters);
}

=head2 validate_genome_properties

=over

=item Usage

  my $rv = validate_genome_properties($hash_ref)

=item Function

Examines data hash containing genome properties.
Makes sure keys are recognized and then splits data
into separate hashes corresponding to each DB table.

=item Returns

List of 3 data hashrefs contains key value pairs of:
1. Feature table properties
2. Featureprop table properties
3. Dbxref table properties

=item Arguments

A hashref containing all input parameters

=back

=cut

sub validate_genome_properties {
	my $hash = shift;
	
	my %valid_f_tags = qw/name 1 uniquename 1 organism 1 properties 1/;
	my %valid_fp_tags = qw/mol_type 1 serotype 1 strain 1 keywords 1 isolation_host 1 
		isolation_location 1 isolation_date 1 description 1 owner 1 finished 1 synonym 1/;
	my %valid_dbxref_tags = qw/primary_dbxref 1 secondary_dbxref 1/;
	
	# Make sure no unrecognized property types
	# Assign value to proper table hash
	my %f; my %fp; my %dx;
	foreach my $type (keys %$hash) {
		
		if($valid_f_tags{$type}) {
			$f{$type} = $hash->{$type};
			
		} elsif($valid_fp_tags{$type}) {
			$fp{$type} = $hash->{$type};
			
		} elsif($valid_dbxref_tags{$type}) {
			# Must supply hash with keys: acc, db
			# Optional: ver, desc
			
			my @entries;
			
			if(ref $hash->{$type} eq 'ARRAY') {
				@entries = @{$hash->{$type}}
			} else {
				@entries = ($hash->{$type});
			}
			
			foreach my $dbxref (@entries) {
				my $db = $dbxref->{db};
				croak 'Must provide a DB for foreign IDs.' unless $db;
				
				my $acc = $dbxref->{acc};
				croak 'Must provide a accession for foreign IDs.' unless $acc;
				
				my $ver = $dbxref->{ver};
				$ver ||= 1;
				
				my $desc = $dbxref->{desc};
				$desc ||= 1;
				
				if($type eq 'primary_dbxref') {
					croak 'Primary foreign ID re-defined.' if defined($dx{primary});
					$dx{primary} = { db => $db, acc => $acc, ver => $ver, desc => $desc };
				} else {
					$dx{secondary} = [] unless $dx{secondary};
					push @{$dx{secondary}}, { db => $db, acc => $acc, ver => $ver, desc => $desc };
				}
			}
			
		} else {
			croak "Invalid genome property type $type.";
		}
	}
	
	# Required types, no default values.
	croak 'Missing required genome property "uniquename".' unless $f{uniquename};
	croak 'Missing primary foreign ID (only required when secondary foreign ID defined)' if defined($dx{secondary}) && !defined($dx{primary});
	
	
	# Initialize other required properties with default values
	$f{name} = $f{uniquename} unless $f{name};
	$f{organism} = 'Escherichia coli' unless $f{organism};
	$fp{mol_type} = 'dna' unless $fp{mol_type};
	
	return(\%f, \%fp, \%dx);
}

=head2 validate_upload_parameters

=over

=item Usage

  my $rv = validate_upload_parameters
=item Function

Examines data hash containing upload parameters.

=item Returns

Also initializes some required parameters
that have default values in the hash ref.

=item Arguments

Ref to data hash

=back

=cut

sub validate_upload_parameters {
	my $hash = shift;
	
	my @valid_parameters = qw/login_id tag release_date upload_date category/;
		
	my %valid;
	map { $valid{$_} = 1 } @valid_parameters;
	
	# Make sure no unrecognized parameters
	foreach my $type (keys %$hash) {
		croak "Invalid upload parameter $type." unless $valid{$type};
	}
	
	# Required parameters, no default values.
	croak 'Missing required upload parameter "category".' unless $hash->{category};
	my %valid_cats = (public => 1, private => 1, release => 1);
	croak "Invalid category: ".$hash->{category} unless $valid_cats{$hash->{category}};
	
	if($hash->{category} eq 'release') {
		croak 'Missing required upload parameter "release_date".' unless $hash->{release_date};
	}
	
	# Set default parameters
	$hash->{login_id} = 0 unless $hash->{login_id};
	
	unless($hash->{upload_date}) {
		my $date = strftime "%Y-%m-%d %H:%M:%S", localtime;
		$hash->{upload_date} = $date;
	}
	$hash->{tag} = 'Unclassified' unless $hash->{tag};
	
	return(1);
}

=head2 contig_collection


=cut

sub contig_collection {
	my ($f, $fp, $dx) = @_;
	
	# Make sure organism is one of the permitted Organisms
	$chado->organism('common_name' => $f->{organism});
	
	# Feature type of parent: contig_collection
	my $type = $chado->feature_types('contig_collection');
	
	# Feature_id 
	my $curr_feature_id = $chado->nextfeature();
	
	# Uniquename
	my $uniquename = $f->{'uniquename'};
	
	# Verifies if name is unique, otherwise modify uniquename so that it is unique.
	$uniquename = $chado->uniquename_validation($uniquename,
		$type,
	    $curr_feature_id);
	    
	## Note uniquename may have changed and changed name will have been cached. Do we need to know original?
	
	# Name
	my $name = $f->{name};
	
	# Sequence Length
	my $seqlen = '\N';
	# Residues
	my $residues = '\N';
	
	
	# Properties
	if(%$fp) {
		$chado->handle_reserved_properties($curr_feature_id, $fp);
	}
	
	
	# Dbxref
	if(%$dx) {
		$chado->handle_dbxref($curr_feature_id, $dx);
	}
	
	
	# Save as parent
	$chado->cache('const', 'contig_collection_id', $curr_feature_id);
	$chado->cache('const', 'contig_collection_uniquename', $uniquename);
	
	# Print  
	$chado->print_f($curr_feature_id, $chado->organism, $name, $uniquename, $type, $seqlen, $chado->cache('source', $curr_feature_id), $residues);  
	$chado->nextfeature('++');
	
}

=head2 contig


=cut

sub contig {
	my ($contig) = @_;
	
	# Feature type of child: contig
	my $type = $chado->feature_types('contig');
	
	
	# Feature_id 
	my $curr_feature_id = $chado->nextfeature();
	
	
	# Uniquename and name
	my $uniquename = $contig->display_id;
	my $name = $uniquename;
	
	# Create unique contig name derived from contig_collection uniquename
	# Since contig_collection uniquename is guaranteed unique, contig name should be unique.
	# Saves us from doing a DB query on the many contigs that could be in the fasta file.
	my $cc_name = $chado->cache('const','contig_collection_uniquename');
	$uniquename .= "- part_of:$cc_name";
	

	# Sequence Length
	my $seqlen = $contig->length;
	# Residues
	my $residues = $contig->seq();
	
	
	# DBxref
	my $dbxref = '\N';
	
	
	# Contig properties
	my %contig_fp;
	
	# mol_type
	# if plasmid or chromosome is in header, change default
	my $mol_type = 'dna';
	
	# description
	if(my $desc = $contig->description) {
		# if plasmid or chromosome is in header, change default
		if($desc =~ m/plasmid/i || $name =~ m/plasmid/i) {
			$mol_type = 'plasmid';
		} elsif($desc =~ m/chromosome/i || $name =~ m/chromosome/i) {
			$mol_type = 'chromosome';
		}
	
		$contig_fp{description} = $desc if $desc;
	} else {
		if($name =~ m/plasmid/i) {
			$mol_type = 'plasmid';
		} elsif($name =~ m/chromosome/i) {
			$mol_type = 'chromosome';
		}
	}
	$contig_fp{mol_type} = $mol_type;
	
	$chado->handle_reserved_properties($curr_feature_id, \%contig_fp);
	
	
	# Feature relationships
	$chado->handle_parent($curr_feature_id);
	
	
	# Print  
	$chado->print_f($curr_feature_id, $chado->organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues);  
	$chado->nextfeature('++');
}