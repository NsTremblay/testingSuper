package Sequences::ExperimentalFeatures;

use strict;
use warnings;
use DBI;
use Carp qw/croak carp confess/;
use Sys::Hostname;
use File::Temp;
use Time::HiRes qw( time );

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
	"raw_virulence_data",
	"raw_amr_data",
	"snp_core",
	"snp_variation",
	"private_snp_variation",
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
  	raw_virulence_data           => "raw_virulence_data_serial_id_seq",
  	raw_amr_data                 => "raw_amr_data_serial_id_seq",
  	snp_core                     => "snp_core_snp_core_id_seq",
  	snp_variation                => "snp_variation_snp_variation_id_seq",
  	private_snp_variation        => "private_snp_variation_snp_variation_id_seq",
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
  	raw_virulence_data           => "serial_id",
  	raw_amr_data                 => "serial_id",
  	snp_core                     => "snp_core_id",
  	snp_variation                => "snp_variation_id",
  	private_snp_variation        => "snp_variation_id"
);

# Valid cvterm types for featureprops table
# hash: name => cv
my %fp_types = (
	copy_number_increase => 'sequence',
	match => 'sequence',
	panseq_function => 'local'
	
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
   raw_virulence_data           => "(serial_id,genome_id,gene_id,presence_absence)",
   raw_amr_data                 => "(serial_id,genome_id,gene_id,presence_absence)",
   snp_core                     => "(snp_core_id,pangenome_region,allele,position,gap_offset,aln_block,aln_column)",
   snp_variation                => "(snp_variation_id,snp,contig_collection,contig,locus,allele)",
   private_snp_variation        => "(snp_variation_id,snp,contig_collection,contig,locus,allele)",
);

my %updatestring = (
	tfeature                      => "seqlen = s.seqlen, residues = s.residues",
	tfeatureloc                   => "fmin = s.fmin, fmax = s.fmin, strand = s.strand, locgroup = s.locgroup, rank = s.rank",
	tfeatureprop                  => "value = s.value",
	tprivate_feature              => "seqlen = s.seqlen, residues = s.residues",
	tprivate_featureloc           => "fmin = s.fmin, fmax = s.fmin, strand = s.strand, locgroup = s.locgroup, rank = s.rank",
	tprivate_featureprop          => "value = s.value",
	ttree                         => "tree_string = s.tree_string",
	tsnp_core                     => "position = s.position, gap_offset = s.gap_offset"
);

my %tmpcopystring = (
	tfeature                      => "(feature_id,organism_id,uniquename,type_id,seqlen,residues)",
	tfeatureprop                  => "(feature_id,type_id,value,rank)",
	tfeatureloc                   => "(feature_id,fmin,fmax,strand,locgroup,rank)",
	tprivate_feature              => "(feature_id,organism_id,uniquename,type_id,seqlen,residues)",
	tprivate_featureprop          => "(feature_id,type_id,value,rank)",
	tprivate_featureloc           => "(feature_id,fmin,fmax,strand,locgroup,rank)",
	ttree                         => "(tree_id,name,tree_string)",
	tsnp_core                     => "(snp_core_id,pangenome_region,position,gap_offset)"
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

# Key values for uniquename cache
my $ALLOWED_UNIQUENAME_CACHE_KEYS = "feature_id|type_id|uniquename|validate|is_public";

# Key values for loci cache
my $ALLOWED_LOCI_CACHE_KEYS = "feature_id|type_id|uniquename|is_public|genome_id|contig_id|query_id";
               
# Tables for which caches are maintained
my $ALLOWED_CACHE_KEYS = "collection|contig|feature|sequence|core|core_snp";

# Tmp file names for storing upload data
my %files = map { $_ => 'FH'.$_; } @tables, @update_tables;

# SQL for unique cache
use constant CREATE_CACHE_TABLE =>
	"CREATE TABLE public.tmp_gff_load_cache (
	     feature_id int,
	     uniquename varchar(1000),
	     type_id int,
	     organism_id int,
	     pub boolean
	)";
use constant DROP_CACHE_TABLE => "DROP TABLE public.tmp_gff_load_cache";
use constant VERIFY_TMP_TABLE => "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
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
               
# SQL for loci cache
use constant CREATE_LOCI_CACHE_TABLE =>
	"CREATE TABLE public.tmp_loci_cache (
	     feature_id int,
	     uniquename varchar(1000),                
	     genome_id int,                   
	     query_id int,                 
	     pub boolean,
	     updated boolean
	)";
use constant DROP_LOCI_CACHE_TABLE => "DROP TABLE public.tmp_loci_cache";
use constant POPULATE_LOCI_CACHE_TABLE =>
	"INSERT INTO public.tmp_loci_cache
	 SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, TRUE, FALSE
	 FROM feature f, feature_relationship f1, feature_relationship f2
	 WHERE f.type_id = ? AND
	   f1.type_id = ? AND f1.subject_id = f.feature_id AND
	   f2.type_id = ? AND f2.subject_id = f.feature_id";
use constant POPULATE_PRIVATE_LOCI_CACHE_TABLE =>
	"INSERT INTO public.tmp_loci_cache ".
	"SELECT f.feature_id, f.uniquename, f1.object_id, f2.object_id, FALSE, FALSE ".
	"FROM private_feature f, private_feature_relationship f1, private_feature_relationship f2 ".
	"WHERE f.type_id = ? AND".
	" f1.type_id = ? AND f1.subject_id = f.feature_id AND".
	" f2.type_id = ? AND f2.subject_id = f.feature_id";
