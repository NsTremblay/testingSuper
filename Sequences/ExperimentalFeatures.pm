package Sequences::ExperimentalFeatures;

use strict;
use warnings;

use DBI;
use Carp qw/croak carp confess/;
use Sys::Hostname;
use File::Temp;

=head1 NAME

Sequences::ExperimentalFeatures;

=head1 DESCRIPTION

Based on perl package: Bio::GMOD::DB::Adapter

Provides interface to CHADO database for loading VF/AMR alleles.

=cut

# Calling program name
my $calling_program = 'genodo_fasta_loader.pl';

my $DEBUG = 0;

# Tables in order that data is inserted
my @tables = (
	"feature",
	"private_feature",
	"feature_relationship",
	"private_feature_relationship",
	"feature_cvterm",
	"private_feature_cvterm",
	"featureloc",
	"private_featureloc",
	"featureprop",
	"private_featureprop",
);


# Primary key sequence names
my %sequences = (
	feature                      => "feature_feature_id_seq",
	feature_relationship         => "feature_relationship_feature_relationship_id_seq",
	featureprop                  => "featureprop_featureprop_id_seq",
	featureloc                   => "featureloc_featureloc_id_seq",
	feature_cvterm               => "feature_cvterm_feature_cvterm_id_seq",
	private_feature              => "private_feature_feature_id_seq",
	private_feature_relationship => "private_feature_relationship_feature_relationship_id_seq",
	private_featureprop          => "private_featureprop_featureprop_id_seq",
	private_featureloc           => "private_featureloc_featureloc_id_seq",
	private_feature_cvterm       => "private_feature_cvterm_feature_cvterm_id_seq",	 
  
);

# Primary key ID names
my %table_ids = (
	feature                      => "feature_id",
	feature_relationship         => "feature_relationship_id",
	featureprop                  => "featureprop_id",
	featureloc                   => "featureloc_featureloc_id",
    feature_cvterm               => "feature_cvterm_feature_cvterm_id",
    private_feature              => "private_feature_id",
	private_feature_relationship => "private_feature_relationship_id",
	private_featureprop          => "private_featureprop_id",
	private_featureloc           => "private_featureloc_featureloc_id",
    private_feature_cvterm       => "private_feature_cvterm_feature_cvterm_id",
);

# Valid cvterm types for featureprops table
# hash: name => cv
my %fp_types = (
	score => 'feature_property',
);

# Used in DB COPY statements
my %copystring = (
   feature                      => "(feature_id,organism_id,name,uniquename,type_id,seqlen,dbxref_id,residues)",
   feature_relationship         => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   featureprop                  => "(featureprop_id,feature_id,type_id,value,rank)",
   feature_cvterm               => "(feature_cvterm_id,feature_id,cvterm_id,pub_id,rank)",
   featureloc                   => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,locgroup,rank)",
   private_feature              => "(feature_id,organism_id,name,uniquename,type_id,seqlen,dbxref_id,upload_id,residues)",
   private_feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   private_featureprop          => "(featureprop_id,feature_id,type_id,value,upload_id,rank)",
   private_feature_cvterm       => "(feature_cvterm_id,feature_id,cvterm_id,pub_id,rank)",
   private_featureloc           => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,locgroup,rank)",
);

# Key values for uniquename cache
my $ALLOWED_UNIQUENAME_CACHE_KEYS = "feature_id|type_id|uniquename|validate";
               
# Tables for which caches are maintained
#my $ALLOWED_CACHE_KEYS = "db|dbxref|feature|source|const";
my $ALLOWED_CACHE_KEYS = "collection|contig";

# Tmp file names for storing upload data
my %files = map { $_ => 'FH'.$_; } @tables; # SEQ special case in feature table

# SQL for unique cache
use constant CREATE_CACHE_TABLE =>
               "CREATE TABLE public.tmp_gff_load_cache (
                    feature_id int,
                    uniquename varchar(1000),
                    type_id int,
                    organism_id int,
                    pub boolean
                )";
use constant DROP_CACHE_TABLE =>
               "DROP TABLE public.tmp_gff_load_cache";
