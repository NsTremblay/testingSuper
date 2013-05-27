package Sequences::Adapter;

use strict;
use warnings;

use DBI;
use Carp qw/croak carp confess/;
use Sys::Hostname;
use File::Temp;

=head1 NAME

Sequences::Adapter

=head1 DESCRIPTION

Based on perl package: Bio::GMOD::DB::Adapter

Provides interface to CHADO database for loading a series of contigs in a multi-fasta file into the database.

Our situation (of only loading a series of 1 or more contig/genomic sequences) is much simplier than the standard CHADO loading scheme.
It allows us to make a number of simplifications over the original Adapter package.

=cut

# Calling program name
my $calling_program = 'genodo_fasta_loader.pl';

my $DEBUG = 0;

# Tables in order that data is inserted
my @tables = (
	"upload",
	"permission",
	"feature",
	"feature_relationship",
	"featureprop",
	"db",
	"dbxref",
	"feature_dbxref"
);

# To allow certain tables to point to the private versions
my %table_names = (
	"upload"               => "upload",
	"permission"           => "permission",
	"feature"              => "feature",
	"feature_relationship" => "feature_relationship",
	"featureprop"          => "featureprop",
	"db"                   => "db",
	"dbxref"               => "dbxref",
	"feature_dbxref"       => "feature_dbxref"
);


# Primary key sequence names
my %sequences = (
   feature              => "feature_feature_id_seq",
   feature_relationship => "feature_relationship_feature_relationship_id_seq",
   featureprop          => "featureprop_featureprop_id_seq",
   upload               => "upload_upload_id_seq",
   db                   => "db_db_id_seq",
   dbxref               => "dbxref_dbxref_id_seq",
   feature_dbxref       => "feature_dbxref_feature_dbxref_id_seq",
   permission           => "permission_permission_id_seq"
);

# Primary key ID names
my %table_ids = (
	feature              => "feature_id",
	feature_relationship => "feature_relationship_id",
	featureprop          => "featureprop_id",
	db                   => "db_id",
	dbxref               => "dbxref_id",
	feature_dbxref       => "feature_dbxref_id",
	upload               => "upload_id",
	permission           => "permission_id"
);

# Valid cvterm types for featureprops table
# hash: name => cv
my %fp_types = (
	mol_type => 'feature_property',
	keywords => 'feature_property',
	description => 'feature_property',
	owner => 'feature_property',
	finished => 'feature_property',
	strain => 'local',
	serotype => 'local',
	isolation_host => 'local',
	isolation_location => 'local',
	isolation_date => 'local',
	synonym => 'feature_property'
);

# Used in DB COPY statements
my %copystring = (
   feature              => "(feature_id,organism_id,name,uniquename,type_id,seqlen,dbxref_id,residues)",
   feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   featureprop          => "(featureprop_id,feature_id,type_id,value,rank)",
   dbxref               => "(dbxref_id,db_id,accession,version,description)",
   feature_dbxref       => "(feature_dbxref_id,feature_id,dbxref_id)",
   db                   => "(db_id,name,description)",
   upload               => "(upload_id,login_id,category,tag,release_date,upload_date)",
   permission           => "(permission_id,upload_id,login_id,can_modify,can_share)"
);


# Valid organism common names
my @organisms = (
	'Escherichia coli'
);

# Key values for uniquename cache
my $ALLOWED_UNIQUENAME_CACHE_KEYS = "feature_id|type_id|uniquename|validate";
               
# Tables for which caches are maintained
my $ALLOWED_CACHE_KEYS = "db|dbxref|feature|source|const";

# Tmp file names for storing upload data
my %files = map { $_ => 'FH'.$_; } @tables; # SEQ special case in feature table

# SQL for unique cache
use constant CREATE_CACHE_TABLE =>
               "CREATE TABLE public.tmp_gff_load_cache (
                    feature_id int,
                    uniquename varchar(1000),
                    type_id int,
                    organism_id int
                )";
use constant DROP_CACHE_TABLE =>
               "DROP TABLE public.tmp_gff_load_cache";
use constant VERIFY_TMP_TABLE =>
               "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
use constant POPULATE_CACHE_TABLE =>
               "INSERT INTO public.tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id FROM feature";
use constant POPULATE_PRIVATE_CACHE_TABLE =>
               "INSERT INTO public.tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id FROM private_feature";
use constant CREATE_CACHE_TABLE_INDEX1 =>
               "CREATE INDEX tmp_gff_load_cache_idx1 
                    ON public.tmp_gff_load_cache (feature_id)";
use constant CREATE_CACHE_TABLE_INDEX2 =>
               "CREATE INDEX tmp_gff_load_cache_idx2 
                    ON public.tmp_gff_load_cache (uniquename)";
use constant CREATE_CACHE_TABLE_INDEX3 =>
               "CREATE INDEX tmp_gff_load_cache_idx3
                    ON public.tmp_gff_load_cache (uniquename,type_id,organism_id)";
use constant TMP_TABLE_CLEANUP =>
               "DELETE FROM tmp_gff_load_cache WHERE feature_id >= ?";
                    
# SQL for lock table
use constant CREATE_META_TABLE =>
               "CREATE TABLE gff_meta (
                     name        varchar(100),
                     hostname    varchar(100),
                     starttime   timestamp not null default now() 
                )";
use constant SELECT_FROM_META =>
               "SELECT name,hostname,starttime FROM gff_meta";
use constant INSERT_INTO_META =>
               "INSERT INTO gff_meta (name,hostname) VALUES (?,?)";
use constant DELETE_FROM_META =>
               "DELETE FROM gff_meta WHERE name = ? AND hostname = ?";
               
# SQL for validating uniquename
use constant VALIDATE_TYPE_ID =>
               "SELECT feature_id FROM public.tmp_gff_load_cache
                    WHERE type_id = ? AND uniquename = ?";
use constant VALIDATE_UNIQUENAME =>
               "SELECT feature_id FROM public.tmp_gff_load_cache WHERE uniquename = ?";
use constant INSERT_CACHE_TYPE_ID =>
               "INSERT INTO public.tmp_gff_load_cache 
                  (feature_id,uniquename,type_id) VALUES (?,?,?)";