use constant CREATE_LOCI_TABLE_INDEX1 =>
	"CREATE INDEX tmp_loci_cache_idx1 ON public.tmp_loci_cache (genome_id,query_id,pub)";
use constant TMP_LOCI_CLEANUP =>
	"DELETE FROM tmp_loci_cache WHERE pub = TRUE AND feature_id >= ?";             
use constant TMP_LOCI_PRIVATE_CLEANUP =>
	"DELETE FROM tmp_loci_cache WHERE pub = FALSE AND feature_id >= ?";
use constant TMP_LOCI_RESET => "UPDATE tmp_loci_cache SET updated = ?";
	
# SQL for snp alignment cache
use constant CREATE_SNP_TABLE =>
	"CREATE TABLE public.snp_alignment (
		name varchar(100),
		block int,
		current_position int,
		alignment varchar(10000)
	)";
use constant CREATE_SNP_TABLE_INDEX1 =>
	"ALTER TABLE public.snp_alignment ADD CONSTRAINT snp_alignment_c1 UNIQUE (name,block)";
use constant CREATE_SNP_CACHE_TABLE_INDEX1 =>
	"ALTER TABLE public.tmp_snp_cache ADD CONSTRAINT tmp_snp_cache_c1 UNIQUE (name,block)";
use constant INITIALIZE_SNP_TABLE =>
	"INSERT into public.snp_alignment ".
	"VALUES('core',1,0,'')";
use constant CREATE_SNP_CACHE_TABLE =>
	"CREATE TABLE public.tmp_snp_cache AS ".
	"SELECT * FROM public.snp_alignment";
use constant DROP_SNP_CACHE_TABLE =>
	"DROP TABLE public.tmp_snp_cache";
use constant FIND_CURRENT_SNP_COLUMN => 
	"SELECT max(current_position) FROM public.tmp_snp_cache ".
	"WHERE block = ?";
use constant FIND_CURRENT_SNP_BLOCK => "SELECT max(block) FROM public.tmp_snp_cache";
                     
                    
# SQL for lock table
use constant CREATE_META_TABLE =>
	"CREATE TABLE gff_meta (
	      name        varchar(100),
	      hostname    varchar(100),
	      starttime   timestamp not null default now() 
	 )";
use constant SELECT_FROM_META => "SELECT name,hostname,starttime FROM gff_meta";
use constant INSERT_INTO_META => "INSERT INTO gff_meta (name,hostname) VALUES (?,?)";
use constant DELETE_FROM_META => "DELETE FROM gff_meta WHERE name = ? AND hostname = ?";
               
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
	   VALUES (?,?,TRUE)";
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
	
# SQL for maintaing loci info
use constant VALIDATE_LOCI =>
	"SELECT feature_id FROM public.tmp_loci_cache WHERE ".
    " genome_id = ? AND query_id = ? AND uniquename = ? AND pub = ? AND updated = FALSE";
use constant INSERT_LOCI =>
	"INSERT INTO public.tmp_loci_cache ".
	"(feature_id,uniquename,genome_id,query_id,pub,updated) VALUES (?,?,?,?,?,TRUE)";
use constant UPDATE_LOCI =>
	"UPDATE public.tmp_loci_cache SET updated = TRUE WHERE feature_id = ?";
               

# SQL for updating phylogenetic trees
use constant VALIDATE_TREE => "SELECT tree_id FROM tree WHERE name = ?";

# SQL for maintaining snps
use constant VALIDATE_CORE_SNP => 
	"SELECT snp_core_id, aln_block, aln_column FROM snp_core WHERE pangenome_region = ? AND position = ? AND gap_offset = ?";
use constant VALIDATE_PUBLIC_SNP => 
	"SELECT snp_variation_id FROM snp_variation WHERE snp = ? AND contig_collection = ?";
use constant VALIDATE_PRIVATE_SNP => 
	"SELECT snp_variation_id FROM private_snp_variation WHERE snp = ? AND contig_collection = ?";
	
# SQL for retrieving pangenome IDs from DB
use constant RETRIEVE_PANGENOME_ID => "SELECT feature_id FROM feature WHERE uniquename = ? AND type_id = ?";	

# SQL for retrieving cached genome IDs from DB 
use constant RETRIEVE_ID => "SELECT collection_id, contig_id FROM pipeline_cache WHERE tracker_id = ? AND chr_num = ?";	

# SQL for maintaining core SNP alignments
use constant ADD_SNP_ROW =>
	"INSERT INTO public.tmp_snp_cache ".
	" SELECT  ?, me.block, me.current_position, me.alignment ".
	" FROM public.tmp_snp_cache me WHERE name = ? ";
use constant ADD_SNP_COLUMN =>
	"UPDATE public.tmp_snp_cache ".
	"SET block = ?, current_position = ?, alignment = source.src_alignment || ? ".
	"FROM ( SELECT alignment AS src_alignment,".
	" name AS src_name,".
	" block AS src_block".
	" FROM public.tmp_snp_cache ) AS source ".
	"WHERE name = source.src_name AND block = source.src_block AND block = ?";
use constant ADD_SNP_BLOCK =>
	"INSERT INTO tmp_snp_cache (name, block, current_position, alignment) ".
	" SELECT me.name, ?, ?, ?".
	" FROM tmp_snp_cache me
	  GROUP BY me.name";