use constant VERIFY_TMP_TABLE =>
               "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
use constant POPULATE_CACHE_TABLE =>
               "INSERT INTO public.tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id,TRUE FROM feature";
use constant POPULATE_PRIVATE_CACHE_TABLE =>
               "INSERT INTO public.tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id,FALSE FROM private_feature";
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
               "DELETE FROM tmp_gff_load_cache WHERE pub = TRUE AND feature_id >= ?";             
use constant TMP_TABLE_PRIVATE_CLEANUP =>
               "DELETE FROM tmp_gff_load_cache WHERE pub = FALSE AND feature_id >= ?";
                    
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
                  (feature_id,uniquename,type_id,pub) VALUES (?,?,?,TRUE)";
use constant INSERT_CACHE_UNIQUENAME =>
               "INSERT INTO public.tmp_gff_load_cache (feature_id,uniquename,pub)
                  VALUES (?,?,?)";
use constant INSERT_CACHE_PRIVATE_TYPE_ID =>
               "INSERT INTO public.tmp_gff_load_cache 
                  (feature_id,uniquename,type_id,pub) VALUES (?,?,?,FALSE)";
use constant INSERT_CACHE_PRIVATE_UNIQUENAME =>
               "INSERT INTO public.tmp_gff_load_cache (feature_id,uniquename,pub)
                  VALUES (?,?,FALSE)";
               
# SQL for obtaining feature info
use constant SELECT_FROM_PUBLIC_FEATURE =>
	"SELECT uniquename, organism_id, residues, seqlen FROM feature WHERE feature_id = ?";
	
use constant SELECT_FROM_PRIVATE_FEATURE =>
	"SELECT uniquename, organism_id, upload_id, residues, seqlen FROM private_feature WHERE feature_id = ?";
	               
            
=head2 new

Constructor

=cut

sub new {
	my $class = shift;
	my %arg   = @_;
	
	$DEBUG = 1 if $arg{debug};
	
	my $self  = bless {}, ref($class) || $class;
	
	my $dbname  =  $arg{dbname};
	my $dbport  =  $arg{dbport};
	my $dbhost  =  $arg{dbhost};
	my $dbuser  =  $arg{dbuser};
	my $dbpass  =  $arg{dbpass};
	my $tmp_dir =  $arg{tmp_dir};
	croak "Missing argument: tmp_dir." unless $tmp_dir;
	
	my $skipinit=0;
	
	my $dbh = DBI->connect(
		"dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
		$dbuser,
		$dbpass,
		{AutoCommit => 0,
		 TraceLevel => 0}
	) or croak "Unable to connect to database";
	
	$self->dbh($dbh);
	
	$self->tmp_dir(         $arg{tmp_dir}         );
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
		$self->initialize_uniquename_cache();
	}
	
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
    
    # Part of ID
	$fp_sth->execute('located_in', 'relationship');
    my ($located_in) = $fp_sth->fetchrow_array();
    
    # Part of ID
	$fp_sth->execute('similar_to', 'relationship');
    my ($similar_to) = $fp_sth->fetchrow_array();

    # Contig collection ID
    $fp_sth->execute('contig_collection', 'sequence');
    my ($contig_col) = $fp_sth->fetchrow_array();
    
    # Contig ID
    $fp_sth->execute('contig', 'sequence');
    my ($contig) = $fp_sth->fetchrow_array();
    
    # Allele ID
    $fp_sth->execute('allele', 'sequence');
    my ($allele) = $fp_sth->fetchrow_array();
    
    # Experimental Feature ID
    $fp_sth->execute('experimental_feature', 'sequence');
    my ($experimental_feature) = $fp_sth->fetchrow_array();
    
    # Query ID?
    
    $self->{feature_types} = {
    	contig_collection => $contig_col,
    	contig => $contig,
    	allele => $allele,
    	experimental_feature => $experimental_feature
    };
    
	$self->{relationship_types} = {
    	part_of => $part_of,
    	similar_to => $similar_to,
    	located_in => $located_in,
    };
    
    # Feature property types
    foreach my $type (keys %fp_types) {
    	my $cv = $fp_types{$type};
    	$fp_sth->execute($type, $cv);
    	my ($cvterm_id) = $fp_sth->fetchrow_array();
    	croak "Featureprop cvterm type $type not in database." unless $cvterm_id;
    	$self->{featureprop_types}->{$type} = $cvterm_id;
    }

	# Place-holder publication ID
	my $p_sth = $self->dbh->prepare("SELECT pub_id FROM pub WHERE uniquename = 'null'");
	($self->{pub_id}) = $fp_sth->fetchrow_array();

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
		my $table_name   = $table;
		my $max_id_query = "SELECT max($id_name) FROM $table_name";
		my $sth          = $self->dbh->prepare($max_id_query);
		$sth->execute;
		my ($max_id)     = $sth->fetchrow_array();
		
		$max_id = 1 unless $max_id; # Empty table
		
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
        my $file_path = $self->{tmp_dir};
     
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

  featureloc_c1:           [feature_id, rank, is_public]
  feature_cvterm_c1:       [feature_id, cvterm_id, is_public]
  featureprop_c1:          [feature_id, cvterm_id, rank, is_public]
  feature_relationship_c1: [feature_id, feature_id, cvterm_id, is_public]
  
