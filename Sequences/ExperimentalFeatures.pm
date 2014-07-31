package Sequences::ExperimentalFeatures;

use strict;

use Inline (Config =>
			DIRECTORY => $ENV{"HOME"}.'/Inline', );
use Inline 'C';
Inline->init;

use warnings;
use DBI;
use Carp qw/croak carp confess/;
use Sys::Hostname;
use File::Temp;
use Time::HiRes qw( time );
use Data::Dumper;
use File::Basename;
use lib dirname (__FILE__) . "/../";
use Phylogeny::Typer;
use Phylogeny::Tree;
use Phylogeny::TreeBuilder;

=head1 NAME

Sequences::ExperimentalFeatures;

=head1 DESCRIPTION

Based on perl package: Bio::GMOD::DB::Adapter

Provides interface to CHADO database for loading VF/AMR alleles.

=cut

# Calling program name
my $calling_program = 'genodo_allele_loader.pl';

my $DEBUG = 0;

# Tables in order that data is inserted
my @tables = (
	"feature",
	"private_feature",
	"feature_relationship",
	"private_feature_relationship",
	"pripub_feature_relationship",
	"feature_cvterm",
	"private_feature_cvterm",
	"featureloc",
	"private_featureloc",
	"featureprop",
	"private_featureprop",
	"tree",
	"feature_tree",
	"private_feature_tree",
	"snp_core",
	"snp_variation",
	"private_snp_variation",
	"snp_position",
	"private_snp_position",
	"gap_position",
	"private_gap_position",
	"core_region"
);

# Tables in order that data is updated
my @update_tables = (
	"tfeature",
	"tprivate_feature",
	"tfeatureloc",
	"tprivate_featureloc",
	"tfeatureprop",
	"tprivate_featureprop",
	"ttree",
	"tsnp_core",
);

my %update_table_names = (
	"tfeature" => 'feature',
	"tprivate_feature" => 'private_feature',
	"tfeatureloc" => 'featureloc',
	"tprivate_featureloc" => 'tprivate_featureloc',
	"tfeatureprop" => 'featureprop',
	"tprivate_featureprop" => 'private_featureprop',
	"ttree" => 'tree',
	"tsnp_core" => 'snp_core'
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
	pripub_feature_relationship  => "pripub_feature_relationship_feature_relationship_id_seq",
	private_featureprop          => "private_featureprop_featureprop_id_seq",
	private_featureloc           => "private_featureloc_featureloc_id_seq",
	private_feature_cvterm       => "private_feature_cvterm_feature_cvterm_id_seq",
	tree                         => "tree_tree_id_seq",
	feature_tree                 => "feature_tree_feature_tree_id_seq",
  	private_feature_tree         => "private_feature_tree_feature_tree_id_seq",
  	snp_core                     => "snp_core_snp_core_id_seq",
  	snp_variation                => "snp_variation_snp_variation_id_seq",
  	private_snp_variation        => "private_snp_variation_snp_variation_id_seq",
  	snp_position                 => "snp_position_snp_position_id_seq",
  	private_snp_position         => "private_snp_position_snp_position_id_seq",
  	gap_position                 => "gap_position_gap_position_id_seq",
  	private_gap_position         => "private_gap_position_gap_position_id_seq",
  	core_region                  => "core_region_core_region_id_seq"
);

# Primary key ID names
my %table_ids = (
	feature                      => "feature_id",
	feature_relationship         => "feature_relationship_id",
	featureprop                  => "featureprop_id",
	featureloc                   => "featureloc_id",
    feature_cvterm               => "feature_cvterm_id",
    private_feature              => "feature_id",
	private_feature_relationship => "feature_relationship_id",
	pripub_feature_relationship  => "feature_relationship_id",
	private_featureprop          => "featureprop_id",
	private_featureloc           => "featureloc_id",
    private_feature_cvterm       => "feature_cvterm_id",
    tree                         => "tree_id",
    feature_tree                 => "feature_tree_id",
  	private_feature_tree         => "feature_tree_id",
  	snp_core                     => "snp_core_id",
  	snp_variation                => "snp_variation_id",
  	private_snp_variation        => "snp_variation_id",
  	snp_position                 => "snp_position_id",
  	private_snp_position         => "snp_position_id",
  	gap_position                 => "gap_position_id",
  	private_gap_position         => "gap_position_id",
  	core_region                  => "core_region"
);

# Valid cvterm types for featureprops table
# hash: name => cv
my %fp_types = (
	copy_number_increase => 'sequence',
	match => 'sequence',
	panseq_function => 'local',
	stx1_subtype => 'local',
	stx2_subtype => 'local'
	
);

# Used in DB COPY statements
my %copystring = (
   feature                      => "(feature_id,organism_id,name,uniquename,type_id,seqlen,dbxref_id,residues)",
   feature_relationship         => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   featureprop                  => "(featureprop_id,feature_id,type_id,value,rank)",
   feature_cvterm               => "(feature_cvterm_id,feature_id,cvterm_id,pub_id,is_not,rank)",
   featureloc                   => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,locgroup,rank)",
   private_feature              => "(feature_id,organism_id,name,uniquename,type_id,seqlen,dbxref_id,upload_id,residues)",
   private_feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   pripub_feature_relationship  => "(feature_relationship_id,subject_id,object_id,type_id,rank)",
   private_featureprop          => "(featureprop_id,feature_id,type_id,value,upload_id,rank)",
   private_feature_cvterm       => "(feature_cvterm_id,feature_id,cvterm_id,pub_id,is_not,rank)",
   private_featureloc           => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,locgroup,rank)",
   tree                         => "(tree_id,name,format,tree_string)",
   feature_tree                 => "(feature_tree_id,feature_id,tree_id,tree_relationship)",
   private_feature_tree         => "(feature_tree_id,feature_id,tree_id,tree_relationship)",
   snp_core                     => "(snp_core_id,pangenome_region_id,allele,position,gap_offset,aln_column)",
   snp_variation                => "(snp_variation_id,snp_id,contig_collection_id,contig_id,locus_id,allele)",
   private_snp_variation        => "(snp_variation_id,snp_id,contig_collection_id,contig_id,locus_id,allele)",
   snp_position                 => "(snp_position_id,contig_collection_id,contig_id,pangenome_region_id,locus_id,region_start,locus_start,region_end,locus_end,locus_gap_offset)",
   private_snp_position         => "(snp_position_id,contig_collection_id,contig_id,pangenome_region_id,locus_id,region_start,locus_start,region_end,locus_end,locus_gap_offset)",
   gap_position                 => "(gap_position_id,contig_collection_id,contig_id,pangenome_region_id,locus_id,snp_id,locus_pos)",
   private_gap_position         => "(gap_position_id,contig_collection_id,contig_id,pangenome_region_id,locus_id,snp_id,locus_pos)",
   core_region                  => "(core_region_id,pangenome_region_id,aln_column)",
);

my %updatestring = (
	tfeature                      => "seqlen = s.seqlen, residues = s.residues",
	tfeatureloc                   => "fmin = s.fmin, fmax = s.fmin, strand = s.strand, locgroup = s.locgroup, rank = s.rank",
	tfeatureprop                  => "value = s.value",
	tprivate_feature              => "seqlen = s.seqlen, residues = s.residues",
	tprivate_featureloc           => "fmin = s.fmin, fmax = s.fmin, strand = s.strand, locgroup = s.locgroup, rank = s.rank",
	tprivate_featureprop          => "value = s.value",
	ttree                         => "tree_string = s.tree_string",
	tsnp_core                     => "position = s.position, gap_offset = s.gap_offset",
);

my %tmpcopystring = (
	tfeature                      => "(feature_id,organism_id,uniquename,type_id,seqlen,residues)",
	tfeatureprop                  => "(feature_id,type_id,value,rank)",
	tfeatureloc                   => "(feature_id,fmin,fmax,strand,locgroup,rank)",
	tprivate_feature              => "(feature_id,organism_id,uniquename,type_id,seqlen,residues)",
	tprivate_featureprop          => "(feature_id,type_id,value,rank)",
	tprivate_featureloc           => "(feature_id,fmin,fmax,strand,locgroup,rank)",
	ttree                         => "(tree_id,name,tree_string)",
	tsnp_core                     => "(snp_core_id,pangenome_region_id,position,gap_offset)"
);

my %joinstring = (
	tfeature                      => "s.feature_id = t.feature_id",
	tfeatureloc                   => "s.feature_id = t.feature_id",
	tfeatureprop                  => "s.feature_id = t.feature_id AND s.type_id = t.type_id",
	tprivate_feature              => "s.feature_id = t.feature_id",
	tprivate_featureloc           => "s.feature_id = t.feature_id",
	tprivate_featureprop          => "s.feature_id = t.feature_id AND s.type_id = t.type_id",
	ttree                         => "s.tree_id = t.tree_id",
	tsnp_core                     => "s.snp_core_id = t.snp_core_id"
);


# Key values for loci cache
my $ALLOWED_LOCI_CACHE_KEYS = "feature_id|uniquename|genome_id|query_id|is_public|insert|update";
               
# Tables for which caches are maintained
my $ALLOWED_CACHE_KEYS = "collection|contig|feature|sequence|core|core_snp|snp_alignment|uploaded_feature|core_alignment|core_region";

# Tmp file names for storing upload data
my %files = map { $_ => 'FH'.$_; } @tables, @update_tables;

# common SQL
use constant VERIFY_TMP_TABLE => "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
	
           
            
=head2 new

Constructor

=cut