use constant INSERT_CACHE_UNIQUENAME =>
               "INSERT INTO public.tmp_gff_load_cache (feature_id,uniquename)
                  VALUES (?,?)";
                  
# SQL for validating DBxrefs
use constant SEARCH_DB =>
               "SELECT db_id FROM db WHERE name =?";
use constant SEARCH_LONG_DBXREF => 
               "SELECT dbxref_id FROM dbxref WHERE accession =?
                                                  AND version =?
                                                  AND db_id =?";
               

sub new {
	my $class = shift;
    my %arg   = @_;

    my $self  = bless {}, ref($class) || $class;

    my $dbname = $arg{dbname};
    my $dbport = $arg{dbport};
    my $dbhost = $arg{dbhost};
    my $dbuser = $arg{dbuser};
    my $dbpass = $arg{dbpass};
    my $skipinit=0;
   
	my $dbh = DBI->connect(
        "dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
        $dbuser,
        $dbpass,
        {AutoCommit => 0,
         TraceLevel => 0}
    ) or croak "Unable to connect to database";

    $self->dbh($dbh);

    $self->dbname(          $arg{dbname}          );
    $self->dbport(          $arg{dbport}          ); 
    $self->dbhost(          $arg{dbhost}          );
    $self->dbuser(          $arg{dbuser}          );
    $self->dbpass(          $arg{dbpass}          );
    $self->noload(          $arg{noload}          );
    $self->recreate_cache(  $arg{recreate_cache}  );
    $self->save_tmpfiles(   $arg{save_tmpfiles}   );
    $self->vacuum(          $arg{vacuum}          );
  
    $self->prepare_queries();
    unless ($skipinit) {
    	$self->initialize_sequences();
        $self->initialize_ontology();
        $self->initialize_organism();
        $self->initialize_uniquename_cache();
    }
    
    # All genomes uploaded by users (whether released as public or private by user)
    # are stored in the private_feature and private_featureprop tables.
    if($arg{web_upload}) {
    	# Genomes are being uploaded in the private feature and
    	# featureprop tables.
    	# Need to change some resources to point to these tables.
    	
    	$table_names{feature} = 'private_' . $table_names{feature};
    	$table_names{featureprop} = 'private_' . $table_names{featureprop};
    	$table_names{feature_relationship} = 'private_' . $table_names{feature_relationship};
    	$table_names{feature_dbxref} = 'private_' . $table_names{feature_dbxref};
    	$sequences{feature} = 'private_' . $sequences{feature};
    	$sequences{featureprop} = 'private_' . $sequences{featureprop};
    	$sequences{feature_dbxref} = 'private_' . $sequences{feature_dbxref};
    	$sequences{feature_relationship} = 'private_' . $sequences{feature_relationship};
    	
    	my $num = ($copystring{feature} =~ s/,residues\)/,upload_id,residues\)/);
    	croak "Unexpected format in feature copystring." unless $num == 1;
    	$num = ($copystring{featureprop} =~ s/,rank\)/,rank,upload_id\)/);
    	croak "Unexpected format in featureprop copystring." unless $num == 1;
    	
    	$self->{web_upload} = 1;
    	
    } else {
    	
    	$self->{web_upload} = 0;
    }
    
    $DEBUG = 1 if $arg{debug};

    return $self;
}

#################
# Initialization
#################

=head2 initialize_ontology

=over

=item Usage

  $obj->initialize_ontology()

=item Function

Initializes cvterm IDs for commonly used types

These are static and predefined.

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_ontology {
    my $self = shift;
    
    # Commonly used cvterms
    my $fp_sth = $self->dbh->prepare("SELECT t.cvterm_id FROM cvterm t, cv v WHERE t.name = ? AND v.name = ? AND t.cv_id = v.cv_id"); 

	# Part of ID
	$fp_sth->execute('part_of', 'relationship');
    my ($part_of) = $fp_sth->fetchrow_array();

    # Contig collection ID
    $fp_sth->execute('contig_collection', 'sequence');
    my ($contig_col) = $fp_sth->fetchrow_array();
    
    # Contig ID
    $fp_sth->execute('contig', 'sequence');
    my ($contig) = $fp_sth->fetchrow_array();
    
    $self->{feature_types} = {
    	contig_collection => $contig_col,
    	contig => $contig
    };
    
	$self->{relationship_types} = {
    	part_of => $part_of,
    };
    
    # Feature property types
    foreach my $type (keys %fp_types) {
    	my $cv = $fp_types{$type};
    	$fp_sth->execute($type, $cv);
    	my ($cvterm_id) = $fp_sth->fetchrow_array();
    	croak "Featureprop cvterm type $type not in database." unless $cvterm_id;
    	$self->{featureprop_types}->{$type} = $cvterm_id;
    }

    return;
}

=head2 initialize_organism

=over

=item Usage

  $obj->initialize_organism()

=item Function

Initializes organism IDs for commonly used organisms

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_organism {
    my $self = shift;
    
    # Commonly used cvterms
    my $o_sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE common_name = ?"); 
    
    # Feature property types
    foreach my $common_name (@organisms) {
    	$o_sth->execute($common_name);
    	my ($o_id) = $o_sth->fetchrow_array();
    	croak "Organism with common name $common_name not in database." unless $o_id;
    	$self->{organisms}->{$common_name} = $o_id;
    }

    return;
}


=head2 initialize_sequences

=over

=item Usage

  $obj->initialize_sequences()

=item Function

Initializes sequence counter variables

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_sequences {
    my $self = shift;

    foreach my $table (@tables) {
      my $sth = $self->dbh->prepare("select nextval('$sequences{$table}')");
      $sth->execute;
      my ($nextoid) = $sth->fetchrow_array();
      $self->nextoid($table, $nextoid);
      print "$table, $nextoid\n" if $DEBUG;
    }
    return;
}


=head2 update_sequences

=over

=item Usage

  $obj->update_sequences()

=item Function