=back

=cut

sub constraint {
    my ($self, %argv) = @_;

    my $constraint = $argv{name};
    my @terms      = @{ $argv{terms} };

    if ($constraint eq 'feature_cvterm_c1' ||
        $constraint eq 'featureloc_c1') {
		
		$self->throw( "wrong number of constraint terms") if (@terms != 3);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'featureprop_c1' ||
    	   $constraint eq 'feature_relationship_c1') {
        
        $self->throw("wrong number of constraint terms") if (@terms != 4);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}++;
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


=head2 collection

=over

=item Usage

  $obj->collection($contig_collection_id, $is_public)        # get existing value

=item Function

=item Returns

A hash of contig_collection data. Keys:
	name
	organism
	upload

=item Arguments

A feature table ID for a contig_collection and a boolean indicating
if feature is in public or private table.

=back

=cut

sub collection {
    my $self = shift;
    my ($feature_id, $public) = @_;
    
    my $cc = $public ? "public_$feature_id" : "private_$feature_id";
    
    if($self->cache('collection', $cc)) {
    	return $self->cache('collection', $cc);
    } else {
    	if($public) {
    		
    		$self->{'queries'}{'select_from_public_feature'}->execute(
			    $feature_id         
			);
			my ($uname, $org_id) = $self->{'queries'}{'select_from_public_feature'}->fetchrow_array(); 
			croak "Contig collection $feature_id not found in feature table." unless $uname;
			
			my $hash = {
				name => $uname,
				organism => $org_id
			};
			
			$self->cache('collection', $cc, $hash);
			return $hash;
			
    	} else {
    		
    		$self->{'queries'}{'select_from_private_feature'}->execute(
			    $feature_id         
			);
			my ($uname, $org_id, $upl_id) = $self->{'queries'}{'select_from_private_feature'}->fetchrow_array(); 
			croak "Contig collection $feature_id not found in feature table." unless $uname;
			
			my $hash = {
				name => $uname,
				organism => $org_id,
				upload => $upl_id
			};
			
			$self->cache('collection', $cc, $hash);
			return $hash;
    		
    	}
    }
}

=head2 contig

=over

=item Usage

  $obj->contig($contig_id, $is_public)        # get existing value

=item Function

=item Returns

A hash of contig data. Keys:
	seq
	name
	len
	sequence

=item Arguments

A feature table ID for a contig and a boolean indicating
if feature is in public or private table.

=back

=cut

sub contig {
    my $self = shift;
    my ($feature_id, $public) = @_;
    
    my $cc = $public ? "public_$feature_id" : "private_$feature_id";
    
    if($self->cache('contig', $cc)) {
    	return $self->cache('contig', $cc);
    } else {
    	if($public) {
    		
    		$self->{'queries'}{'select_from_public_feature'}->execute(
			    $feature_id         
			);
			my ($uname, $org_id, $residues, $seqlen) = $self->{'queries'}{'select_from_public_feature'}->fetchrow_array(); 
			croak "Contig $feature_id not found in feature table." unless $uname;
			
			my $hash = {
				name => $uname,
				organism => $org_id,
				sequence => $residues,
				len => $seqlen
			};
			
			$self->cache('contig', $cc, $hash);
			return $hash;
			
    	} else {
    		
    		$self->{'queries'}{'select_from_private_feature'}->execute(
			    $feature_id         
			);
			my ($uname, $org_id, $upl_id, $residues, $seqlen) = $self->{'queries'}{'select_from_private_feature'}->fetchrow_array(); 
			croak "Contig $feature_id not found in feature table." unless $uname;
			
			my $hash = {
				name => $uname,
				organism => $org_id,
				upload => $upl_id,
				sequence => $residues,
				len => $seqlen
			};
			
			$self->cache('contig', $cc, $hash);
			return $hash;
    		
    	}
    }
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
    my $public = shift;

	my $fid;
	if($public) {
		$fid = $self->nextoid('feature',@_);
	    if (!$self->first_feature_id() ) {
	        $self->first_feature_id( $fid );
	    }
	} else {
		$fid = $self->nextoid('private_feature',@_);
	    if (!$self->first_private_feature_id() ) {
	        $self->first_private_feature_id( $fid );
	    }
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

sub first_private_feature_id {
    my $self = shift;
    my $first_feature_id = shift if defined(@_);
    return $self->{'first_private_feature_id'} = $first_feature_id if defined($first_feature_id);
    return $self->{'first_private_feature_id'};
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
    warn "Attempting to clean up the loader temp table (so that --recreate_cache\nwon't be needed)...\n";
    
	# public
    
    my $first_feature = $self->first_feature_id();
    unless($first_feature){
    	my $delete_query = $dbh->prepare(TMP_TABLE_CLEANUP);
    
		$delete_query->execute($first_feature);
    }

	# private
    
    my $first_feature2 = $self->first_feature_id();
    unless($first_feature2){
    	my $delete_query = $dbh->prepare(TMP_TABLE_PRIVATE_CLEANUP);
    
		$delete_query->execute($first_feature2);
    }

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

		$self->uniquename_cache(type_id   => $type, feature_id  => $nextfeature, uniquename  => $uniquename );
		
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
	
	$self->{'queries'}{'select_from_public_feature'} = $dbh->prepare(SELECT_FROM_PUBLIC_FEATURE);
	
	$self->{'queries'}{'select_from_private_feature'} = $dbh->prepare(SELECT_FROM_PRIVATE_FEATURE);
	
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
		
		$self->copy_from_stdin($table,
			$copystring{$table},
			$files{$table}, #file_handle name
			$sequences{$table},
			$nextvalue{$table});
	}
	
	$self->dbh->commit() || croak "Commit failed: ".$self->dbh->errstr();
	
	if($self->vacuum) {
		warn "Optimizing database (this may take a while) ...\n";
		warn "  ";
		
		foreach (@tables) {
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

=head2 update_tracker

=over

=item Usage

  $obj->update_tracker(tracker_id)

=item Function

Updates the upload_id column in the tracker table
for the provided tracker_id.

upload_id must be in upload to prevent foreign key
violation.

Make sure 

=item Returns

Nothing

=item Arguments

A tracker_id in the tracker table

=back

=cut

sub update_tracker {
	my ($self, $tracking_id, $upload_id) = @_;
	
	my $sth = $self->dbh->prepare("SELECT count(*) FROM upload WHERE upload_id = $upload_id");
	$sth->execute();
	my ($found) = $sth->fetchrow_array();
	
	croak "Method must be called after upload table has been loaded with the provided upload_id: $upload_id." unless $found;
	
	$self->dbh->do("UPDATE tracker SET upload_id = $upload_id WHERE tracker_id = $tracking_id");
	$self->dbh->commit || croak "Tracker table update failed: ".$self->dbh->errstr();
}

=head2 handle_parent

=over

=item Usage

  $obj->handle_parent($child_feature_id, $contig_collection_id, $conti_id, $is_public)

=item Function

Create 'part_of' and 'located_in' entries in feature_relationship table.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature, contig coolection, contig and a boolean indicating public or private

=back

=cut

sub handle_parent {
    my $self = shift;
    my ($child_id, $cc_id, $c_id, $pub) = @_;
    
    my @rtypes = ($self->relationship_types('part_of'));
    push @rtypes, $self->relationship_types('located_in');
    my $rank = 0;
    
    my $table = $pub ? 'feature_relationship' : 'private_feature_relationship';
    foreach my $parent_id ($cc_id, $c_id) {
    	
    	my $type = shift @rtypes;
    	
    	# If this relationship is unique, add it.
		if ($self->constraint(name => 'feature_relationship_c1', terms => [ $parent_id, $child_id, $type, $rank, $pub ]) ) {
	                                        	
			$self->print_frel($self->nextoid($table),$child_id,$parent_id,$type,$rank,$pub);
			$self->nextoid($table,'++');
		}
    }
}


=head2 handle_query_hit

=over

=item Usage

  $obj->handle_query_hit($child_feature_id, $query_gene_id, $is_public)

=item Function

Create 'similar_to' entry in feature_relationship table.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature, query gene and a boolean indicating public or private

=back

=cut

sub handle_query_hit {
    my $self = shift;
    my ($child_id, $parent_id, $pub) = @_;
    
  	my $rtype = $self->relationship_types('similar_to');
    my $rank = 0;
    
   
    # If this relationship is unique, add it.
    my $table = $pub ? 'feature_relationship' : 'private_feature_relationship';
	if ($self->constraint(name => 'feature_relationship_c1', terms => [ $parent_id, $child_id, $rtype, $rank, $pub ]) ) {
                                        	
		$self->print_frel($self->nextoid($table),$child_id,$parent_id,$rtype,$rank,$pub);
		$self->nextoid($table,'++');
		
	}
   
}


=head2 handle_location

=over

=item Usage

  $obj->handle_location($child_feature_id, $contig_id, $start, $end, $is_public)

=item Function

Perform creation of featureloc entry.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature, contig, start and end coords from BLAST and a boolean indicating public or private

=back

=cut

sub handle_location {
	my $self = shift;
    my ($f_id, $src_id, $min, $max, $strand, $pub) = @_;
    
    my $locgrp = 0;
    my $rank = 0;
    
    my $table = $pub ? 'featureloc' : 'private_featureloc';
	if ($self->constraint(name => 'featureloc_c1', terms => [ $f_id, $rank, $pub ]) ) {
	                                    	
		$self->print_floc($self->nextoid($table),$f_id,$src_id,$min,$max,$strand,$locgrp,$rank,$pub);
		$self->nextoid($table,'++');
	}
    
}


=cut

=head2 handle_properties

=over

=item Usage

  $obj->handle_properties($feature_id, $percent_identity)

=item Function

Create featureprop table entries for BLAST results

=item Returns

Nothing

=item Arguments

percent identity, 

=back

=cut

sub handle_properties {
	my $self = shift;
	my ($feature_id, $pi, $pub, $upload_id) = @_;

	my $tag = 'score';
      
 	my $property_cvterm_id = $self->featureprop_types($tag);
	unless($property_cvterm_id) {
		carp "Unrecognized feature property type $tag.";
	}
 	
 	my $rank=0;
 	
    my $table = $pub ? 'featureprop' : 'private_featureprop';
	if ($self->constraint(name => 'featureprop_c1', terms=> [ $feature_id, $property_cvterm_id, $rank, $pub]) ) {
                                      	
		$self->print_fprop($self->nextoid($table),$feature_id,$property_cvterm_id,$pi,$rank,$pub,$upload_id);
      	$self->nextoid($table,'++');
      	
	} else {
		carp "Featureprop with type $property_cvterm_id and rank $rank already exists for this feature.\n";
	}
 	
 
}



=head2 add_types

=over

=item Usage

  $obj->add_types($child_feature_id, $is_public)

=item Function

Add 'experimental feature' type in feature_cvterm table.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature.

=back

=cut

sub add_types {
    my $self = shift;
    my ($child_id, $pub) = @_;
    
    my $ef_type = $self->feature_types('experimental_feature');
    my $rank = 0;

	my $table = $pub ? 'feature_cvterm' : 'private_feature_cvterm';
	if ($self->constraint(name => 'feature_cvterm_c1', terms => [ $child_id, $ef_type, $pub ]) ) {
                                        	
		$self->print_fcvterm($self->nextoid($table), $child_id, $ef_type, $self->publication_id, $rank);
		$self->nextoid($table,'++');
	}
}



#################
# Printing
#################

# Prints to file handles for later COPY run

sub print_fprop {
	my $self = shift;
	my ($fp_id, $f_id, $cvterm_id, $value, $rank, $pub, $upl_id) = @_;

	if($pub) {
		my $fh = $self->file_handles('featureprop');
		print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank)),"\n";		
	} else {
		my $fh = $self->file_handles('private_featureprop');
		print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank,$upl_id)),"\n";
	}
  
}

sub print_fcvterm {
	my $self = shift;
	my ($nextfeaturecvterm,$nextfeature,$type,$ref,$rank,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('feature_cvterm');		
	} else {
		$fh = $self->file_handles('private_feature_cvterm');
	}
	
	print $fh join("\t", ($nextfeaturecvterm,$nextfeature,$type,$ref,$rank)),"\n";
}

sub print_frel {
	my $self = shift;
	my ($nextfeaturerel,$nextfeature,$parent,$part_of,$rank,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('feature_relationship');		
	} else {
		$fh = $self->file_handles('private_feature_relationship');
	}
	
	print $fh join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of,$rank)),"\n";
}