sub new {
	my $class = shift;
	my %arg   = @_;
	
	$DEBUG = 1 if $arg{debug};
	
	my $self  = bless {}, ref($class) || $class;
	
	$self->{now} = time();
	
	my $dbname  =  $arg{dbname};
	my $dbport  =  $arg{dbport};
	my $dbhost  =  $arg{dbhost};
	my $dbuser  =  $arg{dbuser};
	my $dbpass  =  $arg{dbpass};
	my $tmp_dir =  $arg{tmp_dir};
	croak "Missing argument: tmp_dir." unless $tmp_dir;
	
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
	
	$self->{db_cache} = 0;
	$self->{db_cache} = 1 if $arg{use_cached_names};
	
	my $ft = $arg{feature_type};
	croak "Missing/invalid argument: feature_type. Must be (allele|pangenome)" unless $ft && ($ft eq 'allele' || $ft eq 'pangenome');
	$self->{feature_type} = $ft;
	
	$self->{snp_aware} = 0;
	$self->{snp_aware} = 1 if $ft eq 'pangenome';
	
	$self->initialize_sequences();
	$self->initialize_ontology();
	$self->initialize_db_caches();
	$self->initialize_snp_caches() if $self->{snp_aware};
	$self->prepare_queries();
	
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
    
    # Located In ID
	$fp_sth->execute('located_in', 'relationship');
    my ($located_in) = $fp_sth->fetchrow_array();
    
    # Similar To ID
	$fp_sth->execute('similar_to', 'sequence');
    my ($similar_to) = $fp_sth->fetchrow_array();
    
    # Derives From ID
	$fp_sth->execute('derives_from', 'relationship');
    my ($derives_from) = $fp_sth->fetchrow_array();
    
    # Derives From ID
	$fp_sth->execute('contained_in', 'relationship');
    my ($contained_in) = $fp_sth->fetchrow_array();

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
    
    # SNP ID
    $fp_sth->execute('sequence_variant', 'sequence');
    my ($snp) = $fp_sth->fetchrow_array();
    
    # Pangenome Loci ID
    $fp_sth->execute('locus', 'local');
    my ($locus) = $fp_sth->fetchrow_array();
    
    # Pangenome Reference ID
    $fp_sth->execute('pangenome', 'local');
    my ($pan) = $fp_sth->fetchrow_array();
    
    # core_genome ID
    $fp_sth->execute('core_genome', 'local');
    my ($core) = $fp_sth->fetchrow_array();
    
    # Typing gene ID
    $fp_sth->execute('typing_sequence', 'local');
    my ($typing) = $fp_sth->fetchrow_array();
    
    # Allele fusion ID
    $fp_sth->execute('allele_fusion', 'local');
    my ($fusion) = $fp_sth->fetchrow_array();
    
    # Fusion of relationship ID
    $fp_sth->execute('fusion_of', 'local');
    my ($fusion_of) = $fp_sth->fetchrow_array();
    
    # Variant of relationship ID
    $fp_sth->execute('variant_of', 'sequence');
    my ($variant_of) = $fp_sth->fetchrow_array();
    
    
    $self->{feature_types} = {
    	contig_collection => $contig_col,
    	contig => $contig,
    	allele => $allele,
    	experimental_feature => $experimental_feature,
    	snp => $snp,
    	locus => $locus,
    	pangenome => $pan,
    	core_genome => $core,
    	typing_sequence => $typing,
    	allele_fusion => $fusion
    };
    
	$self->{relationship_types} = {
    	part_of => $part_of,
    	similar_to => $similar_to,
    	located_in => $located_in,
    	derives_from => $derives_from,
    	contained_in => $contained_in,
    	fusion_of => $fusion_of,
    	variant_of => $variant_of
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
	$p_sth->execute();
	($self->{pub_id}) = $p_sth->fetchrow_array();
	
    # Default organism
    my $o_sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE common_name = ?"); 
    my @organisms = ('Escherichia coli');
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
		print "NEXTVAL on $table\n" if $DEBUG;
		
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


=head2 initialize_db_cache

=over

=item Usage

  $obj->initialize_db_cache()

=item Function

Creates an intermediary cache of all key features to ensure no dublication in the DB

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_db_caches {
    my $self = shift;
    
    my $is_pg = $self->{feature_type} eq 'pangenome' ? 1 : 0;
    
    my $table = 'tmp_allele_cache';
    my $type_id = $self->feature_types('allele');
    if($is_pg) {
    	$table = 'tmp_loci_cache';
    	$type_id = $self->feature_types('locus');
    }
    $self->{loci_cache}{table} = $table;
    $self->{loci_cache}{type} = $type_id;
    $self->{loci_cache}{is_pangenome} = $is_pg;
    
    # Initialize cache table 
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE); 
    $sth->execute($table);
    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists || $self->recreate_cache() ) {
    	# Rebuild cache
        print STDERR "(Re)creating the $table cache in the database... ";
        
        # Discard old table
        if ($self->recreate_cache() and $table_exists) {
        	my $sql = "DROP TABLE $table";
        	$dbh->do($sql); 
        }

		# Create new table
        print STDERR "\nCreating table...\n";
        my $sql = "CREATE TABLE $table (
			feature_id int,
			uniquename varchar(1000),                
			genome_id int,                   
			query_id int,                 
			pub boolean
		)";
        $dbh->do($sql); 
    	
        # Populate table
        my $reltype = $is_pg ? 'derives_from' : 'similar_to';
        print STDERR "Populating table...\n";
        $sql = "INSERT INTO $table
		SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, TRUE
		FROM feature f, feature_relationship f1, feature_relationship f2
		WHERE f.type_id = $type_id AND
		  f1.type_id = ".$self->relationship_types('part_of')." AND f1.subject_id = f.feature_id AND
		  f2.type_id = ".$self->relationship_types($reltype)." AND f2.subject_id = f.feature_id";
        $dbh->do($sql);
        $sql = "INSERT INTO $table
		SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, FALSE
		FROM private_feature f, private_feature_relationship f1, private_feature_relationship f2
		WHERE f.type_id = $type_id AND
		  f1.type_id = ".$self->relationship_types('part_of')." AND f1.subject_id = f.feature_id AND
		  f2.type_id = ".$self->relationship_types($reltype)." AND f2.subject_id = f.feature_id";
        $dbh->do($sql);
        
        # Add typing features if working with gene alleles
        unless ($is_pg) {
        	$type_id = $self->feature_types('allele_fusion');
        	$reltype = 'variant_of';
        	$sql = "INSERT INTO $table
			SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, TRUE
			FROM feature f, feature_relationship f1, feature_relationship f2
			WHERE f.type_id = $type_id AND
			  f1.type_id = ".$self->relationship_types('part_of')." AND f1.subject_id = f.feature_id AND
			  f2.type_id = ".$self->relationship_types($reltype)." AND f2.subject_id = f.feature_id";
	        $dbh->do($sql);
	        $sql = "INSERT INTO $table
			SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, FALSE
			FROM private_feature f, private_feature_relationship f1, private_feature_relationship f2
			WHERE f.type_id = $type_id AND
			  f1.type_id = ".$self->relationship_types('part_of')." AND f1.subject_id = f.feature_id AND
			  f2.type_id = ".$self->relationship_types($reltype)." AND f2.subject_id = f.feature_id";
	        $dbh->do($sql);
        }
       	
       	# Build indices
        print STDERR "Creating indexes...\n";
        $sql = "CREATE INDEX $table\_idx1 ON $table (genome_id,query_id,pub)";
        $dbh->do($sql);
        $sql = "CREATE INDEX $table\_idx2 ON $table (uniquename)";
        $dbh->do($sql);
       
        print STDERR "Done.\n";
    }
    
    #$dbh->do(TMP_LOCI_RESET, undef, 'FALSE');
    $self->{loci_cache}{new_loci} = {}; # Use memory to track new loci added during this run
    $self->{loci_cache}{updated_loci} = {}; # Use memory to track altered loci during this run
    my $file_path = $self->{tmp_dir};
    my $tmpfile = new File::Temp(
		TEMPLATE => "chado-cache-XXXX",
		SUFFIX   => '.dat',
		UNLINK   => $self->save_tmpfiles() ? 0 : 1, 
		DIR      => $file_path,
	);
	chmod 0644, $tmpfile;
	$self->{loci_cache}{fh} = $tmpfile;
	
	unless($is_pg) {
		# Cache allele data needed for typing
		
		# Retrieve query gene Ids needed in typing
		$type_id = $self->feature_types('typing_sequence');
		my $rel_id = $self->relationship_types('fusion_of');
		
		my $sql = "SELECT r.object_id, r.subject_id, r.rank, f.uniquename
		FROM feature f, feature_relationship r 
		WHERE f.type_id = $type_id AND
		  r.subject_id = f.feature_id AND
		  r.type_id = $rel_id";
		  
		my $feature_arrayref = $dbh->selectall_arrayref($sql);
		
		my %typing_constructs;
		my %typing_watchlists;
		my %typing_seq_names;
		
		map { 
			$typing_constructs{$_->[1]}{$_->[2]} = $_->[0]; 
			$typing_watchlists{$_->[0]} = {}; 
			$typing_seq_names{$_->[1]} = $_->[3]; 
		} @$feature_arrayref;
		
		# Record order that alleles are concatenated to form typing sequence
		$self->{loci_cache}{typing_construct} = \%typing_constructs;
		
		# Record query gene IDs to watch for to build typing sequences
		$self->{loci_cache}{typing_watchlist} = \%typing_watchlists;
		
		# Name to ID mapping
		$self->{loci_cache}{typing_names} = \%typing_seq_names;
		
		# Name to Featureprop mapping
		$self->{loci_cache}{typing_featureprops} = {
			'stx1_subunit' => 'stx1_subtype',
			'stx2_subunit' => 'stx2_subtype',
		};
		
		
	}
	
    $dbh->commit;
    
    return;
}

=head2 initialize_snp_caches

=over

=item Usage

  $obj->initialize_snp_caches()

=item Function

Creates the helper tables in the database for recording core pan-genome
alignment of SNPs.

UPDATE: also creates helper cache tables for recording core pan-genome region
presence/absence

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_snp_caches {
    my $self = shift;

	my $dbh = $self->dbh;
	
	# Store the core snp alignment in memory for faster access
	my $sql = "SELECT max(aln_column) FROM snp_alignment WHERE name = 'core'";
	my $sth = $dbh->prepare($sql);
    $sth->execute();
    my ($pos) = $sth->fetchrow_array();
    $self->{snp_alignment}->{core_alignment} = '';
    $self->{snp_alignment}->{core_position} = $pos // 0;
    
	# Create tmp table
	$sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('tmp_snp_cache');
    my ($table_exists) = $sth->fetchrow_array;
    if($table_exists) {
    	my $sql = "DROP TABLE tmp_snp_cache";
    	$dbh->do($sql);
    }
   
   $sql = 
	"CREATE TABLE public.tmp_snp_cache (
		name varchar(100),
		aln_column int,
		nuc char(1)
	)";
    $dbh->do($sql);
    
    # Prepare bulk insert
    my $bulk_set_size = 10000;
    my $insert_query = 'INSERT INTO tmp_snp_cache (name,aln_column,nuc) VALUES (?,?,?)';
    $insert_query .= ', (?,?,?)' x ($bulk_set_size-1);
    $self->{snp_alignment}{insert_tmp_variations} = $dbh->prepare($insert_query);
    $self->{snp_alignment}{bulk_set_size} = $bulk_set_size;
    
    # Setup up insert buffer
	$self->{snp_alignment}{buffer_stack} = []; 
	$self->{snp_alignment}{buffer_num} = 0; 
	$self->{snp_alignment}{new_rows} = [];
	
	
	
	# Setup core region cache
	$sql = "SELECT max(aln_column) FROM core_alignment WHERE name = 'core'";
	$sth = $dbh->prepare($sql);
    $sth->execute();
    ($pos) = $sth->fetchrow_array();
    $self->{core_alignment}->{added_columns} = 0;
    $self->{core_alignment}->{core_position} = $pos // 0;
	
	
	# Create tmp table
	$sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('tmp_core_pangenome_cache');
    ($table_exists) = $sth->fetchrow_array;
    if($table_exists) {
    	my $sql = "DROP TABLE tmp_core_pangenome_cache";
    	$dbh->do($sql);
    }
   
   $sql = 
	"CREATE TABLE public.tmp_core_pangenome_cache (
		genome varchar(100),
		aln_column int
	)";
    $dbh->do($sql);
    
    # Prepare bulk insert
    $bulk_set_size = 100;
    $insert_query = 'INSERT INTO tmp_core_pangenome_cache (genome,aln_column) VALUES (?,?)';
    $insert_query .= ', (?,?)' x ($bulk_set_size-1);
    $self->{core_alignment}{insert_tmp_presence} = $dbh->prepare($insert_query);
    $self->{core_alignment}{bulk_set_size} = $bulk_set_size;
    
    # Setup up insert buffer
	$self->{core_alignment}{buffer_stack} = []; 
	$self->{core_alignment}{buffer_num} = 0; 
	$self->{core_alignment}{new_rows} = [];
    
    $dbh->commit;
    
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

	foreach my $file (@tables, @update_tables) {
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
  my $arg  = shift if @_;
  
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
   
    my $sql = "SELECT name,hostname,starttime FROM gff_meta";
    my $select_query = $dbh->prepare($sql) or carp "Select prepare failed";
    $select_query->execute() or carp "Select from meta failed";

	$sql = "DELETE FROM gff_meta WHERE name = ? AND hostname = ?";
    my $delete_query = $dbh->prepare($sql) or carp "Delete prepare failed";

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
		my $sql =  
		"CREATE TABLE gff_meta (
			name        varchar(100),
			hostname    varchar(100),
			starttime   timestamp not null default now() 
		)";
       $dbh->do($sql);
       
    } else {
    	# check for existing lock
    	
    	my $sql = "SELECT name,hostname,starttime FROM gff_meta";
	    my $select_query = $dbh->prepare($sql);
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

	my $sql = "INSERT INTO gff_meta (name,hostname) VALUES (?,?)";
    my $insert_query = $dbh->prepare($sql);
    $insert_query->execute($name,$hostname);
    $dbh->commit;

    return;
}

=head2 loci_cache

=over

=item Usage

  $obj->loci_cache()

=item Function

Maintains a cache of unique alleles added/updated during this run

=item Returns

See Arguements.

=item Arguments

loci_cache takes a hash as input. If the key 'insert' is included,
values are added to new cache hash. If the key 'update' is included,
values are added to the update cache hash. 

Allowed hash keys:

  feature_id
  uniquename
  update|insert
  

=back

=cut

sub loci_cache {
	my ($self, %argv) = @_;
	
	my @bogus_keys = grep {!/($ALLOWED_LOCI_CACHE_KEYS)/} keys %argv;
	
	if (@bogus_keys) {
		for (@bogus_keys) {
		    carp "Error in loci_cache input: I don't know what to do with the key ".$_.
		   " in the loci_cache method; it's probably because of a typo\n";
		}
		croak;
	}
		
	my ($insert) = ($argv{insert} ? 1 : 0);
	my ($update) = ($argv{update} ? 1 : 0);
	
	if($update && $insert) {
		croak "Error in loci_cache input: either 'insert' or 'update' must be specified."
	}
	unless($update || $insert) {
		croak "Error in loci_cache input: 'insert' or 'update' must be specified.";
	}
	
	my %info = %argv;
	
	if($insert) {
		$self->{loci_cache}{new_loci}{$argv{uniquename}} = \%info;
		my $fh = $self->{loci_cache}{fh};
		print $fh join("\t", ($info{feature_id},$info{uniquename},$info{genome_id},$info{query_id},$info{is_public})),"\n";
	} else {
		$self->{loci_cache}{updated_loci}{$argv{uniquename}} = $info{feature_id};
	}
	
	return;
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
    
    return $self->{cache}{$top_level} unless defined($key);
    
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
    my $first_feature_id = shift if @_;
    return $self->{'first_feature_id'} = $first_feature_id if defined($first_feature_id);
    return $self->{'first_feature_id'};
}