Checks the maximum value of the primary key of the sequence's table
and modifies the nextval of the sequence if they are out of sync.
It then (re)initializes the sequence cache.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub update_sequences {
    my $self = shift;

	foreach my $table (@tables) {

		my $id_name      = $table_ids{$table};
		my $max_id_query = "SELECT max($id_name) FROM $table";
		my $sth          = $self->dbh->prepare($max_id_query);
		$sth->execute;
		my ($max_id)     = $sth->fetchrow_array();
		
		my $curval_query = "SELECT nextval('$sequences{$table}')";
		$sth             = $self->dbh->prepare($curval_query);
		$sth->execute;
		my ($curval)     = $sth->fetchrow_array();      
		
		if ($max_id > $curval) {
		    my $setval_query = "SELECT setval('$sequences{$table}',$max_id)";
		    $sth             = $self->dbh->prepare($setval_query);
		    $sth->execute;
		    
		    $self->nextoid($table, ++$max_id);
		    
		} else {
			$self->nextoid($table, $curval);
		}
	}

    return;
}



=head2 initialize_uniquename_cache

=over

=item Usage

  $obj->initialize_uniquename_cache()

=item Function

Creates the uniquename cache tables in the database

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_uniquename_cache {
    my $self = shift;

    #determine if the table already exists
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('tmp_gff_load_cache');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists || $self->recreate_cache() ) {
        print STDERR "(Re)creating the uniquename cache in the database... ";
        $dbh->do(DROP_CACHE_TABLE) if ($self->recreate_cache() and $table_exists);

        print STDERR "\nCreating table...\n";
        $dbh->do(CREATE_CACHE_TABLE);

        print STDERR "Populating table...\n";
        $dbh->do(POPULATE_CACHE_TABLE);
        $dbh->do(POPULATE_PRIVATE_CACHE_TABLE);

        print STDERR "Creating indexes...\n";
        $dbh->do(CREATE_CACHE_TABLE_INDEX1);
        $dbh->do(CREATE_CACHE_TABLE_INDEX2);
        $dbh->do(CREATE_CACHE_TABLE_INDEX3);
        
		print STDERR "Adjusting the primary key sequences (if necessary)...";
        $self->update_sequences();
        print STDERR "Done.\n";

        $dbh->commit;
    }
    return;
}


#################
# Files
#################


=head2 file_handles

=over

=item Usage

  $obj->file_handles()

=item Function

Creates and keeps track of file handles for temp files

=item Returns

On create, void.  With an arguement, returns the requested file handle

=item Arguments

If the 'short hand' name of a file handle is given, returns the requested
file handle.  The short hand file names are 'FH'.$tablename

=back

=cut

sub file_handles {
    my ($self, $argv) = @_;

    if ($argv && $argv ne 'close') {
        my $fhhame= ($argv =~ /^FH/) ? $argv : 'FH'.$argv;
        return $self->{file_handles}{$fhhame};
    }
    else {
        my $file_path = "./";
     
        for my $key (keys %files) {
            my $tmpfile = new File::Temp(
                                 TEMPLATE => "chado-$key-XXXX",
                                 SUFFIX   => '.dat',
                                 UNLINK   => $self->save_tmpfiles() ? 0 : 1, 
                                 DIR      => $file_path,
                                );
			chmod 0644, $tmpfile;
			$self->{file_handles}{$files{$key}} = $tmpfile;         
        }
        return;
    }
}

=head2 end_files

=over

=item Usage

  $obj->end_files()

=item Function

Appends proper bulk load terminators

=item Returns

void

=item Arguments

none

=back

=cut

sub end_files {
	my $self = shift;

	foreach my $file (@tables) {
		my $fh = $self->file_handles($files{$file});
		print $fh "\\.\n\n";
	}
    
}

=head2 flush_caches

=over

=item Usage

  $obj->flush_caches()

=item Function

Initiate garbage collection?

=item Returns

void

=item Arguments

none

=back

=cut

sub flush_caches {
    my $self = shift;

    $self->{cache}            = '';
    $self->{uniquename_cache} = '';

    return;
}

#################
# Database
#################

=head2 nextoid

=over

=item Usage

  $obj->nextoid($table)        #get existing value
  $obj->nextoid($table,$newval) #set new value

=item Function

=item Returns

value of next table id (a scalar)

=item Arguments

new value of next table id (to set)

=back

=cut

sub nextoid {  
  my $self = shift;
  my $table= shift;
  my $arg  = shift if defined(@_);
  
  if (defined($arg) && $arg eq '++') {
      return $self->{'nextoid'}{$table}++;
  } elsif (defined($arg)) {
      return $self->{'nextoid'}{$table} = $arg;
  }
  return $self->{'nextoid'}{$table} if ($table);
}


=head2 remove_lock

=over

=item Usage

  $obj->remove_lock()

=item Function

To remove the row in the gff_meta table that prevents other loading scripts from running while the current process is running.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub remove_lock {
    my ($self, %argv) = @_;

    my $dbh = $self->dbh;
    my $select_query = $dbh->prepare(SELECT_FROM_META) or carp "Select prepare failed";
    $select_query->execute() or carp "Select from meta failed";

    my $delete_query = $dbh->prepare(DELETE_FROM_META) or carp "Delete prepare failed";

    while (my @result = $select_query->fetchrow_array) {
        my ($name,$host,$time) = @result;

        if ($name =~ /$calling_program/) {
            $delete_query->execute($name,$host) or carp "Removing the lock failed!";
            $dbh->commit;
        }
    }

    return;
}


=head2 place_lock

=over

=item Usage

  $obj->place_lock()

=item Function