sub print_floc {
	my $self = shift;
	my ($nextfeatureloc,$nextfeature,$src,$min,$max,$str,$lg,$rank,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('featureloc');		
	} else {
		$fh = $self->file_handles('private_featureloc');
	}
	
	print $fh join("\t", ($nextfeatureloc,$nextfeature,$src,$min,$max,$str,$lg,$rank)),"\n";
}

sub print_f {
	my $self = shift;
	my ($nextfeature,$organism,$name,$uniquename,$type,$seqlen,$dbxref,$residues,$pub,$upl_id) = @_;
	
	$dbxref ||= '\N';
	
	if($pub) {
		my $fh = $self->file_handles('feature');
		print $fh join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $upl_id, $residues)),"\n";		
	} else {
		my $fh = $self->file_handles('private_feature');
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

=head2 tmp_dir

=over

=item Usage

  $obj->tmp_dir()        #get existing value
  $obj->tmp_dir($newval) #set new value

=item Function

=item Returns

file path to a tmp directory

=item Arguments

new value of tmp_dir (to set)

=back

=cut

sub tmp_dir {
    my $self = shift;

    my $tmp_dir = shift if defined(@_);
    return $self->{'tmp_dir'} = $tmp_dir if defined($tmp_dir);
    return $self->{'tmp_dir'};
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


=head2 publication_id

=over

=item Usage

  $obj->publication_id #get existing value for null publication type

=item Function

=item Returns

pub_id for a null publication needed in the feature_cvterm table

=back

=cut

sub publication_id {
    my $self = shift;
    
    return $self->{pub_id};
}

=head2 reverse_complement

=over

=item Usage

  $obj->reverse_complement($dna) #return rev comp of dna sequence

=item Function

=item Returns

  Reverse complement of DNA sequence

=item Arguments

  dna string consisting of IUPAC characters

=back

=cut

sub reverse_complement {
	my $self = shift;
	my $dna = shift;
	
	# reverse the DNA sequence
	my $revcomp = reverse($dna);
	
	# complement the reversed DNA sequence
	$revcomp =~ tr/ABCDGHMNRSTUVWXYabcdghmnrstuvwxy/TVGHCDKNYSAABWXRtvghcdknysaabwxr/;
	
	return $revcomp;
}

1;