sub first_private_feature_id {
    my $self = shift;
    my $first_feature_id = shift if @_;
    return $self->{'first_private_feature_id'} = $first_feature_id if defined($first_feature_id);
    return $self->{'first_private_feature_id'};
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
    
	# Queries for obtaining feature info
	my $sql = "SELECT uniquename, organism_id, residues, seqlen FROM feature WHERE feature_id = ?";
	$self->{'queries'}{'select_from_public_feature'} = $dbh->prepare($sql);
	$sql = "SELECT uniquename, organism_id, upload_id, residues, seqlen FROM private_feature WHERE feature_id = ?";
	$self->{'queries'}{'select_from_private_feature'} = $dbh->prepare($sql);
	
	# Loci table
	my $table = $self->{loci_cache}{table};
	$sql = "SELECT feature_id FROM $table WHERE genome_id = ? AND query_id = ? AND uniquename = ? AND pub = ? ";
	$self->{'queries'}{'validate_loci'} = $dbh->prepare($sql);
	$sql = "SELECT feature_id FROM $table WHERE uniquename = ? ";
	$self->{'queries'}{'validate_loci_name'} = $dbh->prepare($sql);
	
	# Tree table
	$sql = "SELECT tree_id FROM tree WHERE name = ?";
	$self->{'queries'}{'validate_tree'} = $dbh->prepare($sql);
	
	# Pangenome utilities
	$sql = "SELECT feature_id FROM feature WHERE uniquename = ? AND type_id = ?";
	$self->{'queries'}{'retrieve_pangenome_id'} = $dbh->prepare($sql);
	
	# Cache table
	if($self->{db_cache}) {
		$sql = "SELECT collection_id, contig_id FROM pipeline_cache WHERE tracker_id = ? AND chr_num = ?";
		$self->{'queries'}{'retrieve_id'} = $dbh->prepare($sql);
	}
	
	# SNP stuff
	if($self->{snp_aware}) {
		# SNP tables
		$sql = "SELECT snp_core_id, aln_column FROM snp_core WHERE pangenome_region_id = ? AND position = ? AND gap_offset = ?";
		$self->{'queries'}{'validate_core_snp'} = $dbh->prepare($sql);
		$sql = "SELECT snp_variation_id FROM snp_variation WHERE snp_id = ? AND contig_collection_id = ?";
		$self->{'queries'}{'validate_public_snp'} = $dbh->prepare($sql);
		$sql = "SELECT snp_variation_id FROM private_snp_variation WHERE snp_id = ? AND contig_collection_id = ?";
		$self->{'queries'}{'validate_private_snp'} = $dbh->prepare($sql);
		# SNP alignment tables
		$sql = "SELECT count(*) FROM snp_alignment WHERE name = ?";
		$self->{'queries'}{'validate_snp_alignment'} = $dbh->prepare($sql);
		$sql = "SELECT contig_collection_id, locus_id, allele FROM snp_variation WHERE snp_id = ?";
		$self->{'queries'}{'retrieve_public_snp_column'} = $dbh->prepare($sql);
		$sql = "SELECT contig_collection_id, locus_id, allele FROM private_snp_variation WHERE snp_id = ?";
		$self->{'queries'}{'retrieve_private_snp_column'} = $dbh->prepare($sql);
		# Core alignment queries
		$sql = "SELECT count(*) FROM core_alignment WHERE name = ?";
		$self->{'queries'}{'validate_core_alignment'} = $dbh->prepare($sql);
		$sql = "SELECT aln_column FROM core_region WHERE pangenome_region_id = ?";
		$self->{'queries'}{'validate_core_region'} = $dbh->prepare($sql);
		
	}
	
	
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
	
	foreach my $table (@update_tables) {
	
		$self->file_handles($files{$table})->autoflush;
		
		if (-s $self->file_handles($files{$table})->filename <= 4) {
			warn "Skipping $table table since the load file is empty...\n";
			next;
		}
		
		$self->update_from_stdin(
			$update_table_names{$table},
			$table,
			$tmpcopystring{$table},
			$updatestring{$table},
			$joinstring{$table},
			$files{$table} #file_handle name
		);
	}

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
	
	# Update cache with newly created loci/allele features added in this run
	$self->push_cache();
	
	# Do live replacement of snp_alignment and core_alignment tables
	if($self->{snp_aware}) {
		$self->push_core_alignment();
		$self->push_snp_alignment();
	}
	 
	
	$self->dbh->commit() || croak "Commit failed: ".$self->dbh->errstr();
	
	if($self->vacuum) {
		warn "Optimizing database (this may take a while) ...\n";
		warn "  ";
		
		foreach (@tables) {
			warn "$_ ";
			$self->dbh->do("VACUUM ANALYZE $_");
		}
		$self->dbh->do("VACUUM ANALYZE snp_alignment") if $self->{snp_aware};
		
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
			# error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $file, line $.");
		} # putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $table failed: $!");

	#update the sequence so that later inserts will work
	$dbh->do("SELECT setval('$sequence', $nextval) FROM $table")
		or croak("Error when executing:  setval('$sequence', $nextval) FROM $table: $!"); 
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

sub update_from_stdin {
	my $self          = shift;
	my $ttable        = shift;
	my $stable        = shift;
	my $copy_fields   = shift;
	my $update_fields = shift;
	my $join          = shift;
	my $file          = shift;

	my $dbh      = $self->dbh();

	warn "Updating data in $ttable table ...\n";

	my $fh = $self->file_handles($file);
	seek($fh,0,0);
	
	my $query1 = "CREATE TEMP TABLE $stable (LIKE $ttable INCLUDING ALL) ON COMMIT DROP";
	$dbh->do($query1) or croak("Error when executing: $query1 ($!).\n");
	
	my $query2 = "COPY $stable $copy_fields FROM STDIN;";
	print STDERR $query2,"\n";

	$dbh->do($query2) or croak("Error when executing: $query2 ($!).\n");

	while (<$fh>) {
		if ( ! ($dbh->pg_putline($_)) ) {
			# error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $file, line $.");
		} # putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $stable failed: $!");
	
	# update the target table
	my $query3 = "UPDATE $ttable t SET $update_fields FROM $stable s WHERE $join";
	
	$dbh->do("$query3") or croak("Error when executing: $query3 ($!).\n");
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

=head2 validate_feature

=over

=item Usage

  $obj->validate_feature($query_id, $contig_collection_id, $uniquename, $is_public)

=item Function

Checks if experimental feature is in caches (DB or hash). Returns feature_id if found.
Also indicates if this is a new feature added during current run, or is in DB from
previous run. Returns a result string as follows:

  1. new - allele/locus entirely new (not in db or mem cache)
  2. new_conflict - allele/locus at that position for given genome already loaded in this run
  3. db - allele/locus in db (so loaded in previous run, being updated in this run)
  4. db_conflict - allele/locus in db already been updated in this run

=item Returns

Array containing:
  1. Result string (new|new_conflict|db|db_conflict)
  2. Feature ID or undef

=item Arguments

The feature_id for the query gene feature, contig collection, the uniquename and a boolean indicating public or private

=back

=cut

sub validate_feature {
    my $self = shift;
	my ($query_id, $cc_id, $un, $pub) = @_;
	
	# Check memory caches
	if($self->{loci_cache}{new_loci}{$un}) {
		return('new_conflict', $self->{loci_cache}{new_loci}{$un}{feature_id});
	}
	if($self->{loci_cache}{updated_loci}{$un}) {
		return('db_conflict', $self->{loci_cache}{updated_loci}{$un});
	}
	
	# Check db cache
    $self->{queries}{'validate_loci'}->execute($cc_id, $query_id, $un, $pub);
	my ($allele_id, $allele_name) = $self->{queries}{'validate_loci'}->fetchrow_array;
	
	# Situation specific to pangenome:
	# Only one pangenome fragment can be mapped to each region of the genome.
	# The pangenome loci uniquename is specific to a region of the genome, so if there are
	# multiple pangenome fragments mapping to the same region, need to return
	# db_conflict.
	# This does not apply to gene alleles, where multiple genes can map to the
	# same region and the same region can map to multiple genes.
	# Gene allele uniquenames are specific to a region and gene type.
	if($self->{loci_cache}{is_pangenome}) {
		 $self->{queries}{'validate_loci_name'}->execute($un);
		 my ($allele_id, $allele_name) = $self->{queries}{'validate_loci_name'}->fetchrow_array;
		 return('db_conflict', $allele_id) if $allele_id;
	}
	
	
	if($allele_id) {
		# return existing allele ID
		return('db',$allele_id);
		
	} else {
		# no existing allele
		return('new',undef);
	}
}


=head2 validate_snp_alignment

=over

=item Usage

  $obj->validate_snp_alignment($genome_feature_id, $is_public)

=item Function

Determines if snp alignment exists for given genome.

=item Returns

1 if not found, else 0 if entry already exists

=item Arguments

The feature_id for the contig collection feature, and a boolean indicating public or private

=back

=cut

sub validate_snp_alignment {
    my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	
	my $pre = $is_public ? 'public_':'private_';
	my $genome = $pre . $genome_id;
	
	unless($self->cache('snp_alignment', $genome)) {
	
		$self->{queries}{'validate_snp_alignment'}->execute($genome);
		my ($found) = $self->{queries}{'validate_snp_alignment'}->fetchrow_array;
		
		if($found) {
			$self->cache('snp_alignment', $genome, 1);
			return 0;
		} else {
			return 1;
		}
		
	} else {
		return 0;
	}
	
}

=head2 retrieve_core_snp

=over

=item Usage

  $obj->retrieve_core_snp($query_id, $pos, $gap_offset)

=item Function



=item Returns

Nothing

=item Arguments

The feature_id for the query pangenome feature, and position of snp in pangenome region

=back

=cut

sub retrieve_core_snp {
    my $self = shift;
	my ($id, $pos, $gap_offset) = @_;
	
	# Search for existing core snp entries in cached values
	my ($core_snp_id, $column);
	
	if(defined $self->cache('core_snp', "$id.$pos.$gap_offset")) {
		($core_snp_id, $column) = @{$self->cache('core_snp', "$id.$pos.$gap_offset")};
	} else {
		# Search for existing entries in snp_core table
		$self->{queries}{'validate_core_snp'}->execute($id,$pos,$gap_offset);
		($core_snp_id, $column) = $self->{queries}{'validate_core_snp'}->fetchrow_array;
		
		$self->cache('core_snp', "$id.$pos.$gap_offset", [$core_snp_id, $column]) if $core_snp_id;
	}
	
	return ($core_snp_id, $column);
}

=head2 validate_core_alignment

=over

=item Usage

  $obj->validate_core_alignment($genome_feature_id, $is_public)

=item Function

Determines if core alignment exists for given genome.

=item Returns

1 if not found, else 0 if entry already exists

=item Arguments

The feature_id for the contig collection feature, and a boolean indicating public or private

=back

=cut

sub validate_core_alignment {
    my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	
	my $pre = $is_public ? 'public_':'private_';
	my $genome = $pre . $genome_id;
	
	unless($self->cache('core_alignment', $genome)) {
	
		$self->{queries}{'validate_core_alignment'}->execute($genome);
		my ($found) = $self->{queries}{'validate_core_alignment'}->fetchrow_array;
		
		if($found) {
			$self->cache('core_alignment', $genome, 1);
			return 0;
		} else {
			return 1;
		}
		
	} else {
		return 0;
	}
	
}

=head2 retrieve_core_column

=over

=item Usage

  $obj->retrieve_core_column($query_id)

=item Function

Returns and caches the column associated with a
core pangenome region

=item Returns

Column id associated with the core pangenome feature

=item Arguments

The feature_id for the query pangenome feature

=back

=cut

sub retrieve_core_column {
    my $self = shift;
	my ($id) = @_;
	
	# Search for existing core snp entries in cached values
	my $column;
	
	if(defined $self->cache('core_region', $id)) {
		$column = $self->cache('core_region', $id);
	} else {
		# Search for existing entries in snp_core table
		$self->{queries}{'validate_core_region'}->execute($id);
		$column = $self->{queries}{'validate_core_region'}->fetchrow_array;
		
		$self->cache('core_region', $id,  $column) if defined $column;
	}
	
	return $column;
}


=head2 retrieve_chr_info

=over

=item Usage

  $obj->retrieve_contig_info(tracker_id, chr_num)

=item Function

Returns the chromosome information for given tmp
chromosome/contig ID

=item Returns

Feature IDs for contig_collection and contig matching
the arguments

=item Arguments

A tracker_id and chr_num in the table pipeline_cache table

=back

=cut

sub retrieve_contig_info {
	my ($self, $tracking_id, $chr_num) = @_;
	
	
	my ($contig_collection_id, $contig_id);
	my $cache_name = 'uploaded_feature';
	my $cache_key = "tracker_id:$tracking_id.chr_num:$chr_num";
	
	if(defined $self->cache($cache_name, $cache_key)) {
		# Search for matching entries in cached values
		($contig_collection_id, $contig_id) = @{$self->cache($cache_name, $cache_key)};
	} else {
		# Search for existing entries in DB pipeline cache table
		$self->{'queries'}{'retrieve_id'}->execute($tracking_id, $chr_num);
		($contig_collection_id, $contig_id) = $self->{'queries'}{'retrieve_id'}->fetchrow_array();
		
		$self->cache($cache_name, $cache_key, [$contig_collection_id, $contig_id]) if $contig_id;
	}
	
	return ($contig_collection_id, $contig_id);
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
		$self->print_frel($self->nextoid($table),$child_id,$parent_id,$type,$rank,$pub);
		$self->nextoid($table,'++');
		
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
    
    # vf/amr query features are always in public table, so if genome is private
    # this requires the pripub_feature_relationship table
    unless($pub) {
    	$self->add_relationship($child_id, $parent_id, 'similar_to', 0, 1); 
    } else {
    	$self->add_relationship($child_id, $parent_id, 'similar_to', $pub); 
    }
}

=head2 handle_pangenome_loci

=over

=item Usage

  $obj->handle_pangenome_loci($child_feature_id, $query_gene_id, $is_public)

=item Function

Create 'derives_from' entry in feature_relationship table. Adds presence
symbol to core pangenome alignment strings

=item Returns

Nothing

=item Arguments

The feature_id for the child feature, query gene and a boolean indicating public or private

=back

=cut

sub handle_pangenome_loci {
    my $self = shift;
    my ($child_id, $parent_id, $pub, $genome_id) = @_;
    
    # pangenome query features are always in public table, so if genome is private
    # this requires the pripub_feature_relationship table
    unless($pub) {
    	$self->add_relationship($child_id, $parent_id, 'derives_from', 0, 1); 
    } else {
    	$self->add_relationship($child_id, $parent_id, 'derives_from', $pub); 
    }
    
    if($self->cache('core', $parent_id)) {
    	# This is core region
    	
    	# Retrieve column for core region
		my $column = $self->retrieve_core_column($parent_id);
		
		croak "Error: no alignment column assigned to core pangenome region $parent_id." unless defined $column;
		
		# Update snp in alignment for genome
		$self->has_core_region($genome_id,$pub,$column);
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
	                              	
	$self->print_floc($self->nextoid($table),$f_id,$src_id,$min,$max,$strand,$locgrp,$rank,$pub);
	$self->nextoid($table,'++');
    
}

=cut

=head2 handle_allele_properties

=over

=item Usage

  $obj->handle_allele_properties($feature_id, $percent_identity, $is_public, $upload_id)

=item Function

Create featureprop table entries for BLAST results

=item Returns

Nothing

=item Arguments

percent identity, 

=back

=cut

sub handle_allele_properties {
	my $self = shift;
	my ($feature_id, $allele_copy, $pub, $upload_id) = @_;
	
	# assign the copy number
	my $tag = 'copy_number_increase';
      
 	my $property_cvterm_id = $self->featureprop_types($tag);
	unless($property_cvterm_id) {
		carp "Unrecognized feature property type $tag.";
	}
 	
 	my $rank=0;
 	
    my $table = $pub ? 'featureprop' : 'private_featureprop';
	                        	
	$self->print_fprop($self->nextoid($table),$feature_id,$property_cvterm_id,$allele_copy,$rank,$pub,$upload_id);
    $self->nextoid($table,'++');
    
}

=cut

=head2 handle_phylogeny

=over

=item Usage

  $obj->handle_phylogeny($seq_group)

=item Function

  Save tree in table. Link allele and query to tree entry.

=item Returns

Nothing

=item Arguments

??

=back

=cut

sub handle_phylogeny {
	my $self = shift;
	my ($tree, $query_id, $seq_group) = @_;
	
	my $tree_name = "q$query_id"; # Base name on the query gene used to search for the alleles
	
	# check if tree entry already exists
	$self->{queries}{validate_tree}->execute($tree_name);
	my ($tree_id) = $self->{queries}{validate_tree}->fetchrow_array();
	
	if($tree_id) {
		# update existing tree
		$self->print_utree($tree_id, $tree_name, $tree);
		
		# add new tree-feature relationships
		foreach my $genome_hash (@$seq_group) {
			my $allele_id = $genome_hash->{allele};
			if($genome_hash->{is_new}) {
				my $pub = $genome_hash->{public};
				my $table = $pub ? 'feature_tree' : 'private_feature_tree';
				
				$self->print_ftree($self->nextoid($table),$tree_id,$allele_id,'allele',$pub);
				$self->nextoid($table,'++');
			}
		}
		
	} else {
		# create new tree
		
		$tree_id = $self->nextoid('tree');
		
		# build tree-feature relationships
		# query
		                                  	
		$self->print_ftree($self->nextoid('feature_tree'),$tree_id,$query_id,'locus',1);
		$self->nextoid('feature_tree','++');
		
		# alleles
		foreach my $genome_hash (@$seq_group) {
			my $allele_id = $genome_hash->{allele};
			my $pub = $genome_hash->{public};
			my $table = $pub ? 'feature_tree' : 'private_feature_tree';
			                              	
			$self->print_ftree($self->nextoid($table),$tree_id,$allele_id,'allele',$pub);
			$self->nextoid($table,'++');
		}
		
		# print tree
		$self->print_tree($tree_id,$tree_name,'perl',$tree);
		$self->nextoid('tree','++');
	}

}

=cut

=head2 handle_pangenome_segment

=over

=item Usage

  $obj->handle_pangenome_segment()

=item Function



=item Returns

Nothing

=item Arguments



=back

=cut

sub handle_pangenome_segment {
	my $self = shift;
	my ($in_core, $func, $func_id, $seq) = @_;
	
	# Create pangenome feature
	
	# Public Feature ID
	my $is_public = 1;
	my $curr_feature_id = $self->nextfeature($is_public);
	
	# Default organism
	my $organism = $self->organism_id();
		
	# Null external accession
	my $dbxref = '\N';
	
	# Feature type
	my $type = $self->feature_types('pangenome');
	
	# Sequence length
	my $seqlen = length $seq;
		
	# uniquename & name
	my $pre = $in_core ? 'core ' : 'accessory ';
	my $name = my $uniquename = $pre ."pan-genome fragment $curr_feature_id";
	
	# Core designation
	my $core_value = $in_core ? 'FALSE' : 'TRUE';
	my $core_type = $self->feature_types('core_genome');
    my $rank = 0;

	my $table = 'feature_cvterm';
	                             	
	$self->print_fcvterm($self->nextoid($table), $curr_feature_id, $core_type, $self->publication_id, $rank, $is_public, $core_value);
	$self->nextoid($table,'++');
		
	# assign pangenome function properties
	my @tags;
	my @values;
	if($func) {
		push @tags, 'panseq_function';
		push @values, $func;
	}
	if($func_id) {
		push @tags, 'match';
		push @values, $func_id;
	}
	
	foreach my $tag (@tags) {
		
		my $property_cvterm_id = $self->featureprop_types($tag);
		unless($property_cvterm_id) {
			carp "Unrecognized feature property type $tag.";
		}
		
	 	my $rank=0;
	 	
	    my $table = 'featureprop';
	    my $value = shift @values;
		
		$self->print_fprop($self->nextoid($table),$curr_feature_id,$property_cvterm_id,$value,$rank,$is_public);
	    $self->nextoid($table,'++');
	}
	
	# Print pangenome feature
	$self->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $seq, $is_public);  
	$self->nextfeature($is_public, '++');
	
	
	# Create column in core alignment for this new core region		
	my $column = $self->add_core_column();
		
	$table = 'core_region';
	my $ref_core_id = $self->nextoid($table);	                                 	
	$self->print_cr($ref_core_id,$curr_feature_id,$column);
	$self->nextoid($table,'++');
	$self->cache('core_region',$curr_feature_id, $column);
			
	
	return($curr_feature_id);
}

=cut

=head2 handle_snp

=over

=item Usage

  $obj->handle_snp()

=item Function

  Save snp

=item Returns

Nothing

=item Arguments



=back

=cut

sub handle_snp {
	my $self = shift;
	my ($ref_id, $c2, $ref_pos, $rgap_offset, $contig_collection, $contig, $locus, $c1, $is_public) = @_;
	
	croak "Positioning violation! $c2 character with gap offset value $rgap_offset for core sequence." if ($rgap_offset && $c2 ne '-') || (!$rgap_offset && $c2 eq '-');
	
	# Retrieve reference snp, if exists
	my ($ref_snp_id, $column) = $self->retrieve_core_snp($ref_id, $ref_pos, $rgap_offset);
	
	unless($ref_snp_id) {
		# Create new core snp
		
		# Update snp alignment strings with new column
		($column) = $self->add_snp_column($c2);
		
		my $table = 'snp_core';
		
		$ref_snp_id = $self->nextoid($table);	                                 	
		$self->print_sc($ref_snp_id,$ref_id,$c2,$ref_pos,$rgap_offset,$column);
		$self->nextoid($table,'++');
		$self->cache('core_snp',"$ref_id.$ref_pos.$rgap_offset",[$ref_snp_id, $column]);
		
	}
		
	# Update snp in alignment for genome
	$self->alter_snp($contig_collection,$is_public,$column,$c1);
	
	# Create snp entry
	my $table = $is_public ? 'snp_variation' : 'private_snp_variation';
	$self->print_sv($self->nextoid($table),$ref_snp_id,$contig_collection,$contig,$locus,$c1,$is_public);
	$self->nextoid($table,'++');
	
}

=cut

=head2 handle_snp_alignment_block

=over

=item Usage

  $obj->handle_snp_alignment_block()

=item Function

  Save pairwise alignment encodings

=item Returns

Nothing

=item Arguments



=back

=cut

sub handle_snp_alignment_block {
	my $self = shift;
	my ($contig_collection, $contig, $ref_id, $locus, $start1, $start2, $end1, $end2, $gap1, $gap2, $is_public) = @_;
	
	croak "Positioning violation in reference alignment! gap positions should have length 1 (sequence: $contig_collection, $contig, $ref_id, $locus)." if $gap1 && ($start1 != $end1);
	croak "Positioning violation in comparison alignment! gap positions should have length 1 (sequence: $contig_collection, $contig, $ref_id, $locus)." if $gap2 && ($start2 != $end2);
	croak "Positioning violation in snp alignment! received gap column (sequence: $contig_collection, $contig, $ref_id, $locus)." if $gap2 && $gap1;
	
	if($gap1) {
		# Reference gaps go into 'special' table
		
		my $snp_array = $self->cache('core_snp',"$ref_id.$start1.$gap1");
		croak "Error: SNP in reference pangenome region $ref_id (pos: $start1, gap-offset: $gap1) not found." unless defined $snp_array;
		my $core_snp_id = $snp_array->[0];
		
		my $table = $is_public ? 'gap_position' : 'private_gap_position';
		$self->print_gp($self->nextoid($table),$contig_collection, $contig, $ref_id, $locus, $core_snp_id, $start2, $is_public);
		$self->nextoid($table,'++');
		
	} else {
		# Create standard snp position entry: reference nuc aligned to gap or nuc in comparison strain
		
		my $table = $is_public ? 'snp_position' : 'private_snp_position';
		$self->print_sp($self->nextoid($table), $contig_collection, $contig, $ref_id, $locus, $start1, $start2, $end1, $end2, $gap2, $is_public);
		$self->nextoid($table,'++');
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
	                                 	
	$self->print_fcvterm($self->nextoid($table), $child_id, $ef_type, $self->publication_id, $rank,$pub);
	$self->nextoid($table,'++');
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

sub add_relationship {
    my $self = shift;
    my ($child_id, $parent_id, $reltype, $pub, $xpub) = @_;
    
  	my $rtype = $self->relationship_types($reltype);
  	croak "Unrecognized relationship type: $reltype." unless $rtype;
    my $rank = 0;
    
    # If this relationship is unique, add it.
    my $table;
    my $pub_type;
    if($pub) {
    	$table = 'feature_relationship';
    	$pub_type = 1;
    } else {
    	if($xpub) {
    		$table = 'pripub_feature_relationship';
    		$pub_type = 2;
    	} else {
    		$table = 'private_feature_relationship';
    		$pub_type = 0;
    	}
    }
    	                               	
	$self->print_frel($self->nextoid($table),$child_id,$parent_id,$rtype,$rank,$pub,$xpub);
	$self->nextoid($table,'++');
   
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
		print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$upl_id,$rank)),"\n";
	}
  
}

sub print_fcvterm {
	my $self = shift;
	my ($nextfeaturecvterm,$nextfeature,$type,$ref,$rank,$pub,$is_not) = @_;
	
	$is_not = 'FALSE' unless $is_not; # Default
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('feature_cvterm');		
	} else {
		$fh = $self->file_handles('private_feature_cvterm');
	}
	
	print $fh join("\t", ($nextfeaturecvterm,$nextfeature,$type,$ref,$is_not,$rank)),"\n";
}

sub print_frel {
	my $self = shift;
	my ($nextfeaturerel,$nextfeature,$parent,$part_of,$rank,$pub,$xpub) = @_;
	
	my $fh;
	if($pub) {
		
		$fh = $self->file_handles('feature_relationship');
			
	} else {
		if($xpub) {
			$fh = $self->file_handles('pripub_feature_relationship');
		} else {
			$fh = $self->file_handles('private_feature_relationship');
		}
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
	
	if(!$pub) {
		my $fh = $self->file_handles('private_feature');
		print $fh join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $upl_id, $residues)),"\n";		
	} else {
		my $fh = $self->file_handles('feature');
		print $fh join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $residues)),"\n";
	}
}