To place a row in the gff_meta table (creating that table if necessary) 
that will prevent other users/processes from doing GFF bulk loads while
the current process is running.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub place_lock {
    my ($self, %argv) = @_;

    # first determine if the meta table exists
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('gff_meta');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists) {
       carp "Creating gff_meta table...\n";
       $dbh->do(CREATE_META_TABLE);
       
    } else {
    	# check for existing lock
    	
	    my $select_query = $dbh->prepare(SELECT_FROM_META);
	    $select_query->execute();
	
	    while (my @result = $select_query->fetchrow_array) {
	        my ($name,$host,$time) = @result;
	        my ($progname,$pid)  = split /\-/, $name;
	
	        if ($progname eq $calling_program) {
	            carp "\n\n\nWARNING: There is another $calling_program process\n".
	            "running on $host, with a process id of $pid\n".
	            "which started at $time\n".
	            "\nIf that process is no longer running, you can remove the lock by providing\n".
	            "the --remove_lock flag when running $calling_program.\n\n".
	            "Note that if the last bulk load process crashed, you may also need the\n".
	            "--recreate_cache option as well.\n\n";
	
	            exit(-2);
	        }
	    }
    }

    my $pid = $$;
    my $name = "$calling_program-$pid";
    my $hostname = hostname;

    my $insert_query = $dbh->prepare(INSERT_INTO_META);
    $insert_query->execute($name,$hostname);
    $dbh->commit;

    return;
}


=head2 uniquename_cache

=over

=item Usage

  $obj->uniquename_cache()

=item Function

Maintains a cache of feature.uniquenames present in the database

=item Returns

See Arguements.

=item Arguments

uniquename_cache takes a hash.  
If it has a key 'validate', it returns the feature_id
of the feature corresponding to that uniquename if present, 0 if it is not.
Otherwise, it uses the values in the hash to update the uniquename_cache

Allowed hash keys:

  feature_id
  type_id
  organism_id
  uniquename
  validate

=back

=cut

sub uniquename_cache {
	my ($self, %argv) = @_;
	
	my @bogus_keys = grep {!/($ALLOWED_UNIQUENAME_CACHE_KEYS)/} keys %argv;
	
	if (@bogus_keys) {
		for (@bogus_keys) {
		    carp "I don't know what to do with the key ".$_.
		   " in the uniquename_cache method; it's probably because of a typo\n";
		}
		croak;
	}
		
	if ($argv{validate}) {
		if(defined $argv{type_id}) {  
			# valididate type & org too
			$self->{'queries'}{'validate_type_id'}->execute(
			    $argv{type_id},
			    $argv{uniquename},         
			);
			
			my ($feature_id) = $self->{'queries'}{'validate_type_id'}->fetchrow_array; 
			
			return $feature_id;
		} else { 
			#just validate the uniquename
			
			$self->{'queries'}{'validate_uniquename'}->execute($argv{uniquename});
			my ($feature_id) = $self->{'queries'}{'validate_uniquename'}->fetchrow_array;
			
			return $feature_id;
		}
	}
	elsif ($argv{type_id}) { 
	
	$self->{'queries'}{'insert_cache_type_id'}->execute(
	    $argv{feature_id},
	    $argv{uniquename},
	    $argv{type_id},    
	);
	$self->dbh->commit;
	return;
	}
}


=head2 constraint

=over

=item Usage

  $obj->constraint()

=item Function

Manages database constraints

=item Returns

Updates cache and returns true if the constraint has not be violated,
otherwise returns false.

=item Arguments

A hash with keys:

  name		constraint name
  terms		a anonymous array with column values

The array contains the column values in the 'right' order:

  feature_synonym_c1:      [feature_id, synonym_id]
  feature_dbxref_c1:       [feature_id, dbxref_id]
  feature_cvterm_c1:       [feature_id, cvterm_id]
  featureprop_c1:          [feature_id, cvterm_id, rank]
  feature_relationship_c1: [feature_id, feature_id, cvterm_id, rank]
  permission_c1:           [upload_id, login_id],
  
=back

=cut

sub constraint {
    my ($self, %argv) = @_;

    my $constraint = $argv{name};
    my @terms      = @{ $argv{terms} };

    if ($constraint eq 'feature_synonym_c1' ||
        $constraint eq 'feature_dbxref_c1'  ||
        $constraint eq 'permission_c1'      ||
        $constraint eq 'feature_cvterm_c1') {
        $self->throw( "wrong number of constraint terms") if (@terms != 2);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'featureprop_c1') {
        $self->throw("wrong number of constraint terms") if (@terms != 3);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'feature_relationship_c1') {
        $self->throw("wrong number of constraint terms") if (@terms != 4);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}{$terms[3]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}{$terms[3]}++;
            return 1;
        }
    }
    else {
        croak "I don't know how to deal with the constraint $constraint: typo?";
    }
}



=head2 cache

=over

=item Usage

  $obj->cache()

=item Function

Handles generic data cache hash of hashes from bulk_load_gff3

=item Returns

The cached value

=item Arguments

The name of one of several top level cache keys:

             db              #db.db_id cache
             dbxref
             feature
             source          #dbxref.dbxref_id ; gff_source
             type            #cvterm.cvterm_id cache

and a tag and optional value that gets stored in the cache.
If no value is passed, it is returned, otherwise void is returned.


=back

=cut

sub cache {
    my ($self, $top_level, $key, $value) = @_;

    if ($top_level !~ /($ALLOWED_CACHE_KEYS)/) {
        confess "I don't know what to do with the key '$top_level'".
            " in the cache method; it's probably because of a typo";
    }

    return $self->{cache}{$top_level}{$key} unless defined($value);

    return $self->{cache}{$top_level}{$key} = $value; 
}


=head2 nextfeature

=over

=item Usage

  $obj->nextfeature()        #get existing value
  $obj->nextfeature($newval) #set new value

=item Function

=item Returns

value of nextfeature (a scalar)

=item Arguments

new value of nextfeature (to set)

=back

=cut

sub nextfeature {
    my $self = shift;

    my $fid = $self->nextoid('feature',@_);
    if (!$self->first_feature_id() ) {
        $self->first_feature_id( $fid );
    }

    return $fid;
}


=head2 first_feature_id

=over

=item Usage

  $obj->first_feature_id()        #get existing value
  $obj->first_feature_id($newval) #set new value

=item Function

=item Returns

value of first_feature_id (a scalar), that is, the feature_id of the first
feature parsed in the current session.

=item Arguments

new value of first_feature_id (to set)

=back

=cut

sub first_feature_id {
    my $self = shift;
    my $first_feature_id = shift if defined(@_);
    return $self->{'first_feature_id'} = $first_feature_id if defined($first_feature_id);
    return $self->{'first_feature_id'};
}