use constant ALTER_SNP => 
	"UPDATE public.tmp_snp_cache ".
	" SET alignment = overlay(alignment placing ? from ?) ".
	" WHERE name = ? AND block = ?";
use constant VALIDATE_SNP_ALIGNMENT => "SELECT count(*) FROM tmp_snp_cache WHERE name = ?";
use constant RETRIEVE_PUBLIC_SNP_COLUMN =>
	"SELECT contig_collection, locus, allele FROM snp_variation WHERE snp = ?";
use constant RETRIEVE_PRIVATE_SNP_COLUMN =>
	"SELECT contig_collection, locus, allele FROM private_snp_variation WHERE snp = ?";
	           
            
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
	
	$self->{snp_aware} = 0;
	$self->{snp_aware} = 1 if $arg{snp_capable};
	
	$self->prepare_queries();
	$self->initialize_sequences();
	$self->initialize_ontology();
	$self->initialize_db_caches();
	$self->initialize_snp_caches() if $self->{snp_aware};
	
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
    
    
    $self->{feature_types} = {
    	contig_collection => $contig_col,
    	contig => $contig,
    	allele => $allele,
    	experimental_feature => $experimental_feature,
    	snp => $snp,
    	locus => $locus,
    	pangenome => $pan,
    	core_genome => $core
    };
    
	$self->{relationship_types} = {
    	part_of => $part_of,
    	similar_to => $similar_to,
    	located_in => $located_in,
    	derives_from => $derives_from,
    	contained_id => $contained_in
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

sub initialize_db_caches {
    my $self = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    
    # Uniquename cache
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
     
    }
    
    # Loci cache    
    $sth->execute('tmp_loci_cache');
    ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists || $self->recreate_cache() ) {
        print STDERR "(Re)creating the loci cache in the database... ";
        $dbh->do(DROP_LOCI_CACHE_TABLE) if ($self->recreate_cache() and $table_exists);

        print STDERR "\nCreating table...\n";
        $dbh->do(CREATE_LOCI_CACHE_TABLE);
        
        print STDERR "Populating table...\n";
        $dbh->do(POPULATE_LOCI_CACHE_TABLE, undef,
        	$self->feature_types('allele'), $self->relationship_types('part_of'),$self->relationship_types('similar_to'));
        $dbh->do(POPULATE_PRIVATE_LOCI_CACHE_TABLE, undef,
        	$self->feature_types('allele'), $self->relationship_types('part_of'),$self->relationship_types('similar_to'));
       	
        print STDERR "Creating indexes...\n";
        $dbh->do(CREATE_LOCI_TABLE_INDEX1);
       
        print STDERR "Done.\n";
    }
    
    $dbh->do(TMP_LOCI_RESET, undef, 'FALSE');
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

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_snp_caches {
    my $self = shift;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    
    # snp_alignment table will need to be created if this is the first run
    $sth->execute('snp_alignment');
    my ($table_exists) = $sth->fetchrow_array;
    
    if(!$table_exists) {
    	$dbh->do(CREATE_SNP_TABLE);
    	$dbh->do(CREATE_SNP_TABLE_INDEX1);
    	$dbh->do(INITIALIZE_SNP_TABLE);
    }
    
    # Create tmp table to load data from this run
    $sth->execute('tmp_snp_cache');
    my ($table_exists2) = $sth->fetchrow_array;
    if($table_exists2) {
    	$dbh->do(DROP_SNP_CACHE_TABLE);
    }
    $dbh->do(CREATE_SNP_CACHE_TABLE);
    $dbh->do(CREATE_SNP_CACHE_TABLE_INDEX1);
    
    # Initialize the counters
	$sth = $dbh->prepare(FIND_CURRENT_SNP_BLOCK);
    $sth->execute();
    my ($block) = $sth->fetchrow_array();
	$sth = $dbh->prepare(FIND_CURRENT_SNP_COLUMN);
    $sth->execute($block);
    my ($pos) = $sth->fetchrow_array();
    
    
    
    #my $max = 10000;
    my $max = 1000;
    
    # Advance counter
    $pos++;
    if($pos > $max) {
    	$pos = 1;
    	$block++;
    }
    
    print "CURRENT BLOCK: $block, NEXT COLUMN: $pos\n";
    
    $self->{snp_alignment}->{block} = $block;
    $self->{snp_alignment}->{column} = $pos;
    $self->{snp_alignment}->{max_column} = $max;
   
   
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
	elsif ($argv{type_id} && $argv{is_public}) { 
	
		$self->{'queries'}{'insert_cache_type_id'}->execute(
		    $argv{feature_id},
		    $argv{uniquename},
		    $argv{type_id},    
		);
		$self->dbh->commit;
		return;
	}
	elsif ($argv{type_id} && !$argv{is_public}) { 
	
		$self->{'queries'}{'insert_cache_private_type_id'}->execute(
		    $argv{feature_id},
		    $argv{uniquename},
		    $argv{type_id},    
		);
		$self->dbh->commit;
		return;
	}
}


=head2 loci_cache

=over

=item Usage

  $obj->loci_cache()

=item Function

Maintains a cache of unique alleles present in the database

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