sub print_tree {
	my $self = shift;
	my ($tree,$name,$format,$string) = @_;
	
	my $fh = $self->file_handles('tree');		

	print $fh join("\t", ($tree,$name,$format,$string)),"\n";
}

sub print_ftree {
	my $self = shift;
	my ($nextft,$tree_id,$feature_id,$type,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('feature_tree');		
	} else {
		$fh = $self->file_handles('private_feature_tree');
	}	

	print $fh join("\t", ($nextft,$feature_id,$tree_id,$type)),"\n";
}

sub print_sc {
	my $self = shift;
	my ($sc_id,$ref_id,$nuc,$pos,$gap,$col) = @_;
	
	my $fh = $self->file_handles('snp_core');		

	print $fh join("\t", ($sc_id,$ref_id,$nuc,$pos,$gap,$col)),"\n";
}

sub print_cr {
	my $self = shift;
	my ($cr_id,$ref_id,$col) = @_;
	
	my $fh = $self->file_handles('core_region');		

	print $fh join("\t", ($cr_id,$ref_id,$col)),"\n";
}

sub print_sv {
	my $self = shift;
	my ($nextft,$snp_id,$genome_id,$contig_id,$locus,$nuc,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('snp_variation');		
	} else {
		$fh = $self->file_handles('private_snp_variation');
	}	

	print $fh join("\t", ($nextft,$snp_id,$genome_id,$contig_id,$locus,$nuc)),"\n";
}