=head2 cleanup_tmp_table

=over

=item Usage

  $obj->cleanup_tmp_table()

=item Function

Called when there is an abnormal exit from a loading program.  It deletes
entries in the tmp_gff_load_cache table that have feature_ids that were used
during the current session.

=item Returns

Nothing

=item Arguments

None (it needs the first feature_id, but that is stored in the object).

=back

=cut

sub cleanup_tmp_table {
    my $self = shift;

    my $dbh = $self->dbh;
    my $first_feature = $self->first_feature_id();
    return unless $first_feature;

    my $delete_query = $dbh->prepare(TMP_TABLE_CLEANUP);


    warn "Attempting to clean up the loader temp table (so that --recreate_cache\nwon't be needed)...\n";
    $delete_query->execute($first_feature); 

    return;
}


=head2 uniquename_validation

=over

=item Usage

  $obj->uniquename_validation(uniquename, type_id, feature_id)

=item Function

Determines if uniquename is really unique. If so, caches it and returns uniquename.
If not, attempts to create a unique

=item Returns

0 if uniquename is not unique, otherwise returns 1

=item Arguments

Array containing uniquename string, the cvterm type ID, feature ID for the next feature.

=back

=cut

sub uniquename_validation {
	my $self = shift;
	my ($uniquename, $type, $nextfeature) = @_;

	if ($self->uniquename_cache(validate => 1, type_id => $type, uniquename  => $uniquename )) { 
		#if this returns non-zero, it is already in the cache and not valid

		$uniquename = "$uniquename ($nextfeature)"; # Should be unique, if not something is screwy
		
		croak "Error: uniquename collision. Unable to generate uniquename using feature_id. " 
			if $self->uniquename_cache(validate => 1, type_id => $type, uniquename  => $uniquename );
			
		return $uniquename;
		
	} else { 
		# this uniquename is valid. cache it and return

		$self->uniquename_cache(type_id   => $type,
                                feature_id  => $nextfeature,
                                uniquename  => $uniquename );
		
		return $uniquename;
	}
}

=head2 prepare_queries

=over

=item Usage

  $obj->prepare_queries()

=item Function

Does dbi prepare on several cached queries

=item Returns

void

=item Arguments

none

=back

=cut

sub prepare_queries {
    my $self = shift;
    my $dbh  = $self->dbh();
    
	$self->{'queries'}{'validate_type_id'} = $dbh->prepare(VALIDATE_TYPE_ID);
	
	#$self->{'queries'}{'validate_uniquename'} = $dbh->prepare(VALIDATE_UNIQUENAME);
	
	$self->{'queries'}{'insert_cache_type_id'} = $dbh->prepare(INSERT_CACHE_TYPE_ID);
	
	#$self->{'queries'}{'insert_cache_uniquename'} = $dbh->prepare(INSERT_CACHE_UNIQUENAME);
	
	$self->{'queries'}{'search_db'} = $dbh->prepare(SEARCH_DB);
	
	$self->{'queries'}{'search_long_dbxref'} = $dbh->prepare(SEARCH_LONG_DBXREF);
	
	return;
}


=head2 load_data

=over

=item Usage

  $obj->load_data();

=item Function

Initiate loading of data for all tables and commit
to DB. 

Optionally, perform vacuum of DB after loading complete.

=item Returns

Nothing

=item Arguments

void

=back

=cut
sub load_data {
	my $self = shift;

	my %nextvalue = $self->nextvalueHash();

	foreach my $table (@tables) {
	
		$self->file_handles($files{$table})->autoflush;
		
		if (-s $self->file_handles($files{$table})->filename <= 4) {
			warn "Skipping $table table since the load file is empty...\n";
			next;
		}
		
		my $l_table = $table_names{$table};
		$self->copy_from_stdin($l_table,
			$copystring{$table},
			$files{$table}, #file_handle name
			$sequences{$table},
			$nextvalue{$table});
	}
	
	$self->dbh->commit() || croak "Commit failed: ".$self->dbh->errstr();
  
	if($self->vacuum) {
		warn "Optimizing database (this may take a while) ...\n";
		warn "  ";
		
		foreach (values %table_names) {
			warn "$_ ";
			$self->dbh->do("VACUUM ANALYZE $_");
		}
		warn "\nWhile this script has made an effort to optimize the database, you\n"
		."should probably also run VACUUM FULL ANALYZE on the database as well.\n";
		
		warn "\nDone.\n";
	}
}

=head2 copy_from_stdin

=over

=item Usage

  $obj->copy_from_stdin($table, $fields, $file, $sequence, $nextvalue);

=item Function

Load data  for a single table into DB using COPY ... FROM STDIN; command.

=item Returns

Nothing

=item Arguments

Array containing:
1. table name
2. string containing column field order (i.e. '(primary_id, value1, value2)')
3. name of file containing tab-delim values
4. name of primary key sequence in DB
5. next value in primary key's sequence

=back

=cut