sub loci_cache {
	my ($self, %argv) = @_;
	
	my @bogus_keys = grep {!/($ALLOWED_LOCI_CACHE_KEYS)/} keys %argv;
	
	if (@bogus_keys) {
		for (@bogus_keys) {
		    carp "I don't know what to do with the key ".$_.
		   " in the loci_cache method; it's probably because of a typo\n";
		}
		croak;
	}
		
	$self->{'queries'}{'insert_loci'}->execute(
	    $argv{feature_id},
	    $argv{uniquename},
	    $argv{genome_id},
	    $argv{query_id},
	    $argv{is_public}
	);
	
	$self->dbh->commit;
	return;
}

#=head2 loci_cache
#
#=over
#
#=item Usage
#
#  $obj->loci_cache()
#
#=item Function
#
#Maintains a cache of unique alleles present in the database
#
#=item Returns
#
#See Arguements.
#
#=item Arguments
#
#uniquename_cache takes a hash.  
#If it has a key 'validate', it returns the feature_id
#of the feature corresponding to that uniquename if present, 0 if it is not.
#Otherwise, it uses the values in the hash to update the uniquename_cache
#
#Allowed hash keys:
#
#  feature_id
#  type_id
#  organism_id
#  uniquename
#  validate
#
#=back
#
#=cut
#
#sub snp_cache {
#	my ($self, %argv) = @_;
#	
#	my @bogus_keys = grep {!/($ALLOWED_LOCI_CACHE_KEYS)/} keys %argv;
#	
#	if (@bogus_keys) {
#		for (@bogus_keys) {
#		    carp "I don't know what to do with the key ".$_.
#		   " in the loci_cache method; it's probably because of a typo\n";
#		}
#		croak;
#	}
#		
#	$self->{'queries'}{'insert_loci'}->execute(
#	    $argv{feature_id},
#	    $argv{uniquename},
#	    $argv{genome_id},
#	    $argv{query_id},
#	    $argv{is_public}
#	);
#	
#	$self->dbh->commit;
#	return;
#}

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
  feature_tree_c1:         [feature_id, tree_id, is_public]
  tree_c1:                 [tree_name],
  binary_c1:               [genome_label, genome_id]
  snp_core_c1:             [ref_pangenome_id, position]
  
=back

=cut