sub print_sp {
	my $self = shift;
	my ($nextft,$genome_id,$contig_id,$ref,$locus,$s1,$s2,$e1,$e2,$g,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('snp_position');		
	} else {
		$fh = $self->file_handles('private_snp_position');
	}	

	print $fh join("\t", ($nextft,$genome_id,$contig_id,$ref,$locus,$s1,$s2,$e1,$e2,$g)),"\n";
}

sub print_gp {
	my $self = shift;
	my ($nextft,$genome_id,$contig_id,$ref,$locus,$snp,$s2,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('gap_position');		
	} else {
		$fh = $self->file_handles('private_gap_position');
	}	

	print $fh join("\t", ($nextft,$genome_id,$contig_id,$ref,$locus,$snp,$s2)),"\n";
}


# Print to tmp tables for update

sub print_uf {
	my $self = shift;
	my ($nextfeature,$uname,$type,$seqlen,$residues,$pub) = @_;
	
	my $org_id = 13; # just need to put in some value to fulfill non-null constraint
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('tfeature');		
	} else {
		$fh = $self->file_handles('tprivate_feature');
	}
	
	print $fh join("\t", ($nextfeature, $org_id, $uname, $type, $seqlen, $residues)),"\n";
	
}

sub print_ufprop {
	my $self = shift;
	my ($f_id,$cvterm_id,$value,$rank,$pub) = @_;
	
	$rank = 0 unless defined $rank;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('tfeatureprop');		
	} else {
		$fh = $self->file_handles('tprivate_featureprop');
	}

	print $fh join("\t",($f_id,$cvterm_id,$value,$rank,)),"\n";
	
}

sub print_ufloc {
	my $self = shift;
	my ($nextfeature,$min,$max,$str,$lg,$rank,$pub) = @_;
	
	my $fh;
	if($pub) {
		$fh = $self->file_handles('tfeatureloc');		
	} else {
		$fh = $self->file_handles('tprivate_featureloc');
	}
	
	print $fh join("\t", ($nextfeature,$min,$max,$str,$lg,$rank)),"\n";
}

sub print_utree {
	my $self = shift;
	my ($tree,$name,$string) = @_;
	
	my $fh = $self->file_handles('ttree');		

	print $fh join("\t", ($tree,$name,$string)),"\n";
}