sub copy_from_stdin {
	my $self = shift;
	my $table    = shift;
	my $fields   = shift;
	my $file     = shift;
	my $sequence = shift;
	my $nextval  = shift;

	my $dbh      = $self->dbh();

	warn "Loading data into $table table ...\n";

	my $fh = $self->file_handles($file);
	seek($fh,0,0);

	my $query = "COPY $table $fields FROM STDIN;";

	$dbh->do($query) or croak("Error when executing: $query: $!");

	while (<$fh>) {
		if ( ! ($dbh->pg_putline($_)) ) {
			#error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $file, line $.");
		} #putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $table failed: $!");

	#update the sequence so that later inserts will work
	$dbh->do("SELECT setval('$sequence', $nextval) FROM $table")
		or croak("Error when executing:  setval('$sequence', $nextval) FROM $table: $!"); 
}

=head2 handle_upload

=over

=item Usage

  $obj->handle_upload(login_id => $id,
  					  category => $cat,
  					  tag => $desc,
  					  release_date => '0000-00-00',
  					  upload_date => '0000-00-00')

=item Function

Perform creation of upload entry which is printed to file handle. Caches upload id.
Does the same for the permission table.

=item Returns

Nothing

=item Arguments

Hash with following keys: login_id, category, tag, release_date, upload_date

=back

=cut

sub handle_upload {
	my ($self, %argv) = @_;
	
	my %valid_cats = (public => 1, private => 1, release => 1);
	
	# Category
	my $category = $argv{category};
	croak "Missing argument: category" unless $category;
	croak "Invalid category: $category" unless $valid_cats{$category};
	
	# Login id
	my $login_id = $argv{login_id};
	croak "Missing argument: login_id" unless $login_id;
	my $l_sth = $self->dbh->prepare("SELECT count(*) FROM login WHERE login_id = $login_id");
	$l_sth->execute();
	croak "Invalid login_id: $login_id" unless $l_sth->fetchrow_array;
	
	# Tag
	my $tag = $argv{tag};
	$tag = 'Unclassified' unless $tag;
	
	# Release date
	my $rel_date = '3955-01-01'; # Apes will rule, so whatever
	if($category eq 'release') {
		$rel_date = $argv{release_date};
		croak "Missing argument: release_date" unless defined($rel_date);
		croak "Improperly formatted date: release_date (expected format: 0000-00-00)." unless $rel_date =~ m/^\d\d\d\d-\d\d-\d\d$/;
	}
	
	# Upload date
	my $upl_date = $argv{upload_date};
	croak "Missing argument: upload_date" unless defined($upl_date);
	croak "Improperly formatted date/time: upload_date (expected format: 0000-00-00 00:00:00)." unless $upl_date =~ m/^\d\d\d\d-\d\d-\d\d \d\d\:\d\d:\d\d$/;
	
	# Cache upload value
	my $upload_id = $self->nextoid('upload');
	$self->cache('const','upload', $upload_id);
	
	# Save in file
	$self->print_upl($upload_id, $login_id, $category, $tag, $rel_date, $upl_date);
	$self->nextoid('upload','++');
	
	
	# Now fill in permission entry
	
	# Uploader is given full permissions;
	my $can_share = my $can_modify = 1;
	my $perm_id = $self->nextoid('permission');
	
	if($self->constraint(name => 'permission_c1', terms => [$upload_id, $login_id])) {
		# Permission entry has not been added previously in this run
		$self->print_perm($perm_id, $upload_id, $login_id, $can_modify, $can_share);
		$self->nextoid('permission','++');
	}
	
	
}

=head2 handle_reserved_properties

=over

=item Usage

  $obj->handle_reseaved_properties($feature_id, $featureprop_hashref)

=item Function

Create featureprop table entries.

=item Returns

Nothing

=item Arguments

Hash with following keys: login_id, category, tag, release_date, upload_date

=back

=cut

sub handle_reserved_properties {
	my $self = shift;
	my ($feature_id, $fprops) = @_;

	foreach my $tag (keys %$fprops) {
      
      	my $property_cvterm_id = $self->featureprop_types($tag);
		unless($property_cvterm_id) {
      		carp "Unrecognized feature property type $tag.";
      		next;
      	}
      	
		# All property values are single value scalars (maybe in future allow some multiple values? like multiple aliases?)
		
		my $value = $fprops->{$tag};
      	my $rank=0; # Since we only have a single instance of each attribute, rank is 0.
      	
      	# If this property is unique, add it.
		if ($self->constraint(name => 'featureprop_c1', terms=> [ $feature_id, $property_cvterm_id, $rank ]) ) {
                                        	
			$self->print_fprop($self->nextoid('featureprop'),$feature_id,$property_cvterm_id,$value,$rank);
        	$self->nextoid('featureprop','++');
		}
    }
}

=head2 handle_dbxref

=over

=item Usage

  $obj->parent($feature_id, $dbxref_hashref)

=item Function

  Create db, dbxref and feature_dbxref table entries as needed. Save the primary
  dbxref for later loading in the feature table.

=item Returns

Nothing

=item Arguments

  Nested hashs, keyed as:
    a. primary => dbxref hashref
    b. secondary => array of dbxref hashrefs
  
  There must be a primary if there is any secondary dbxref. Each dbxref hash
  must contain keys:
    i.   db
    ii.  acc
  and optionally
    iii. ver
    iv.  desc

=back

=cut

sub handle_dbxref {
    my $self = shift;
    my ($feature_id,$dbxhash_ref) = @_;
    
    # Primary dbxref is first on list
    # primary dbxref_id stored in feature table and in feature_dbxref table
    # secondary dbxref_id stored only in feature_dbxref table
   
    my @dbxrefs = ($dbxhash_ref->{primary});
    push @dbxrefs, @{$dbxhash_ref->{secondary}};
    my $primary_dbxref_id;
    
	foreach my $dbxref (@dbxrefs) {
		my $database  = $dbxref->{db};
		my $accession = $dbxref->{acc};
      	my $version   = $dbxref->{ver};
		my $desc      = $dbxref->{desc};
		
		my $dbxref_id;
		if($dbxref_id = $self->cache('dbxref',"$database|$accession|$version")) {
			# dbxref has been created previously in this run
			
			# Make sure dbxref has not been added for this feature before
			if($self->constraint(name  => 'feature_dbxref_c1', terms => [ $feature_id, $dbxref_id]) ) {
				
				$self->print_fdbx($self->nextoid('feature_dbxref'), $feature_id, $dbxref_id);
          		$self->nextoid('feature_dbxref','++');
        	}
      	} else {
      		# New dbxref for this run
      		
      		# Search for database
          	unless ($self->cache('db', $database)) {
          		
				$self->{queries}{search_db}->execute("$database");
				
				my ($db_id) = $self->{queries}{search_db}->fetchrow_array;
				
				unless($db_id) { 
					# DB not found. Create db entry
					carp "Couldn't find database '$database' in db table. Adding new DB entry";
					$db_id= $self->nextoid('db');
				  	$self->print_dbname($db_id,$database,"autocreated:$database");
				  	$self->nextoid('db','++');
				}
				
				$self->cache('db',$database,$db_id);
          	}
          	
          	# Search for existing dbxref
          	$self->{queries}{search_long_dbxref}->execute($accession, $version, $self->cache('db',$database));
			($dbxref_id) = $self->{queries}{search_long_dbxref}->fetchrow_array;

			if ($dbxref_id) {
				# Found existing dbxref
				
				# Make sure dbxref has not been added for this feature before
            	if($self->constraint( name => 'feature_dbxref_c1', terms=> [ $feature_id, $dbxref_id ]) ) {
            		
            		$self->print_fdbx($self->nextoid('feature_dbxref'), $feature_id, $dbxref_id);
              		$self->nextoid('feature_dbxref','++'); #$nextfeaturedbxref++;
            	}
            	
            	$self->cache('dbxref',"$database|$accession|$version", $dbxref_id);
            	
			} else {
				# New dbxref
				
				$dbxref_id = $self->nextoid('dbxref');
				
            	# Make sure dbxref has not been added for this feature before
            	if($self->constraint( name => 'feature_dbxref_c1', terms=> [ $feature_id, $dbxref_id ]) ) {
            		
            		$self->print_fdbx($self->nextoid('feature_dbxref'), $feature_id, $dbxref_id);
              		$self->nextoid('feature_dbxref','++'); #$nextfeaturedbxref++;
            	}
            	
				$self->print_dbx($dbxref_id, $self->cache('db',$database), $accession, $version, $desc);
				$self->cache('dbxref',"$database|$accession|$version",$dbxref_id);
				$self->nextoid('dbxref','++');
			}
      	}
      	
      	$primary_dbxref_id = $dbxref_id unless defined($primary_dbxref_id);
	}
	
	# Store primary dbxref in feature table cache (call it 'source')
	# At this point db, dbxref table entries should already be created
	if(defined($primary_dbxref_id)) {
		$self->cache('source', $feature_id, $primary_dbxref_id);
	}
}

=head2 handle_parent

=over

=item Usage

  $obj->parent($child_feature_id)

=item Function

Create 'part_of' entry in feature_relationship table.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature.

=back

=cut

sub handle_parent {
    my $self = shift;
    my ($child_id) = @_;
    
    my $parent_id = $self->cache('const', 'contig_collection_id');
    my $part_of = $self->relationship_types('part_of');
    my $rank = 0;

	croak "Parent not defined." unless $parent_id;

	# If this relationship is unique, add it.
	if ($self->constraint(name => 'feature_relationship_c1', terms => [ $parent_id, $child_id, $part_of, $rank ]) ) {
                                        	
		$self->print_frel($self->nextoid('feature_relationship'),$child_id,$parent_id,$part_of,$rank);
		$self->nextoid('feature_relationship','++');
	}
	
  
}



#################
# Printing
#################

# Prints to file handles for later COPY run

sub print_upl {
	my $self = shift;
	my ($upl_id,$login_id,$cat,$tag,$rdate,$udate) = @_;

	my $fh = $self->file_handles('upload');
 
	print $fh join("\t",($upl_id,$login_id,$cat,$tag,$rdate,$udate)),"\n";
  
}

sub print_perm {
	my $self = shift;
	my ($perm_id,$upl_id,$login_id,$mod,$share) = @_;

	my $fh = $self->file_handles('permission');
 
	print $fh join("\t",($perm_id,$upl_id,$login_id,$mod,$share)),"\n";
  
}

sub print_fprop {
	my $self = shift;
	my ($fp_id, $f_id, $cvterm_id, $value, $rank) = @_;

	my $fh = $self->file_handles('featureprop');
	
	if($self->web_upload) {
		my $upl_id = $self->cache('const','upload');
		croak 'Undefined upload_id.' unless $upl_id;
		
		print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank,$upl_id)),"\n";
		
	} else {
		
		print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank)),"\n";
	}
		
  
	
  
}