sub constraint {
    my ($self, %argv) = @_;

    my $constraint = $argv{name};
    my @terms      = @{ $argv{terms} };
    
    if ($constraint eq 'feature_cvterm_c1' ||
        $constraint eq 'featureloc_c1' ||
        $constraint eq 'feature_tree_c1' ||
        $constraint eq 'snp_variation_c1' ||
        $constraint eq 'snp_core_c1') {
		
		croak( "wrong number of constraint terms $constraint") if (@terms != 3);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'tree_c1') {
        
        croak("wrong number of constraint terms for $constraint") if (@terms != 1);
        my $i = 0;
        foreach(@terms) {
        	croak "term $i undefined for $constraint" unless defined $_;
        	$i++
        }
        if ($self->{$constraint}{$terms[0]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'binary_c1'||
        $constraint eq 'snp_alignment_c1' ||
        $constraint eq 'snp_core_c2' ) {
        
        croak("wrong number of constraint terms for $constraint") if (@terms != 2);
        my $i = 0;
        foreach(@terms) {
        	croak "term $i undefined for $constraint" unless defined $_;
        	$i++
        }
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
        
        croak("wrong number of constraint terms for $constraint") if (@terms != 4);
        my $i = 0;
        foreach(@terms) {
        	croak "term $i undefined for $constraint" unless defined $_;
        	$i++
        }
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
    if($first_feature){
    	$dbh->do(TMP_TABLE_CLEANUP, undef, $first_feature);
    	$dbh->do(TMP_LOCI_CLEANUP, undef, $first_feature);
		
    }

	# private
    
    my $first_feature2 = $self->first_private_feature_id();
	if($first_feature2){
    	$dbh->do(TMP_TABLE_PRIVATE_CLEANUP, undef, $first_feature2);
    	$dbh->do(TMP_LOCI_PRIVATE_CLEANUP, undef, $first_feature2);
    }
    
    # loci table reset
    $dbh->do(TMP_LOCI_RESET, undef, 'FALSE');
                            
    return;
}


=head2 uniquename_validation

=over

=item Usage

  $obj->uniquename_validation(uniquename, type_id, feature_id, is_public)

=item Function

Determines if uniquename is really unique. If so, caches it and returns uniquename.
If not, attempts to create a unique

=item Returns

0 if uniquename is not unique, otherwise returns 1

=item Arguments

  Array containing uniquename string, the cvterm type ID, feature ID for the next feature
  and boolean indicating if feature is public.

=back

=cut

sub uniquename_validation {
	my $self = shift;
	my ($uniquename, $type, $nextfeature, $pub) = @_;

	if ($self->uniquename_cache(validate => 1, type_id => $type, uniquename => $uniquename )) { 
		#if this returns non-zero, it is already in the cache and not valid
		warn "Warning: uniquename collision. This might indicate an attempt to reload experimental feature data.";
		return 0;
		
	} else { 
		# this uniquename is valid. cache it and return
		$self->uniquename_cache(type_id => $type, feature_id => $nextfeature, uniquename => $uniquename, is_public => $pub );
	}
	
	return $uniquename;
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
	
	$self->{'queries'}{'insert_cache_private_type_id'} = $dbh->prepare(INSERT_CACHE_PRIVATE_TYPE_ID);
	
	#$self->{'queries'}{'insert_cache_uniquename'} = $dbh->prepare(INSERT_CACHE_UNIQUENAME);
	
	$self->{'queries'}{'select_from_public_feature'} = $dbh->prepare(SELECT_FROM_PUBLIC_FEATURE);
	
	$self->{'queries'}{'select_from_private_feature'} = $dbh->prepare(SELECT_FROM_PRIVATE_FEATURE);
	
	# Loci table
	$self->{'queries'}{'validate_loci'} = $dbh->prepare(VALIDATE_LOCI);
	
	$self->{'queries'}{'insert_loci'} = $dbh->prepare(INSERT_LOCI);
	
	$self->{'queries'}{'update_loci'} = $dbh->prepare(UPDATE_LOCI);
	
	# Tree table
	$self->{'queries'}{'validate_tree'} = $dbh->prepare(VALIDATE_TREE);
	
	# Pangenome utilities
	$self->{'queries'}{'retrieve_pangenome_id'} = $dbh->prepare(RETRIEVE_PANGENOME_ID);
	
	# Cache table
	if($self->{db_cache}) {
		$self->{'queries'}{'retrieve_id'} = $dbh->prepare(RETRIEVE_ID);
	}
	
	# SNP stuff
	if($self->{snp_aware}) {
		# SNP tables
		$self->{'queries'}{'validate_core_snp'} = $dbh->prepare(VALIDATE_CORE_SNP);
		$self->{'queries'}{'validate_public_snp'} = $dbh->prepare(VALIDATE_PUBLIC_SNP);
		$self->{'queries'}{'validate_private_snp'} = $dbh->prepare(VALIDATE_PRIVATE_SNP);
		
		# SNP Alignment tables
		$self->{'queries'}{'add_snp_row'} = $dbh->prepare(ADD_SNP_ROW);
		$self->{'queries'}{'add_snp_column'} = $dbh->prepare(ADD_SNP_COLUMN);
		$self->{'queries'}{'add_snp_block'} = $dbh->prepare(ADD_SNP_BLOCK);
		$self->{'queries'}{'alter_snp'} = $dbh->prepare(ALTER_SNP);
		$self->{'queries'}{'validate_snp_alignment'} = $dbh->prepare(VALIDATE_SNP_ALIGNMENT);
		$self->{'queries'}{'retrieve_public_snp_column'} = $dbh->prepare(RETRIEVE_PUBLIC_SNP_COLUMN);
		$self->{'queries'}{'retrieve_private_snp_column'} = $dbh->prepare(RETRIEVE_PRIVATE_SNP_COLUMN);
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
	
	# Do live replacement of snp_alignment table
	$self->push_snp_alignment() if $self->{snp_aware};
	
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

=head2 validate_allele

=over

=item Usage

  $obj->validate_allele($query_id, $contig_collection_id, $uniquename, $is_public)

=item Function

Determines if genome allele already exists for given query gene. If it does it exists,
marks allele as being updated in cache

=item Returns

Nothing

=item Arguments

The feature_id for the query gene feature, contig collection, the uniquename and a boolean indicating public or private

=back

=cut

sub validate_allele {
    my $self = shift;
	my ($query_id, $cc_id, $un, $pub) = @_;
	
    $self->{queries}{'validate_loci'}->execute($cc_id, $query_id, $un, $pub);
	my ($allele_id, $allele_name) = $self->{queries}{'validate_loci'}->fetchrow_array;
	
	if($allele_id) {
		# existing allele, mark as being updated
		$self->{queries}{'update_loci'}->execute($allele_id);
		$self->dbh->commit;
		return($allele_id,$allele_name);
		
	} else {
		# no existing allele
		return 0;
	}
}

=head2 validate_snp

=over

=item Usage

  $obj->validate_allele($query_id, $contig_collection_id, $uniquename, $is_public)

=item Function

Determines if genome allele already exists for given query gene. If it does it exists,
marks allele as being updated in cache

=item Returns

Nothing

=item Arguments

The feature_id for the query gene feature, contig collection, the uniquename and a boolean indicating public or private

=back

=cut

sub validate_snp {
    my $self = shift;
	my ($snp, $contig_collection, $contig, $pub) = @_;
	
	# Search for existing core snp entries in cached values
	if ($self->constraint(name => 'snp_variation_c1', terms => [ $snp, $contig_collection, $pub ])) {
		
		# not found in constraint cache, check DB
		# NOTE: the call to constraint records this entry, so we better create a entry in the DB
		# after this method!!
		if($pub) {
			$self->{queries}{'validate_public_snp'}->execute($snp, $contig_collection);
			my ($snp_id) = $self->{queries}{'validate_public_snp'}->fetchrow_array;
			return 1 if $snp_id;
		
		} else {
			$self->{queries}{'validate_private_snp'}->execute($snp, $contig_collection);
			my ($snp_id) = $self->{queries}{'validate_private_snp'}->fetchrow_array;
			return 1 if $snp_id;

		}
		
	} else {
		return 0;
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
	
	if ($self->constraint(name => 'snp_alignment_c1', terms => [ $genome_id, $is_public ]) ) {
	
		# not found in constraint cache, check DB
		# NOTE: the call to constraint records this entry, so we better create a entry in the DB
		# after this method!!
		my $pre = $is_public ? 'public_':'private_';
		my $genome = $pre . $genome_id;
		
		$self->{queries}{'validate_snp_alignment'}->execute($genome);
		my ($found) = $self->{queries}{'validate_snp_alignment'}->fetchrow_array;
		return 0 if $found;
		return 1;
		
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
	my ($core_snp_id, $block, $column);
	
	if(defined $self->cache('core_snp', "$id.$pos.$gap_offset")) {
		($core_snp_id, $block, $column) = @{$self->cache('core_snp', "$id.$pos.$gap_offset")};
	} else {
		# Search for existing entries in snp_core table
		$self->{queries}{'validate_core_snp'}->execute($id,$pos,$gap_offset);
		($core_snp_id, $block, $column) = $self->{queries}{'validate_core_snp'}->fetchrow_array;
		
		$self->cache('core_snp', "$id.$pos.$gap_offset", [$core_snp_id, $block, $column]) if $core_snp_id;
	}
	
	return ($core_snp_id, $block, $column);
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
	
	$self->{'queries'}{'retrieve_id'}->execute($tracking_id, $chr_num);
	
	return $self->{'queries'}{'retrieve_id'}->fetchrow_array();
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
		if ($self->constraint(name => 'feature_relationship_c1', terms => [ $parent_id, $child_id, $type, $pub ]) ) {
	                                        	
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

Create 'derives_from' entry in feature_relationship table.

=item Returns

Nothing

=item Arguments

The feature_id for the child feature, query gene and a boolean indicating public or private

=back

=cut

sub handle_pangenome_loci {
    my $self = shift;
    my ($child_id, $parent_id, $pub) = @_;
    
    # pangenome query features are always in public table, so if genome is private
    # this requires the pripub_feature_relationship table
    unless($pub) {
    	$self->add_relationship($child_id, $parent_id, 'derives_from', 0, 1); 
    } else {
    	$self->add_relationship($child_id, $parent_id, 'derives_from', $pub); 
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

=head2 handle_binary

=over

=item Usage

  $obj->handle_binary($genome_label, $query_gene_id, $present_absent, $type)

=item Function

Perform creation of raw data table entry.

=item Returns

Nothing

=item Arguments

1. genome_label: a contig_collection feature in the format: private_12344
2. query_gene_id: a feature ID for the VF or AMR query gene
3. present_absent: 1/0 indicating if allele present for gene
4. type: VF/AMR

=back

=cut

sub handle_binary {
	my $self = shift;
    my ($g_id, $qg_id, $pa, $type) = @_;
    
    my $table;
	if($type eq 'amr') {
		$table = 'raw_amr_data';
		if ($self->constraint(name => 'binary_c1', terms => [ $g_id, $qg_id ]) ) {	                                 	
			$self->print_amr($self->nextoid($table),$g_id,$qg_id,$pa);
			$self->nextoid($table,'++');
		}
	} elsif($type eq 'vf') {
		$table = 'raw_virulence_data';
		if ($self->constraint(name => 'binary_c1', terms => [ $g_id, $qg_id ]) ) {	                                 	
			$self->print_vf($self->nextoid($table),$g_id,$qg_id,$pa);
			$self->nextoid($table,'++');
		}
	}
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
	if ($self->constraint(name => 'featureprop_c1', terms=> [ $feature_id, $property_cvterm_id, $rank, $pub]) ) {
                                      	
		$self->print_fprop($self->nextoid($table),$feature_id,$property_cvterm_id,$allele_copy,$rank,$pub,$upload_id);
      	$self->nextoid($table,'++');
      	
	} else {
		carp "Featureprop with type $property_cvterm_id and rank $rank already exists for this feature.\n";
	}
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

Hash containing headers pointing to FASTA alignment sequences

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
		foreach my $genome (keys %$seq_group) {
			my $allele_id = $seq_group->{$genome}->{allele};
			if($seq_group->{$genome}->{is_new}) {
				my $pub = $seq_group->{$genome}->{public};
				my $table = $pub ? 'feature_tree' : 'private_feature_tree';
				if ($self->constraint(name => 'feature_tree_c1', terms => [ $allele_id, $tree_id, $pub ]) ) {
		                                        	
					$self->print_ftree($self->nextoid($table),$tree_id,$allele_id,'allele',$pub);
					$self->nextoid($table,'++');
				}
			}
		}
		
	} else {
		# create new tree
		
		$tree_id = $self->nextoid('tree');
		
		# build tree-feature relationships
		# query
		if ($self->constraint(name => 'feature_tree_c1', terms => [ $query_id, $tree_id, 1 ]) ) {
	                                        	
			$self->print_ftree($self->nextoid('feature_tree'),$tree_id,$query_id,'locus',1);
			$self->nextoid('feature_tree','++');
		}
		
		# alleles
		foreach my $genome (keys %$seq_group) {
			my $allele_id = $seq_group->{$genome}->{allele};
			my $pub = $seq_group->{$genome}->{public};
			my $table = $pub ? 'feature_tree' : 'private_feature_tree';
			if ($self->constraint(name => 'feature_tree_c1', terms => [ $allele_id, $tree_id, $pub ]) ) {
	                                        	
				$self->print_ftree($self->nextoid($table),$tree_id,$allele_id,'allele',$pub);
				$self->nextoid($table,'++');
			}
		}
		
		# print tree
		if ($self->constraint(name => 'tree_c1', terms => [ $tree_name ]) ) {
	                                        	
			$self->print_tree($tree_id,$tree_name,'perl',$tree);
			$self->nextoid('tree','++');
		}
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
	
	$self->uniquename_validation($uniquename, $type, $curr_feature_id, $is_public);
	
	
	# Core designation
	my $core_value = $in_core ? 'FALSE' : 'TRUE';
	my $core_type = $self->feature_types('core_genome');
    my $rank = 0;

	my $table = 'feature_cvterm';
	if ($self->constraint(name => 'feature_cvterm_c1', terms => [ $curr_feature_id, $core_type, $is_public ]) ) {
                                        	
		$self->print_fcvterm($self->nextoid($table), $curr_feature_id, $core_type, $self->publication_id, $rank, $is_public, $core_value);
		$self->nextoid($table,'++');
	}
	
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
		if ($value && $self->constraint(name => 'featureprop_c1', terms=> [ $curr_feature_id, $property_cvterm_id, $rank, $is_public]) ) {
			
			$self->print_fprop($self->nextoid($table),$curr_feature_id,$property_cvterm_id,$value,$rank,$is_public);
	      	$self->nextoid($table,'++');
	      	
		}
	}
	
	# Print pangenome feature
	$self->print_f($curr_feature_id, $organism, $name, $uniquename, $type, $seqlen, $dbxref, $seq, $is_public);  
	$self->nextfeature($is_public, '++');
	
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
	my ($ref_snp_id, $block, $column) = $self->retrieve_core_snp($ref_id, $ref_pos, $rgap_offset);
	
#	print "CURRENT BLOCK: ".$self->{snp_alignment}->{block}."\n";
#	print "CURRENT COLUMN: ".$self->{snp_alignment}->{column}."\n";
#	$self->print_alignment_lengths();
	
	unless($ref_snp_id) {
		# Create new core snp
		
		# Update snp alignment strings with new column
		($block, $column) = $self->add_snp_column($c2);
		
		my $table = 'snp_core';
		if ($self->constraint(name => 'snp_core_c1', terms => [ $ref_id, $ref_pos, $rgap_offset ]) &&
			$self->constraint(name => 'snp_core_c2', terms => [ $block, $column ])) {
			$ref_snp_id = $self->nextoid($table);	                                 	
			$self->print_sc($ref_snp_id,$ref_id,$c2,$ref_pos,$rgap_offset,$block,$column);
			$self->nextoid($table,'++');
			$self->cache('core_snp',"$ref_id.$ref_pos.$rgap_offset",[$ref_snp_id, $block, $column]);
			#print "SAVED NEW SNP UNDER $ref_id.$ref_pos.$rgap_offset: ".join(',',@{$self->cache('core_snp',"$ref_id.$ref_pos.$rgap_offset")})."\n";
		} else {
			croak "A matching entry for region $ref_id, position $ref_pos, gap offset $rgap_offset already exists in snp_core table.";
		}
		
		#print "NEW COLUMN: $ref_snp_id, $block, $column\n";
		
	} else {
		
		#print "COLUMN: $ref_snp_id, $block, $column\n";
		
	}
	
	#$self->print_alignment_lengths();
	
	unless($self->validate_snp($ref_snp_id, $contig_collection, $contig, $is_public)) {
		
		# Update snp in alignment for genome
		$self->alter_snp($contig_collection,$is_public,$block,$column,$c1);
		
		# Create snp entry
		my $table = $is_public ? 'snp_variation' : 'private_snp_variation';
		$self->print_sv($self->nextoid($table),$ref_snp_id,$contig_collection,$contig,$locus,$c1,$is_public);
		$self->nextoid($table,'++');
		
	} else {
		croak "A matching entry for genome $contig_collection and snp $ref_snp_id already exists in snp_variation table.";
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
                                        	
		$self->print_fcvterm($self->nextoid($table), $child_id, $ef_type, $self->publication_id, $rank,$pub);
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
    	
    
	if ($self->constraint(name => 'feature_relationship_c1', terms => [ $parent_id, $child_id, $rtype, $pub_type ]) ) {
                                        	
		$self->print_frel($self->nextoid($table),$child_id,$parent_id,$rtype,$rank,$pub,$xpub);
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

sub print_amr {
	my $self = shift;
	my ($serial_id,$genome_label,$gene,$present) = @_;
	
	my $fh = $self->file_handles('raw_amr_data');		

	print $fh join("\t", ($serial_id,$genome_label,$gene,$present)),"\n";
}

sub print_vf {
	my $self = shift;
	my ($serial_id,$genome_label,$gene,$present) = @_;
	
	my $fh = $self->file_handles('raw_virulence_data');		

	print $fh join("\t", ($serial_id,$genome_label,$gene,$present)),"\n";
}

sub print_sc {
	my $self = shift;
	my ($sc_id,$ref_id,$nuc,$pos,$gap,$blk,$col) = @_;
	
	my $fh = $self->file_handles('snp_core');		

	print $fh join("\t", ($sc_id,$ref_id,$nuc,$pos,$gap,$blk,$col)),"\n";
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
	
	my ($b,$c);
	if($self->{snp_alignment}->{column} > $self->{snp_alignment}->{max_column}) {
		# New block
		$b = $self->{snp_alignment}->{block}+1;
		$self->{snp_alignment}->{block} = $b;
		$c = $self->{snp_alignment}->{column} = 1;
		
		$self->{'queries'}{'add_snp_block'}->execute($b, $c, $nuc);
		
	} else {
		# New column in current block
		$b = $self->{snp_alignment}->{block};
		$c = $self->{snp_alignment}->{column};
		
		$self->{'queries'}{'add_snp_column'}->execute($b, $c, $nuc, $b);
	
	}
	
	$self->dbh->commit;
	
	$self->{snp_alignment}->{column}++;
	
	return($b,$c);
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
		
		$self->{'queries'}{'add_snp_row'}->execute($genome,'core');
		$self->dbh->commit;
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
  feature table, the alignment block number, the position in the block and the
  character to assign at that position

=back

=cut

sub alter_snp {
	my $self = shift;
	my $genome_id = shift;
	my $is_public = shift;
	my $block = shift;
	my $pos = shift;
	my $nuc = shift;
	
	# Validate alignment positions
	my $maxb = $self->{snp_alignment}->{block};
	croak "Invalid SNP alignment block number $block (max: $maxb)." unless $block <= $maxb;
	my $maxc = $self->{snp_alignment}->{max_column};
	croak "Invalid SNP alignment position $pos (max: $maxc)." unless $pos <= $maxc;
	
	if($maxb == $block) {
		# Changing position in current block, may not be a full block
		$maxc = $self->{snp_alignment}->{column};
		croak "Invalid SNP alignment position $pos in current block $block (max: $maxc)." unless $pos <= $maxc;
	}
	
	# Validate nucleotide
	$nuc = uc($nuc);
	croak "Invalid nucleotide character '$nuc'." unless $nuc =~ m/^[A-Z\-]$/;
	
	my $pre = $is_public ? 'public_' : 'private_';
	my $genome = $pre . $genome_id;
	
	$self->{'queries'}{'alter_snp'}->execute($nuc,$pos,$genome,$block) or 
		croak "Unable to update SNP character in alignment. Make sure genome $genome has corresponding row in alignment ($!).";
	
	$self->dbh->commit;
		
}

=head2 push_snp_alignment

=over

=item Usage

  $obj->push_snp_alignment(); 

=item Function

  Move the current snp_alignment to backup and the tmp_snp_cache table to snp_alignment

=item Returns

  Nothing

=item Arguments

  None

=back

=cut

sub push_snp_alignment {
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	# Drop current backup table, if it exists
	my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    
    $sth->execute('snp_backup');
    my ($table_exists) = $sth->fetchrow_array;
    
    if($table_exists) {
    	$dbh->do('DROP TABLE public.snp_backup');
    }
    
    # Move snp_alignment to backup
    $dbh->do('ALTER TABLE snp_alignment RENAME TO snp_backup');
    $dbh->do('ALTER INDEX snp_alignment_c1 RENAME TO snp_backup_c1');
    # Move cache to snp_alignment
    $dbh->do('ALTER TABLE tmp_snp_cache RENAME TO snp_alignment');
    $dbh->do('ALTER INDEX tmp_snp_cache_c1 RENAME TO snp_alignment_c1');
    
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
        			my ($snp_id, $block, $col) = $self->retrieve_core_snp($refid, $pos, $j);
					
					unless($snp_id) {
						# new insert
						$n++;
					} else {
						push @old_snps, [$snp_id, $block, $col];
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
        
		for(my $i=1; $i <= $gap; $i++) {
			
			# Compare alignment chars to chars in DB for a single alignment column
			# genome_label: private_genome_id|loci_id
			my $col_match = 1;
			foreach my $genome_label (keys %$insert_column) {
				my $c1 = $insert_column->{$genome_label};
				my $c2 = substr($loci_hash->{$genome_label}, $aln+$i-1,1);
				
				if($c1 ne $c2) {
					croak "Error: Unable to position new and old insertion columns in SNP alignment (encountered non-gap character in genome row that is currently in DB)." unless $c2 eq '-';
					# Found new snp column
					
					# Create new entry in snp_core table and add gap column to SNP alignment
					my ($block, $column) = $self->add_snp_column('-');
					
					print "CREATING NEW GAP COLUMN AT POSITION $pos, $i ($block, $column)\n";
					
					$self->constraint(name => 'snp_core_c1', terms => [ $ref_id, $pos, $i ]); # Make sure position is recorded in constraint cache
					
					my $table = 'snp_core';
					if ($self->constraint(name => 'snp_core_c2', terms => [ $block, $column ])) {
						my $ref_snp_id = $self->nextoid($table);	                                 	
						$self->print_sc($ref_snp_id,$ref_id,$c2,$pos,$i,$block,$column);
						$self->nextoid($table,'++');
						$self->cache('core_snp',"$ref_id.$pos.$i",[$ref_snp_id, $block, $column]);
					} else {
						croak "A matching entry for region $ref_id, position $pos, gap offset $i already exists in snp_core table.";
					}
					
					$col_match = 0;
					$n--;
					last;
				}
			}
			
        	if($col_match) {
        		# This gap position matches the current insert column
        		
        		# Update the position of the insert column
        		my ($snp_core_id, $block, $column) = @{$current_insert_ids[0]};
        		$self->print_usc($snp_core_id,$ref_id,$pos,$i);
				
				$self->cache('core_snp',"$ref_id.$pos.$i",[$snp_core_id, $block, $column]);
				
				print "MOVING OLD GAP COLUMN $snp_core_id TO POSITION $pos, $i ($block, $column)\n";
        		
        		shift @current_insert_ids;
        		$insert_column = $self->snp_variations_in_column($current_insert_ids[0][0]) if @current_insert_ids;
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

1;