sub print_usc {
	my $self = shift;
	my ($snp_core_id,$pangenome_region,$position,$gap_offset) = @_;
	
	my $fh = $self->file_handles('tsnp_core');		

	print $fh join("\t", ($snp_core_id,$pangenome_region,$position,$gap_offset)),"\n";
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

    my $dbh = shift if @_;
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

    my $tmp_dir = shift if @_;
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

    my $dbname = shift if @_;
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

    my $v = shift if @_;
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
    my $save_tmpfiles = shift if @_;
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
    my $recreate_cache = shift if @_;

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

=head2 organism_id

=over

=item Usage

  $obj->organism_id #get existing value for default organism type

=item Function

=item Returns

Default organism_id needed in the feature table

=back

=cut

sub organism_id {
    my $self = shift;
    
    return $self->{organisms}->{'Escherichia coli'};
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

sub elapsed_time {
	my ($self, $mes) = @_;
	
	my $time = $self->{now};
	my $now = time();
	printf("$mes: %.2f\n", $now - $time);
	
	$self->{now} = $now;
}

=head2 add_snp_column

=over

=item Usage

  $obj->add_snp_column($nuc); 

=item Function

  For new snp, add char in each genome's SNP alignment string and in the default 'core' string

=item Returns

  The block and column number of the new SNP alignment column

=item Arguments

  The nucleotide char in the core pangenome

=back

=cut

sub add_snp_column {
	my $self = shift;
	my $nuc = shift;
		
	my $c = $self->{snp_alignment}->{core_position}++;
	$self->{snp_alignment}->{core_alignment} .= $nuc;
	
	
	return($c);
}

=head2 add_snp_row

=over

=item Usage

  $obj->add_snp_row($genome_id, $is_public); 

=item Function

  For new genome, add the default 'core' SNP alignment string in table

=item Returns

  Nothing

=item Arguments

  The genome featureID and boolean indicating if genome is in public or private
  feature table.

=back
=cut

sub add_snp_row {
	my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	
	my $pre = $is_public ? 'public_' : 'private_';
	my $genome = $pre . $genome_id;
	
	if ($self->validate_snp_alignment($genome_id, $is_public) ) {
		
		# Record new genomes;
		push @{$self->{snp_alignment}{new_rows}}, $genome;
		$self->cache('snp_alignment', $genome, 1);
	}
}

=head2 add_core_column

=over

=item Usage

  $obj->add_core_column($nuc); 

=item Function

  For new core pangenome region, add column in each genome's alignment string and in the default 'core' string

=item Returns

  The column number of the new core alignment column

=item Arguments

  None

=back

=cut

sub add_core_column {
	my $self = shift;
		
	my $c = $self->{core_alignment}->{core_position}++;
	$self->{core_alignment}->{added_columns}++;
	
	return($c);
}

=head2 add_snp_row

=over

=item Usage

  $obj->add_core_row($genome_id, $is_public); 

=item Function

  For new genome, add the default 'core' alignment string in table

=item Returns

  Nothing

=item Arguments

  The genome featureID and boolean indicating if genome is in public or private
  feature table.

=back
=cut

sub add_core_row {
	my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	
	my $pre = $is_public ? 'public_' : 'private_';
	my $genome = $pre . $genome_id;
	
	if ($self->validate_core_alignment($genome_id, $is_public) ) {
		
		# Record new genomes;
		push @{$self->{core_alignment}{new_rows}}, $genome;
		$self->cache('core_alignment', $genome, 1);
	}
}


=head2 alter_snp

=over

=item Usage

  $obj->alter_snp($genome_id, $is_public, $block, $pos, $nuc); 

=item Function

  Change the SNP alignment string at a single position for a genome

=item Returns

  Nothing

=item Arguments

  The genome featureID, boolean indicating if genome is in public or private
  feature table, the position in the alignment and the
  character to assign at that position

=back

=cut

sub alter_snp {
	my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	my $pos = shift;
	my $nuc = shift;
	
	# Validate alignment positions
	my $maxc = $self->{snp_alignment}->{core_position};
	croak "Invalid SNP alignment position $pos (max: $maxc)." unless $pos <= $maxc;
	
	# Validate nucleotide
	$nuc = uc($nuc);
	croak "Invalid nucleotide character '$nuc'." unless $nuc =~ m/^[A-Z\-]$/;
	
	my $pre = $is_public ? 'public_' : 'private_';
	my $genome = $pre . $genome_id;
	
	push @{$self->{snp_alignment}{buffer_stack}}, $genome, $pos, $nuc;
	$self->{snp_alignment}{buffer_num}++;

	if($self->{snp_alignment}{buffer_num} == $self->{snp_alignment}{bulk_set_size}) {
		
		$self->{snp_alignment}{insert_tmp_variations}->execute(@{$self->{snp_alignment}{buffer_stack}});
		$self->dbh->commit;
		$self->{snp_alignment}{buffer_num} = 0;
		$self->{snp_alignment}{buffer_stack} = [];
	}
}

=head2 has_core_region

=over

=item Usage

  $obj->has_core_region($genome_id, $is_public, $column); 

=item Function

  Change the core alignment string at a single position for a genome

=item Returns

  Nothing

=item Arguments

  The genome featureID, boolean indicating if genome is in public or private
  feature table, the alignment column number

=back

=cut

sub has_core_region {
	my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	my $col = shift;
	
	# Validate alignment positions
	my $maxc = $self->{core_alignment}->{core_position};
	croak "Invalid core alignment position $col (max: $maxc)." unless $col <= $maxc;
	
	my $pre = $is_public ? 'public_' : 'private_';
	my $genome = $pre . $genome_id;
	
	push @{$self->{core_alignment}{buffer_stack}}, $genome, $col;
	$self->{core_alignment}{buffer_num}++;

	if($self->{core_alignment}{buffer_num} == $self->{core_alignment}{bulk_set_size}) {
		
		$self->{core_alignment}{insert_tmp_presence}->execute(@{$self->{core_alignment}{buffer_stack}});
		$self->dbh->commit;
		$self->{core_alignment}{buffer_num} = 0;
		$self->{core_alignment}{buffer_stack} = [];
	}
}

=head2 push_snp_alignment

=over

=item Usage

  $obj->push_snp_alignment(); 

=item Function

  Add the current tmp_snp_cache to the snp_alignment table

=item Returns

  Nothing

=item Arguments

  None

=back

=cut

sub push_snp_alignment {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	# Insert the remaining rows in the buffer
	my $num_rows = scalar(@{$self->{snp_alignment}{buffer_stack}});
	if($num_rows) {
		$num_rows = $num_rows/3;
		my $insert_query = 'INSERT INTO tmp_snp_cache (name,aln_column,nuc) VALUES (?,?,?)';
	    $insert_query .= ', (?,?,?)' x ($num_rows-1);
	    my $insert_sth = $dbh->prepare($insert_query);
	    $insert_sth->execute(@{$self->{snp_alignment}{buffer_stack}});
	}
	my $sql = "CREATE INDEX tmp_snp_cache_idx1 ON public.tmp_snp_cache (name)";
    $dbh->do($sql);
    $dbh->commit;
	
	# New additions to core
	my $new_core_aln = $self->{snp_alignment}->{core_alignment};
	my $curr_column = $self->{snp_alignment}->{core_position};

	# Retrieve the full core snp alignment string (not just the new snps appended in this run)
	$sql = "SELECT alignment FROM snp_alignment WHERE name = 'core'";
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my ($old_core_aln) = $sth->fetchrow_array();
	$old_core_aln = '' unless defined $old_core_aln;
	my $full_core_aln = $old_core_aln . $new_core_aln;
	croak "Alignment length does not match position counter $curr_column (length:".length($full_core_aln).")" unless length($full_core_aln) == $curr_column;
	
	# Genomes
	my $genomes = $self->_genomeList;
	
	# Core pangenome regions
	my $pgregions = $self->_coreRegionList;	
	
	# SNPs
	my ($db_snps, $new_snps) = $self->_snpsList;
	
	# Pangenome map: genome -> core regions
	my $pgmap = $self->_coreRegionMap($pgregions);
	
	# Prepare loading file for COPY FROM operation
	my $file_path = $self->{tmp_dir};
	my ($tmpfh,$tmpfile) = new File::Temp(
		TEMPLATE => "chado-snp-alignment-XXXX",
		SUFFIX   => '.dat',
		UNLINK   => $self->save_tmpfiles() ? 0 : 1, 
		DIR      => $file_path,
	);
	chmod 0644, $tmpfh;
	
	# Print core alignment additions to loading file
	print $tmpfh join("\t", ('core',$curr_column,$new_core_aln)),"\n";
	
	# Iterate through new genomes
	my @new_genomes = @{$self->{snp_alignment}{new_rows}};
	
	my $retrieve_sth = $dbh->prepare('SELECT aln_column,nuc FROM tmp_snp_cache WHERE name = ?');
	print 'NG:'.join(',',@new_genomes),"\n";
	foreach my $g (@new_genomes) {
		
		$genomes->{$g} = 0;
		
		# Make genome snp changes to core string
		$retrieve_sth->execute($g);
		my $genome_string = $full_core_aln;

		while (my $bunch_of_rows = $retrieve_sth->fetchall_arrayref(undef, 5000)) {
			snp_edits($genome_string, $bunch_of_rows);
		}
		
		# Remove snps for regions not in genome
		#print 'BEFORE: '.$genome_string."\n";
		my $missing_regions = &_absentCoreRegions($g, $pgregions, $pgmap->{$g});
		$genome_string = $self->mask_missing_in_new($genome_string, $missing_regions, $db_snps, $new_snps);
		#print 'AFTER: '.$genome_string."\n";
		
		# Print to DB file
		print $tmpfh join("\t", ($g,$curr_column,$genome_string)),"\n";
	}
	
	# Iterate through old genomes (no SNP-finding performed on these genomes)
	# Add core snps to their strings
	my $offset = $curr_column - length($new_core_aln);
	foreach my $g (keys %$genomes) {
		
		next unless $genomes->{$g};
		
		# Change snps for regions not in genome to gaps
		my $missing_regions = &_absentCoreRegions($g, $pgregions, $pgmap->{$g});
		my $editted_aln = $self->mask_missing_in_db($new_core_aln, $missing_regions, $new_snps, $offset);
		
		print $tmpfh join("\t", ($g,$curr_column,$editted_aln)),"\n";
	}
	
	# Run upsert operation
	warn "Upserting data in snp_alignment table ...\n";
	seek($tmpfh,0,0);
	
	my $ttable = 'snp_alignment';
	my $stable = 'tmp_snp_alignment';
	my $query0 = "DROP TABLE IF EXISTS $stable";
	my $query1 = "CREATE TABLE $stable (LIKE $ttable INCLUDING ALL)";
	$dbh->do($query0) or croak("Error when executing: $query0 ($!).\n");
	$dbh->do($query1) or croak("Error when executing: $query1 ($!).\n");
	
	my $query2 = "COPY $stable (name,aln_column,alignment) FROM STDIN;";
	print STDERR $query2,"\n";
	$dbh->do($query2) or croak("Error when executing: $query2 ($!).\n");

	while (<$tmpfh>) {
		if ( ! ($dbh->pg_putline($_)) ) {
			# error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $tmpfile, line $.");
		} # putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $stable failed: $!");
	
	# update the target table
	my $query3 = 
"WITH upsert AS
(UPDATE $ttable t SET alignment = overlay(t.alignment placing s.alignment from t.aln_column+1), 
 aln_column = s.aln_column 
 FROM $stable s WHERE t.name = s.name
 RETURNING t.name
)
INSERT INTO $ttable (name,aln_column,alignment)
SELECT name,aln_column,alignment
FROM $stable tmp
WHERE NOT EXISTS (SELECT 1 FROM upsert up WHERE up.name = tmp.name);";

	$dbh->do("$query3") or croak("Error when executing: $query3 ($!).\n");
	
	# Check for duplicate SNP alignment strings
	# A red-flag for duplicate genomes in DB
	my $query4 = 
"SELECT * FROM (
  SELECT name,
  ROW_NUMBER() OVER(PARTITION BY alignment ORDER BY name ASC) AS Row
  FROM $ttable
) dups
WHERE 
dups.Row > 1";

	my $sth5 = $dbh->prepare($query4);
	$sth5->execute();
	
	while(my ($name) = $sth5->fetchrow_array()) {
		carp('WARNING: Identical SNP strings found for genome: '.$name.'. Might indicate duplicate genomes in DB.');
	}
}

=head2 push_core_alignment

=over

=item Usage

  $obj->push_core_alignment(); 

=item Function

  Add the current tmp_core_cache to the core_alignment table

=item Returns

  Nothing

=item Arguments

  None

=back

=cut

sub push_core_alignment {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	# Insert the remaining rows in the buffer
	my $num_rows = scalar(@{$self->{core_alignment}{buffer_stack}});
	if($num_rows) {
		$num_rows = $num_rows/2;
		my $insert_query = 'INSERT INTO tmp_core_pangenome_cache (genome,aln_column) VALUES (?,?)';
	    $insert_query .= ', (?,?)' x ($num_rows-1);
	    my $insert_sth = $dbh->prepare($insert_query);
	    $insert_sth->execute(@{$self->{core_alignment}{buffer_stack}});
	}
	my $sql = "CREATE INDEX tmp_core_pangenome_cache_idx1 ON public.tmp_core_pangenome_cache (genome)";
    $dbh->do($sql);
    $dbh->commit;
	
	# New additions to core string
	my $new_cols = $self->{core_alignment}->{added_columns};
	my $new_core_aln = '0' x $new_cols;
	my $curr_column = $self->{core_alignment}->{core_position};

	# Retrieve the full core alignment string (not just the new columns appended in this run)
	$sql = "SELECT alignment FROM core_alignment WHERE name = 'core'";
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my ($old_core_aln) = $sth->fetchrow_array();
	$old_core_aln = '' unless defined $old_core_aln;
	my $full_core_aln = $old_core_aln . $new_core_aln;
	croak "Alignment length does not match position counter $curr_column (length:".length($full_core_aln).")" unless length($full_core_aln) == $curr_column;
	
	# Genomes
	my $genomes = $self->_genomeList;
	
	# Prepare loading file for COPY FROM operation
	my $file_path = $self->{tmp_dir};
	my ($tmpfh,$tmpfile) = new File::Temp(
		TEMPLATE => "chado-core-alignment-XXXX",
		SUFFIX   => '.dat',
		UNLINK   => $self->save_tmpfiles() ? 0 : 1, 
		DIR      => $file_path,
	);
	chmod 0644, $tmpfh;
	
	# Print core alignment additions to loading file
	print $tmpfh join("\t", ('core',$curr_column,$new_core_aln)),"\n";
	
	# Iterate through new genomes
	my @new_genomes = @{$self->{core_alignment}{new_rows}};
	
	my $retrieve_sth = $dbh->prepare("SELECT aln_column, '1' FROM tmp_core_pangenome_cache WHERE genome = ?");
	print 'NG:'.join(',',@new_genomes),"\n";
	foreach my $g (@new_genomes) {
		
		$genomes->{$g} = 0;
		
		# Insert presence indicators into core string for genome
		$retrieve_sth->execute($g);
		my $genome_string = $full_core_aln;
		
		while (my $bunch_of_rows = $retrieve_sth->fetchall_arrayref(undef, 5000)) {
			snp_edits($genome_string, $bunch_of_rows);
		}
		
		# Print to DB file
		print $tmpfh join("\t", ($g,$curr_column,$genome_string)),"\n";
	}
	
	# Iterate through old genomes
	# Add core columns to their strings
	foreach my $g (keys %$genomes) {
		
		next unless $genomes->{$g};
		
		print $tmpfh join("\t", ($g,$curr_column,$new_core_aln)),"\n";
	}
	
	# Run upsert operation
	warn "Upserting data in core_alignment table ...\n";
	seek($tmpfh,0,0);
	
	my $ttable = 'core_alignment';
	my $stable = 'tmp_core_alignment';
	my $query0 = "DROP TABLE IF EXISTS $stable";
	my $query1 = "CREATE TABLE $stable (LIKE $ttable INCLUDING ALL)";
	$dbh->do($query0) or croak("Error when executing: $query0 ($!).\n");
	$dbh->do($query1) or croak("Error when executing: $query1 ($!).\n");
	
	my $query2 = "COPY $stable (name,aln_column,alignment) FROM STDIN;";
	print STDERR $query2,"\n";
	$dbh->do($query2) or croak("Error when executing: $query2 ($!).\n");

	while (<$tmpfh>) {
		if ( ! ($dbh->pg_putline($_)) ) {
			# error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $tmpfile, line $.");
		} # putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $stable failed: $!");
	
	# update the target table
	my $query3 = 
"WITH upsert AS
(UPDATE $ttable t SET alignment = overlay(t.alignment placing s.alignment from t.aln_column+1), 
 aln_column = s.aln_column 
 FROM $stable s WHERE t.name = s.name
 RETURNING t.name
)
INSERT INTO $ttable (name,aln_column,alignment)
SELECT name,aln_column,alignment
FROM $stable tmp
WHERE NOT EXISTS (SELECT 1 FROM upsert up WHERE up.name = tmp.name);";

	$dbh->do("$query3") or croak("Error when executing: $query3 ($!).\n");
}

# List of all genomes
sub _genomeList {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	my %genomes;
	my $cc_id = $self->feature_types('contig_collection');
	my $sql1 = "SELECT feature_id FROM feature WHERE type_id = ?";
	my $sql2 = "SELECT feature_id FROM private_feature WHERE type_id = ?";
	
	# Public
	my $sth1 = $dbh->prepare($sql1);
	$sth1->execute($cc_id);
	
	while(my ($id) = $sth1->fetchrow_array()) {
		$genomes{"public_$id"} = [$id, 1];
	}
	
	# Private
	my $sth2 = $dbh->prepare($sql2);
	$sth2->execute($cc_id);
	
	while(my ($id) = $sth2->fetchrow_array()) {
		$genomes{"private_$id"} = [$id, 0];
	}
	
	return \%genomes;
}

# List of core pangenome regions
sub _coreRegionList {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	# Core pangenome regions in DB
	my %pgregions;
	my $pg_id = $self->feature_types('pangenome');
	my $core_type = $self->feature_types('core_genome');
	my $sql3 = "SELECT f.feature_id FROM feature f, feature_cvterm c".
		" WHERE f.feature_id = c.feature_id and f.type_id = $pg_id and c.cvterm_id = $core_type and c.is_not = FALSE";
	
	my $sth3 = $dbh->prepare($sql3);
	$sth3->execute();
	
	while(my ($id) = $sth3->fetchrow_array()) {
		$pgregions{$id}=1;
	}
	
	# New core pangenome regions in this run
	# Assumes that 'core' cache has been populated with new core pangenome regions added during this run
	my $core_cache = $self->cache('core');
	
	if(defined $core_cache) {
		foreach my $pg_id (keys %{$core_cache}) {
			$pgregions{$pg_id} = 1 if $core_cache->{$pg_id};
		}
	}
	
	return \%pgregions;
}

# List of snps
sub _snpsList {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	# Build list of new and existing SNPs
	# DB Snps
	my %db_snps;
	my $sql4 = "SELECT snp_core_id, aln_column, pangenome_region_id FROM snp_core";
	my $sth4 = $dbh->prepare($sql4);
	$sth4->execute();
	
	while(my $row = $sth4->fetchrow_arrayref) {
		$db_snps{$row->[2]} = [] unless defined $db_snps{$row->[2]};
		push @{$db_snps{$row->[2]}}, [$row->[0], $row->[1]];
	}
	
	# New Snps
	# Assumes $self->{cache}{'core_snp'} is populated with new snps
	my %new_snps;
	if(defined $self->cache('core_snp')) {
		foreach my $uniquename (keys %{$self->cache('core_snp')}) {
			my ($pg_id, $pos, $gap) = split(/\./, $uniquename);
			my $snp_data = $self->{cache}{'core_snp'}->{$uniquename};
			$new_snps{$pg_id} = [] unless defined $new_snps{$pg_id};
			push @{$new_snps{$pg_id}}, $snp_data;
		}
	}
	
	return (\%db_snps, \%new_snps);
}

# Map genomes to array of core regions
sub _coreRegionMap {
	my $self = shift;
	my $pgregions = shift;
	
	my $dbh = $self->dbh;
	
	my %genome_regions;
	# Add new genome -> core region mappings
	foreach my $data_hash (values %{$self->{loci_cache}{new_loci}}) {
		my $genome_id = $data_hash->{genome_id};
		my $query_id = $data_hash->{query_id};
		if($pgregions->{$query_id}) {
			# Core region, add it to list
			$genome_regions{$genome_id}{$query_id} = 1;
		}
	}
	
	# Add genome -> core region mappings already in DB
	my $sql = 'SELECT genome_id, pub, query_id FROM tmp_loci_cache WHERE query_id IN ('.join(',', keys %{$pgregions}).')';
	my $sth = $dbh->prepare($sql);
	$sth->execute();
		
	while(my $row = $sth->fetchrow_arrayref) {
		my ($genome, $pub, $query_id) = @$row;
		my $genome_id = $pub ? "public_$genome" : "private_$genome";
		$genome_regions{$genome_id}{$query_id} = 1;
	}
	
	return \%genome_regions;
}

=head2 mask_missing_in_db

=over

=item Usage

  $obj->mask_missing_in_db(); 

=item Function

  In snp alignment, overwrite sections of alignment with '-' coresponding to pangenome regions not found in genome
  
  This function handles existing genomes already in DB

=item Returns

  Updated alignment string

=item Arguments

  1. new alignment segment string being appended to existing alignments
  2. hashref containing core pangenome regions absent in genome
  3. hashref containing all new SNPs added in this run. 
     Each hash value contains 2 element array: [snp_id, snp_alignment_column]
  4. Alignment column assigned to start of new alignment segment

=back

=cut

sub mask_missing_in_db {
	my $self = shift;
	my $alignment = shift;
	my $missing_regions = shift;
	my $new_snps = shift;
	my $position_offset = shift;
	
	my $dbh = $self->dbh;
	
	# Genome already in DB, 
	# Alignment is new portion concatenated onto end of existing alignment
	
	# Find any new snps in the missing regions
	# Replace those snp alignment positions with '-'
	my @edits;
	foreach my $pg_id (%$new_snps) {
		if($missing_regions->{$pg_id}) {
			foreach my $snp (@{$new_snps->{$pg_id}}) {
				my $pos = $snp->[1] - $position_offset;
				push @edits, [$pos, '-'];
			}
		}
	}
		
	snp_edits($alignment, \@edits) if @edits;
	
	return $alignment;
}

=head2 mask_missing_in_new

=over

=item Usage

  $obj->mask_missing_in_new(); 

=item Function

  In snp alignment, overwrite sections of alignment with '-' coresponding to pangenome regions not found in genome
  
  This function handles new genomes inserted in this run

=item Returns

  Updated alignment string

=item Arguments

  1. Full alignment string for new genomes added in this run
  2. hashref containing core pangenome regions absent in genome
  3. hashref containing all SNPs in DB 
     Each hash value contains 2 element array: [snp_id, snp_alignment_column]
  4. hashref containing all new SNPs added in this run. 
     Each hash value contains 2 element array: [snp_id, snp_alignment_column]

=back

=cut

sub mask_missing_in_new {
	my $self = shift;
	my $alignment = shift;
	my $missing_regions = shift;
	my $db_snps = shift;
	my $new_snps = shift;
	
	
	# Find any snps in the missing regions
	# Replace those snp alignment positions with '-'
	my @edits;
	foreach my $pg_id (%$new_snps) {
		if($missing_regions->{$pg_id}) {
			foreach my $snp (@{$new_snps->{$pg_id}}) {
				my $pos = $snp->[1];
				push @edits, [$pos, '-'];
			}
		}
	}
	
	foreach my $pg_id (%$db_snps) {
		if($missing_regions->{$pg_id}) {
			foreach my $snp (@{$new_snps->{$pg_id}}) {
				my $pos = $snp->[1];
				push @edits, [$pos, '-'];
			}
		}
	}
	
	snp_edits($alignment, \@edits) if @edits;
		
	return $alignment;
}

# Compute set of core regions not found in genome
sub _absentCoreRegions {
	my $genome = shift;
	my $core_list = shift;
	my $genome_regions = shift;
	
	my %missing_regions;
	unless(defined $genome_regions) {
		warn "WARNING: genome $genome has no associated pangenome regions. All snps will be marked as missing (e.g. '-').\n";
		return \%missing_regions; 
	}
		
	# Build 'missing' list - pangenome regions not present in genome
	foreach my $region (keys %$core_list) {
		$missing_regions{$region} = 1 unless $genome_regions->{$region};
	}
	
	return \%missing_regions;
}


=head2 push_cache

=over

=item Usage

  $obj->push_cache(); 

=item Function

  Add the current tmp_snp_cache to the snp_alignment table

=item Returns

  Nothing

=item Arguments

  None

=back

=cut

sub push_cache {
	my $self = shift;
	
	my $dbh = $self->dbh;
	my $fh = $self->{loci_cache}{fh};
	my $file = $fh->filename;
	$fh->autoflush;
	
	if (-s $file <= 0) {
		warn "Skipping cache table since the load file is empty...\n";
		return;
	}
		
	warn "Loading data into cache table ...\n";
	seek($fh,0,0);

	my $table = $self->{loci_cache}{table};
	my $fields = "(feature_id,uniquename,genome_id,query_id,pub)";
	my $query = "COPY $table $fields FROM STDIN;";

	$dbh->do($query) or croak("Error when executing: $query: $!");

	while (<$fh>) {
		if ( ! ($dbh->pg_putline($_)) ) {
			# error, disconecting
			$dbh->pg_endcopy;
			$dbh->rollback;
			$dbh->disconnect;
			croak("error while copying data's of file $file, line $.");
		} # putline returns 1 if succesful
	}

	$dbh->pg_endcopy or croak("calling endcopy for $table failed: $!");
}

=head2 snp_audit

Scan the reference pangenome sequence alignment for regions of ambiguity (consequetive gaps where at least one gap is new).
Can't tell which gap is new and which is old.

=cut

sub snp_audit {
	my $self = shift;
	my $refid = shift;
	my $refseq = shift;
	
	# Search sequence for extended indels
	my @regions;
	my $l = length($refseq)-1;
	my $pos = 0;
	my $gap = 0;
		
	for my $i (0 .. $l) {
        my $c = substr($refseq, $i, 1);
        
        # Advance position counters
        if($c eq '-') {
        	$gap++;
        } else {
        	if($gap > 1) {
        		# extended indel
        		my @old_snps;
        		
        		# find if any columns are new
        		my $n = 0;
        		for(my $j=1; $j <= $gap; $j++) {
        			my ($snp_id, $col) = $self->retrieve_core_snp($refid, $pos, $j);
        			
					unless($snp_id) {
						# new insert
						$n++;
					} else {
						croak "Error: SNP entry in DB for $refid, $pos, $j, $snp_id missing alignment column." unless $col;
						push @old_snps, [$snp_id, $col];
					}
        		}
        		
        		if($n && $n != $gap) {
        			# Have some new columns mixed with some old, region of ambiguity
        			my %indel_hash;
        			$indel_hash{p} = $pos;
					$indel_hash{g} = $gap;
					$indel_hash{insert_ids} = \@old_snps;
					$indel_hash{aln_start} = $i-$gap;
					$indel_hash{n} = $n;
					push @regions, \%indel_hash;
        		}
        		
        	}
        	$pos++;
        	$gap=0 if $gap;
        }
	}
	
	return \@regions;
}


=head2 handle_insert_blocks

Handle regions of ambiguity (new gap inserted into existing gap), identifying
old and new alignment columns. Update positioning as needed.

=cut

sub handle_insert_blocks {
	my $self = shift;
	my $regions = shift;
	my $ref_id = shift;
	my $refseq = shift;
	my $loci_hash = shift;
	
	my $v = 0;
	
	# Find new snps, update old snps in reach region of ambiguity
	foreach my $region (@$regions) {
	
		my $pos = $region->{p};
		my $gap = $region->{g};
		my $aln = $region->{aln_start};
		my $n   = $region->{n};
		my @current_insert_ids = @{$region->{insert_ids}};
		
		# Compare each insert position with known column characters to distinguish old and new
        
        # Obtain identifying characters for the first old insert column in alignment
        my $insert_column = $self->snp_variations_in_column($current_insert_ids[0][0]);
		
		if($v) {
			print "REF FRAGMENT: $ref_id\n$refseq\n";
			print "REGION: p: $pos, g: $gap, a: $aln, n: $n\n";
			print "CURRENT SNPS IN REGION: ",Dumper(@current_insert_ids),"\n";
			print "ALIGNMENT COLUMNS IN REGION: ",Dumper($insert_column),"\n";
		}
	
		for(my $i=1; $i <= $gap; $i++) {
			
			# Compare alignment chars to chars in DB for a single alignment column
			# genome_label: private_genome_id|loci_id
			my $col_match = 1;
			foreach my $genome_label (keys %$insert_column) {
				my $c1 = $insert_column->{$genome_label};
				my $c2 = substr($loci_hash->{$genome_label}, $aln+$i-1,1);
				
				print "Genome $genome_label -- SNP char: $c1, alignment char: $c2 for column: $i, $aln, ",$aln+$i-1,"\n" if $v;
				
				if($c1 ne $c2) {
					croak "Error: Unable to position new and old insertion columns in SNP alignment (encountered non-gap character in genome row that is currently in DB)." unless $c2 eq '-';
					
					# Found new snp column
					
					# Create new entry in snp_core table and add gap column to SNP alignment
					my ($column) = $self->add_snp_column('-');
					
					my $table = 'snp_core';
					my $ref_snp_id = $self->nextoid($table);	                                 	
					$self->print_sc($ref_snp_id,$ref_id,$c2,$pos,$i,$column);
					$self->nextoid($table,'++');
					$self->cache('core_snp',"$ref_id.$pos.$i",[$ref_snp_id, $column]);
					
					$col_match = 0;
					$n--;
					last;
				}
			}
			
        	if($col_match) {
        		# This gap position matches the current insert column
        		
        		# Update the position of the insert column
        		croak "Error: The snps in the DB and the current alignment are out of sync." unless @current_insert_ids;
        		my ($snp_core_id, $column) = @{$current_insert_ids[0]};
        		$self->print_usc($snp_core_id,$ref_id,$pos,$i);
				
				$self->cache('core_snp',"$ref_id.$pos.$i",[$snp_core_id, $column]);
				
        		shift @current_insert_ids;
        		$insert_column = $self->snp_variations_in_column($current_insert_ids[0][0]) if @current_insert_ids;
        		
        		print "MATCHED $snp_core_id, $column to $pos, $i in ALIGNMENT.\n" if $v;
        		
        	} else {
        		print "NEW GAP COLUMN IN ALIGNMENT at $pos, $i.\n" if $v;
        	}
        	
        }
        
        # Reached the end of the region
        # All new and old insert columns should be accounted for
        croak "Error: an insert column $current_insert_ids[0] in database was not located in the region of ambiguity in the alignment." if(@current_insert_ids);
        croak "Error: A new insert column was not located in the region of ambiguity in the alignment." if $n;
		
	}
	
}

=head2 snp_variations_in_column

Handle regions of ambiguity (new gap inserted into existing gap), identifying
old and new alignment columns. Update positioning as needed.

=cut

sub snp_variations_in_column {
	my $self = shift;
	my $snp_id = shift;
	
	my %variations;
	
	$self->{'queries'}{'retrieve_public_snp_column'}->execute($snp_id);
	
	while( my ($cc, $l, $a) = $self->{'queries'}{'retrieve_public_snp_column'}->fetchrow_array ) {
		my $lab = "public_$cc|$l";
		$variations{$lab} = $a;
	}
	
	$self->{'queries'}{'retrieve_private_snp_column'}->execute($snp_id);
	
	while( my ($cc, $l, $a) = $self->{'queries'}{'retrieve_private_snp_column'}->fetchrow_array ) {
		my $lab = "private_$cc|$l";
		$variations{$lab} = $a;
	}
	
	return(\%variations);
}

=head2 print_alignment_lengths

=cut

sub print_alignment_lengths {
	my $self = shift;
	
	my $sql = q/select length(alignment),block,name from tmp_snp_cache order by block,name/;
	
	$self->{'queries'}{'print_alignment_lengths'} = $self->dbh->prepare($sql) unless $self->{'queries'}{'print_alignment_lengths'};
	
	$self->{'queries'}{'print_alignment_lengths'}->execute();
	
	print "LENGTHS:\n---------\n";
	while (my ($len,$b,$n) = $self->{'queries'}{'print_alignment_lengths'}->fetchrow_array) {
		print "$n - $b: $len\n";
	}
	print "\n";
}

=head2 record_typing_sequences

Checks if query gene is needed to generate a in silico
subtype classification. If yes, the sequence_group hash
is cached. The hash, used elsewhere, includes key/values:

  genome => contig_collection feature ID
  public => T/F indicating if private/public feature
  allele => the allele feature ID
  seq    => the allele sequence
  is_new => T/F indicating if new sequence

=cut

sub record_typing_sequences {
	my $self = shift;
	my $query_id = shift;
	my $sequence_group = shift;
	
	return 0 unless defined $self->{loci_cache}{typing_watchlist}{$query_id};
	
	my $genome_id = $sequence_group->{genome};
	my $public = $sequence_group->{public};
	my $genome = $public ? 'public_' : 'private_';
	$genome .= $genome_id;
	
	$self->{loci_cache}{typing_watchlist}{$query_id}{$genome} = [] unless defined
		$self->{loci_cache}{typing_watchlist}{$query_id}{$genome};
	
	push @{$self->{loci_cache}{typing_watchlist}{$query_id}{$genome}}, $sequence_group;
	
	print "Recording $genome set for $query_id\n";
}

=head2 is_typing_sequence

Checks if query gene is needed to generate a in silico
subtype classification.

=cut

sub is_typing_sequence {
	my $self = shift;
	my $query_id = shift;
	
	return defined $self->{loci_cache}{typing_watchlist}{$query_id};
}

=head2 typing

Perform typing and load data and results into DB

=cut

sub typing {
	my $self = shift;
	my $work_dir = shift;
	
	# Prepare aligned concatenated sequences for each typing segment
	my $typing_sets = $self->construct_typing_sequences();
	print "Construction complete\n";
	
	# Typing and Tree objects
	my $typer = Phylogeny::Typer->new(tmp_dir => $work_dir);
	my $tree_builder = Phylogeny::TreeBuilder->new();
	my $tree_io = Phylogeny::Tree->new(dbix_schema => 1);
	
	# Run insilico typing on each typing segment
	foreach my $typing_ref_seq (keys %$typing_sets) {
		
		print "Number of typable subunits for $typing_ref_seq: ". scalar(@{$typing_sets->{$typing_ref_seq}}),"\n";
		
		my %waiting_subtype;
		my %fasta;
		my @sequence_group;
		foreach my $typing_hashref (@{$typing_sets->{$typing_ref_seq}}) {
			# Prepare fasta inputs
			# Only include allele_fusions not currently in the DB
			
			my $is_new = 0;
			
			my $genome_id = $typing_hashref->{genome};
			my $public = $typing_hashref->{public};
			my $uniquename = $typing_hashref->{uniquename};
			
			# Check if typing_seq is in cache
			# Check if this allele is already in DB
			my ($result, $alleleset_id) = $self->validate_feature($typing_ref_seq,$genome_id,$uniquename,$public);
			
			if($result eq 'new_conflict') {
				warn "Attempt to add allele_fusion feature multiple times. Dropping duplicate of allele_fusion $uniquename.";
				next;
			}
			if($result eq 'db_conflict') {
				warn "Attempt to update existing allele_fusion multiple times. Skipping duplicate allele_fusion $uniquename.";
				next;
			}
			
			unless($alleleset_id) {
				# A typing feature matching this one has not been loaded before
				# Add to list of type-ready sequences
				my $header = $typing_hashref->{header};
				$waiting_subtype{$header} = $typing_hashref;
				$fasta{$header} = $typing_hashref->{seq};
				$is_new = 1;
			}
			
			$typing_hashref->{allele} = $alleleset_id;
			$typing_hashref->{is_new} = $is_new;
			
			push @sequence_group, $typing_hashref;
			
		}
		
		# Run typing
		my $typing_unit_name = $self->{loci_cache}{typing_names}{$typing_ref_seq};
		my $typing_results_file = "$work_dir/$typing_unit_name\_subtypes.txt";
		my $typing_tree_file = "$work_dir/$typing_unit_name\_subtypes.phy";
		my $subtype_prop = $self->{loci_cache}{typing_featureprops}{$typing_unit_name};
		
		$typer->subtype($typing_unit_name, \%fasta, $typing_tree_file, $typing_results_file);
		
		# Load subtype assignments
		open(my $in, "<", $typing_results_file) or croak "Error: unable to read file $typing_results_file ($!).\n";
		
		while(my $row = <$in>) {
			chomp $row;
			my ($header, $assignment) = split("\t", $row);
			
			$self->handle_typing_sequence($subtype_prop, $typing_ref_seq, $assignment, $waiting_subtype{$header});
		}
		
		close $in;
		
		# Build tree
		
		# write alignment file
		my $tmp_file = $work_dir . '/genodo_allele_aln.txt';
		open(my $out, ">", $tmp_file) or croak "Error: unable to write to file $tmp_file ($!).\n";
		foreach my $allele_hash (@sequence_group) {
			my $header = $allele_hash->{public} ? 'public_':'private_';

			$header .= $allele_hash->{genome} . '|' . $allele_hash->{allele};
			print $out join("\n",">".$header,$allele_hash->{seq}),"\n";
		}
		close $out;
		
		# clear output file for safety
		my $tree_file = $work_dir . '/genodo_allele_tree.txt';
		open($out, ">", $tree_file) or croak "Error: unable to write to file $tree_file ($!).\n";
		close $out;
		
		# build newick tree
		$tree_builder->build_tree($tmp_file, $tree_file) or croak;
		
		# slurp tree and convert to perl format
		my $tree = $tree_io->newickToPerlString($tree_file);
		
		# store tree in tables
		$self->handle_phylogeny($tree, $typing_ref_seq, \@sequence_group);
		
	}
}

=head2 construct_typing_sequences

Produces a typing sequence by concatenating the individual aligned 
allele sequences that make up a typing sequence

=cut

sub construct_typing_sequences {
	my $self = shift;
	
	my %typing_sets;
	
	foreach my $typing_ref_gene (keys %{$self->{loci_cache}{typing_construct}}) {
		print "Construction step for SUBUNIT: $typing_ref_gene\n";
		
		$typing_sets{$typing_ref_gene} = [];
		my @ordered_keys = sort keys %{$self->{loci_cache}{typing_construct}{$typing_ref_gene}};
		my @ordered_seqs;
		
		# Record the order of the query genes in this typing sequence
		foreach my $i (@ordered_keys) {
			my $query_id = $self->{loci_cache}{typing_construct}{$typing_ref_gene}{$i};
			
			push @ordered_seqs, $query_id;
		}
		
		print "Alleles in subunit: ".join(', ',@ordered_seqs),"\n";
		
		# Iterate through each genome, concatenting the sequences
		# Skip genomes that do not have all needed sequences
		my $query_gene1 = $ordered_seqs[0];
		my @genome_list = keys %{$self->{loci_cache}{typing_watchlist}{$query_gene1}};
		print "Number of potential genomes: ".scalar(@genome_list)."\n";
		
		foreach my $genome (@genome_list) {
			
			# Typing sequence properties
			my @seqs = ();
			my @headers = ();
			my @alleles = ();
			my $public;
			my $genome_id;
			my $missing = 0;
			
			# Concatenate all alleles for each query gene in typing sequence
			foreach my $query_gene (@ordered_seqs) {
				my $alleles_list = $self->{loci_cache}{typing_watchlist}{$query_gene}{$genome};
				
				unless(defined $alleles_list) {
					# One of the needed alleles is missing in the genome, skip genome
					$missing = 1;
					last;
					
				} else {
					
					# Iterate through each allele copy for this query gene
					my @next_seqs;
					my @next_headers;
					my @next_alleles;
					
					foreach my $allele_data (@$alleles_list) {
						
						if(@seqs) {
							my $allele_id = $allele_data->{allele};
							
							# Concatenate this set of alleles with all earlier alleles in construct
							foreach my $s (@seqs) {
								push @next_seqs, $s.$allele_data->{seq};
							}
							foreach my $a (@alleles) {
								push @next_alleles, [@$a, $allele_id];
							}
							foreach my $h (@headers) {
								my $thish = "|$query_gene\_$allele_id";
								push @next_headers, $h.$thish;
							}
							
						} else {
							# Start of typing sequence, record all alleles in first position
							my $allele_id = $allele_data->{allele};
							@next_seqs =  ($allele_data->{seq});
							@next_alleles = ([$allele_id]);
							@next_headers = ("$query_gene\_$allele_id");
							$public = $allele_data->{public};
							$genome_id = $allele_data->{genome};
						}
						
						@seqs = @next_seqs;
						@headers = @next_headers;
						@alleles = @next_alleles;
						
					}
				}
			}
					
			# Finalize typing sequence data
			# Each array row represent a single typing sequence in a genome
			if(!$missing) {
				while (@seqs) {
					my $seq = shift @seqs;
					my $h = shift @headers;
					my $allele_list = shift @alleles;
						
					my $uniquename = "typer:$h";
					my $header = "$genome|$h";
					
					my $typing_hash = {
						genome => $genome_id,
						uniquename => $uniquename,
						public => $public,
						alleles => $allele_list,
						header => $header,
						seq => $seq
					};
					
					push @{$typing_sets{$typing_ref_gene}}, $typing_hash;
				}
			}
			
		}
						
		
	}
	
	return(\%typing_sets);

}

sub handle_typing_sequence {
	my $self = shift;
	my ($subtype_name, $typing_ref_id, $subtype_asmt, $typing_dataset) = @_;
	
	my $contig_collection_id = $typing_dataset->{genome};
	my $uniquename = $typing_dataset->{uniquename};
	my $is_public = $typing_dataset->{public}; 
	my $alleles_list = $typing_dataset->{alleles};
	my $upload_id = undef;
	$upload_id = $typing_dataset->{upload_id} unless $is_public;
	
	# Create allele_fusion feature
		
	# ID
	my $curr_feature_id = $self->nextfeature($is_public);

	# Use default organism
	my $organism = $self->organism_id();
	
	# external accessions
	my $dbxref = '\N';
	
	# name
	my $name = "$subtype_name subtype for genome $contig_collection_id";
	
	# Feature relationships
	my $rank = 0;
    my $table = $is_public ? 'feature_relationship' : 'private_feature_relationship';
	
	# Link to contig_collection
	my $rtype = $self->relationship_types('part_of');
    $self->print_frel($self->nextoid($table),$curr_feature_id,$contig_collection_id,$rtype,$rank,$is_public);
	$self->nextoid($table,'++');
	
	# Link to typing reference gene
	$rtype = $self->relationship_types('variant_of');
    $self->print_frel($self->nextoid($table),$curr_feature_id,$typing_ref_id,$rtype,$rank,$is_public);
	$self->nextoid($table,'++');
	
	# Link to alleles
	$rtype = $self->relationship_types('fusion_of');
	foreach my $allele_id (@$alleles_list) {
    	$self->print_frel($self->nextoid($table),$curr_feature_id,$allele_id,$rtype,$rank,$is_public);
		$self->nextoid($table,'++');
		$rank++
	}
	
	# Feature property
	# save subtype classification
 	my $property_cvterm_id = $self->featureprop_types($subtype_name);
	unless($property_cvterm_id) {
		croak "Unrecognized feature property type $subtype_name.";
	}
 	
 	$rank=0;
    $table = $is_public ? 'featureprop' : 'private_featureprop';
	                        	
	$self->print_fprop($self->nextoid($table),$curr_feature_id,$property_cvterm_id,$subtype_asmt,$rank,$is_public,$upload_id);
    $self->nextoid($table,'++');
	
	# Print feature
	my $seq = $typing_dataset->{seq};
	my $seqlen = length($seq);
	my $type = $self->feature_types('allele_fusion');
	$self->print_f($curr_feature_id,$organism, $name, $uniquename, $type, $seqlen, $dbxref, $seq, $is_public, $upload_id);  
	$self->nextfeature($is_public, '++');
		
}

1;

__DATA__
__C__

// Make a series of edits to a dna string
// Edits are stored in an array of arrays:
// [[position, nucleotide],[...]]
void snp_edits(SV* dna, SV* snps_arrayref) {
	AV* snps;
	AV* snp_row;
	
	snps = (AV*)SvRV(snps_arrayref);
	int n = av_len(snps);
	int i;
	
	char* dna_string = (char*)SvPV_nolen(dna);
	
	// Rewrite 
	for(i=0; i <= n; ++i) {
		SV* row = av_shift(snps);
		snp_row = (AV*)SvRV(row);
		
		SV* pos = av_shift(snp_row);
		SV* nuc = av_shift(snp_row);
		int p = (int)SvIV(pos);
		char* c = (char*)SvPV_nolen(nuc);
		
		dna_string[p] = *c;
	}
}