sub print_dbname {
	my $self = shift;
	my ($db_id,$name,$description) = @_;
	
	$description ||= '\N';
	
	my $fh = $self->file_handles('db');
	
	print $fh join("\t",($db_id,$name,$description)),"\n";
	
}

sub print_fdbx {
	my $self = shift;
	my ($fd_id,$f_id,$dx_id) = @_;
	
	my $fh = $self->file_handles('feature_dbxref');
	
	print $fh join("\t",($fd_id,$f_id,$dx_id)),"\n";
	
}

sub print_dbx {
	my $self = shift;
	my ($dbx_id,$db_id,$acc,$vers,$desc) = @_;
	
	my $fh = $self->file_handles('dbxref');
	
	print $fh join("\t",($dbx_id,$db_id,$acc,$vers,$desc)),"\n";
	
}

sub print_frel {
	my $self = shift;
	my ($nextfeaturerel,$nextfeature,$parent,$part_of,$rank) = @_;
	
	my $fh = $self->file_handles('feature_relationship');
	
	print $fh join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of,$rank)),"\n";
  
}

sub print_f {
	my $self = shift;
	my ($nextfeature,$organism,$name,$uniquename,$type,$seqlen,$dbxref,$residues) = @_;
	
	my $fh = $self->file_handles('feature');
	$dbxref ||= '\N';
	
	if($self->web_upload) {
		my $upl_id = $self->cache('const','upload');
		croak 'Undefined upload_id.' unless $upl_id;
		
		print $fh join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $upl_id, $residues)),"\n";
		
	} else {
		
		print $fh join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues)),"\n";
	}
	
}

sub nextvalueHash {  
	my $self = shift;
	
	my %nextval = ();
	for my $t (@tables) {
		$nextval{$t} = $self->{'nextoid'}{$t};
	}
	
	return %nextval;
}

#################
# Accessors
#################

=head2 dbh

=over

=item Usage

  $obj->dbh()        #get existing value
  $obj->dbh($newval) #set new value

=item Function

=item Returns

value of dbh (a scalar)

=item Arguments

new value of dbh (to set)

=back

=cut

sub dbh {
    my $self = shift;

    my $dbh = shift if defined(@_);
    return $self->{'dbh'} = $dbh if defined($dbh);
    return $self->{'dbh'};
}

=head2 dbname

=over

=item Usage

  $obj->dbname()        #get existing value
  $obj->dbname($newval) #set new value

=item Function

=item Returns

value of dbname (a scalar)

=item Arguments

new value of dbname (to set)

=back

=cut

sub dbname {
    my $self = shift;

    my $dbname = shift if defined(@_);
    return $self->{'dbname'} = $dbname if defined($dbname);
    return $self->{'dbname'};
}

=head2 dbport

=over

=item Usage

  $obj->dbport()        #get existing value
  $obj->dbport($newval) #set new value

=item Function

=item Returns

value of dbport (a scalar)

=item Arguments

new value of dbport (to set)

=back

=cut

sub dbport {
    my $self = shift;

    my $dbport = shift;
    return $self->{'dbport'} = $dbport if defined($dbport);
    return $self->{'dbport'};
}

=head2 dbhost

=over

=item Usage

  $obj->dbhost()        #get existing value
  $obj->dbhost($newval) #set new value

=item Function

=item Returns

value of dbhost (a scalar)

=item Arguments

new value of dbhost (to set)

=back

=cut

sub dbhost {
    my $self = shift;

    my $dbhost = shift;
    return $self->{'dbhost'} = $dbhost if defined($dbhost);
    return $self->{'dbhost'};
}

=head2 dbuser

=over

=item Usage

  $obj->dbuser()        #get existing value
  $obj->dbuser($newval) #set new value

=item Function

=item Returns

value of dbuser (a scalar)

=item Arguments

new value of dbuser (to set)

=back

=cut

sub dbuser {
    my $self = shift;

    my $dbuser = shift;
    return $self->{'dbuser'} = $dbuser if defined($dbuser);
    return $self->{'dbuser'};
}

=head2 dbpass

=over

=item Usage

  $obj->dbpass()        #get existing value
  $obj->dbpass($newval) #set new value

=item Function

=item Returns

value of dbpass (a scalar)

=item Arguments

new value of dbpass (to set)

=back

=cut

sub dbpass {
    my $self = shift;

    my $dbpass = shift;
    return $self->{'dbpass'} = $dbpass if defined($dbpass);
    return $self->{'dbpass'};
}

=head2 noload

=over

=item Usage

  $obj->noload()        #get existing value
  $obj->noload($newval) #set new value

=item Function

=item Returns

value of noload (a scalar)

=item Arguments

new value of noload (to set)

=back

=cut

sub noload {
    my $self = shift;

    my $noload = shift;
    return $self->{'noload'} = $noload if defined($noload);
    return $self->{'noload'};
}

=head2 vacuum

=over

=item Usage

  $obj->vacuum()        #get existing value
  $obj->vacuum($newval) #set new value

=item Function

=item Returns

Boolean value of vacuum parameter (0/1)

=item Arguments

Boolean value of vacuum parameter (0/1)

=back

=cut

sub vacuum {
    my $self = shift;

    my $v = shift if defined(@_);
    return $self->{'vacuum'} = $v if defined($v);
    return $self->{'vacuum'};
}

=head2 web_upload

=over

=item Usage

  $obj->web_upload()        #get existing value
  $obj->web_upload($newval) #set new value

=item Function

=item Returns

Boolean value of web_upload parameter (0/1)

=item Arguments

Boolean value of web_upload parameter (0/1)

=back

=cut

sub web_upload {
    my $self = shift;

    my $v = shift if defined(@_);
    return $self->{'web_upload'} = $v if defined($v);
    return $self->{'web_upload'};
}

=head2 save_tmpfiles

=over

=item Usage

  $obj->save_tmpfiles()        #get existing value
  $obj->save_tmpfiles($newval) #set new value

=item Function

=item Returns

value of save_tmpfiles (a scalar)

=item Arguments

new value of save_tmpfiles (to set)

=back

=cut

sub save_tmpfiles {
    my $self = shift;
    my $save_tmpfiles = shift if defined(@_);
    return $self->{'save_tmpfiles'} = $save_tmpfiles if defined($save_tmpfiles);
    return $self->{'save_tmpfiles'};
}


=head2 recreate_cache

=over

=item Usage

  $obj->recreate_cache()        #get existing value
  $obj->recreate_cache($newval) #set new value

=item Function

=item Returns

value of recreate_cache (a scalar)

=item Arguments

new value of recreate_cache (to set)

=back

=cut

sub recreate_cache {
    my $self = shift;
    my $recreate_cache = shift if defined(@_);

    return $self->{'recreate_cache'} = $recreate_cache if defined($recreate_cache);
    return $self->{'recreate_cache'};
}

=head2 feature_types

=over

=item Usage

  $obj->feature_types('featuretypename')        #get existing value

=item Function

=item Returns

value of cvterm_id for featuretypename

=item Arguments

name of feature type

=back

=cut

sub feature_types {
    my $self = shift;
    my $type = shift;

    return $self->{'feature_types'}->{$type};
}

=head2 relationship_types

=over

=item Usage

  $obj->relationship_types('relationshiptypename')        #get existing value

=item Function

=item Returns

value of cvterm_id for relationshiptypename

=item Arguments

name of relationship type

=back

=cut

sub relationship_types {
    my $self = shift;
    my $type = shift;

    return $self->{'relationship_types'}->{$type};
}

=head2 featureprop_types

=over

=item Usage

  $obj->featureprop_typess('featurepropname') #get existing value for featurepropname

=item Function

=item Returns

cvterm_id for a valid featureprop type.

=item Arguments

a featurprop type

=back

=cut

sub featureprop_types {
    my $self = shift;
    my $fp = shift;
    
    return $self->{featureprop_types}->{$fp};
}

=head2 organism

=over

=item Usage

  $obj->organism() #get existing value
  $obj->organism('common_name' => $name) #get existing value

=item Function

=item Returns

  organism_id for a current organism

=item Arguments

  To set organism, hash with following keys:
    1. common name => name of organism

=back

=cut

sub organism {
    my $self = shift;
    my %argv = @_;
    
    if($argv{common_name}) {
   		my $cn = $argv{common_name};
    	my $oid = $self->{organisms}->{$cn};
    	croak "Unrecognized or unknown organism with common name $cn." unless $oid;
    	$self->{organism_id} = $oid;
    }
    
    return $self->{organism_id};
}


1;


