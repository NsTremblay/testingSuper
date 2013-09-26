BEGIN;

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: featureloc; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE featureloc (
    featureloc_id integer NOT NULL,
    feature_id integer NOT NULL,
    srcfeature_id integer,
    fmin integer,
    is_fmin_partial boolean DEFAULT false NOT NULL,
    fmax integer,
    is_fmax_partial boolean DEFAULT false NOT NULL,
    strand smallint,
    phase integer,
    residue_info text,
    locgroup integer DEFAULT 0 NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    CONSTRAINT featureloc_c2 CHECK ((fmin <= fmax))
);


ALTER TABLE public.featureloc OWNER TO postgres;

--
-- Name: TABLE featureloc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE featureloc IS 'The location of a feature relative to
another feature. Important: interbase coordinates are used. This is
vital as it allows us to represent zero-length features e.g. splice
sites, insertion points without an awkward fuzzy system. Features
typically have exactly ONE location, but this need not be the
case. Some features may not be localized (e.g. a gene that has been
characterized genetically but no sequence or molecular information is
available). Note on multiple locations: Each feature can have 0 or
more locations. Multiple locations do NOT indicate non-contiguous
locations (if a feature such as a transcript has a non-contiguous
location, then the subfeatures such as exons should always be
manifested). Instead, multiple featurelocs for a feature designate
alternate locations or grouped locations; for instance, a feature
designating a blast hit or hsp will have two locations, one on the
query feature, one on the subject feature. Features representing
sequence variation could have alternate locations instantiated on a
feature on the mutant strain. The column:rank is used to
differentiate these different locations. Reflexive locations should
never be stored - this is for -proper- (i.e. non-self) locations only; nothing should be located relative to itself.';


--
-- Name: COLUMN featureloc.feature_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.feature_id IS 'The feature that is being located. Any feature can have zero or more featurelocs.';


--
-- Name: COLUMN featureloc.srcfeature_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.srcfeature_id IS 'The source feature which this location is relative to. Every location is relative to another feature (however, this column is nullable, because the srcfeature may not be known). All locations are -proper- that is, nothing should be located relative to itself. No cycles are allowed in the featureloc graph.';


--
-- Name: COLUMN featureloc.fmin; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.fmin IS 'The leftmost/minimal boundary in the linear range represented by the featureloc. Sometimes (e.g. in Bioperl) this is called -start- although this is confusing because it does not necessarily represent the 5-prime coordinate. Important: This is space-based (interbase) coordinates, counting from zero. To convert this to the leftmost position in a base-oriented system (eg GFF, Bioperl), add 1 to fmin.';


--
-- Name: COLUMN featureloc.is_fmin_partial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.is_fmin_partial IS 'This is typically
false, but may be true if the value for column:fmin is inaccurate or
the leftmost part of the range is unknown/unbounded.';


--
-- Name: COLUMN featureloc.fmax; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.fmax IS 'The rightmost/maximal boundary in the linear range represented by the featureloc. Sometimes (e.g. in bioperl) this is called -end- although this is confusing because it does not necessarily represent the 3-prime coordinate. Important: This is space-based (interbase) coordinates, counting from zero. No conversion is required to go from fmax to the rightmost coordinate in a base-oriented system that counts from 1 (e.g. GFF, Bioperl).';


--
-- Name: COLUMN featureloc.is_fmax_partial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.is_fmax_partial IS 'This is typically
false, but may be true if the value for column:fmax is inaccurate or
the rightmost part of the range is unknown/unbounded.';


--
-- Name: COLUMN featureloc.strand; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.strand IS 'The orientation/directionality of the
location. Should be 0, -1 or +1.';


--
-- Name: COLUMN featureloc.phase; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.phase IS 'Phase of translation with
respect to srcfeature_id.
Values are 0, 1, 2. It may not be possible to manifest this column for
some features such as exons, because the phase is dependant on the
spliceform (the same exon can appear in multiple spliceforms). This column is mostly useful for predicted exons and CDSs.';


--
-- Name: COLUMN featureloc.residue_info; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.residue_info IS 'Alternative residues,
when these differ from feature.residues. For instance, a SNP feature
located on a wild and mutant protein would have different alternative residues.
for alignment/similarity features, the alternative residues is used to
represent the alignment string (CIGAR format). Note on variation
features; even if we do not want to instantiate a mutant
chromosome/contig feature, we can still represent a SNP etc with 2
locations, one (rank 0) on the genome, the other (rank 1) would have
most fields null, except for alternative residues.';


--
-- Name: COLUMN featureloc.locgroup; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.locgroup IS 'This is used to manifest redundant,
derivable extra locations for a feature. The default locgroup=0 is
used for the DIRECT location of a feature. Important: most Chado users may
never use featurelocs WITH logroup > 0. Transitively derived locations
are indicated with locgroup > 0. For example, the position of an exon on
a BAC and in global chromosome coordinates. This column is used to
differentiate these groupings of locations. The default locgroup 0
is used for the main or primary location, from which the others can be
derived via coordinate transformations. Another example of redundant
locations is storing ORF coordinates relative to both transcript and
genome. Redundant locations open the possibility of the database
getting into inconsistent states; this schema gives us the flexibility
of both warehouse instantiations with redundant locations (easier for
querying) and management instantiations with no redundant
locations. An example of using both locgroup and rank: imagine a
feature indicating a conserved region between the chromosomes of two
different species. We may want to keep redundant locations on both
contigs and chromosomes. We would thus have 4 locations for the single
conserved region feature - two distinct locgroups (contig level and
chromosome level) and two distinct ranks (for the two species).';


--
-- Name: COLUMN featureloc.rank; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN featureloc.rank IS 'Used when a feature has >1
location, otherwise the default rank 0 is used. Some features (e.g.
blast hits and HSPs) have two locations - one on the query and one on
the subject. Rank is used to differentiate these. Rank=0 is always
used for the query, Rank=1 for the subject. For multiple alignments,
assignment of rank is arbitrary. Rank is also used for
sequence_variant features, such as SNPs. Rank=0 indicates the wildtype
(or baseline) feature, Rank=1 indicates the mutant (or compared) feature.';


--
-- Name: featureloc_featureloc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE featureloc_featureloc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.featureloc_featureloc_id_seq OWNER TO postgres;

--
-- Name: featureloc_featureloc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE featureloc_featureloc_id_seq OWNED BY featureloc.featureloc_id;


--
-- Name: featureloc_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY featureloc ALTER COLUMN featureloc_id SET DEFAULT nextval('featureloc_featureloc_id_seq'::regclass);


--
-- Name: featureloc_c1; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_c1 UNIQUE (feature_id, locgroup, rank);


--
-- Name: featureloc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_pkey PRIMARY KEY (featureloc_id);


--
-- Name: binloc_boxrange; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX binloc_boxrange ON featureloc USING gist (boxrange(fmin, fmax));


--
-- Name: binloc_boxrange_src; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX binloc_boxrange_src ON featureloc USING gist (boxrange(srcfeature_id, fmin, fmax));


--
-- Name: featureloc_idx1; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX featureloc_idx1 ON featureloc USING btree (feature_id);


--
-- Name: featureloc_idx2; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX featureloc_idx2 ON featureloc USING btree (srcfeature_id);


--
-- Name: featureloc_idx3; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX featureloc_idx3 ON featureloc USING btree (srcfeature_id, fmin, fmax);


--
-- Name: featureloc_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: featureloc_srcfeature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_srcfeature_id_fkey FOREIGN KEY (srcfeature_id) REFERENCES feature(feature_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: feature_cvterm; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE feature_cvterm (
    feature_cvterm_id integer NOT NULL,
    feature_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    pub_id integer NOT NULL,
    is_not boolean DEFAULT false NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.feature_cvterm OWNER TO postgres;

--
-- Name: TABLE feature_cvterm; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE feature_cvterm IS 'Associate a term from a cv with a feature, for example, GO annotation.';


--
-- Name: COLUMN feature_cvterm.pub_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN feature_cvterm.pub_id IS 'Provenance for the annotation. Each annotation should have a single primary publication (which may be of the appropriate type for computational analyses) where more details can be found. Additional provenance dbxrefs can be attached using feature_cvterm_dbxref.';


--
-- Name: COLUMN feature_cvterm.is_not; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN feature_cvterm.is_not IS 'If this is set to true, then this annotation is interpreted as a NEGATIVE annotation - i.e. the feature does NOT have the specified function, process, component, part, etc. See GO docs for more details.';


--
-- Name: feature_cvterm_feature_cvterm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE feature_cvterm_feature_cvterm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.feature_cvterm_feature_cvterm_id_seq OWNER TO postgres;

--
-- Name: feature_cvterm_feature_cvterm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE feature_cvterm_feature_cvterm_id_seq OWNED BY feature_cvterm.feature_cvterm_id;


--
-- Name: feature_cvterm_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY feature_cvterm ALTER COLUMN feature_cvterm_id SET DEFAULT nextval('feature_cvterm_feature_cvterm_id_seq'::regclass);


--
-- Name: feature_cvterm_c1; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_c1 UNIQUE (feature_id, cvterm_id, pub_id, rank);


--
-- Name: feature_cvterm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_pkey PRIMARY KEY (feature_cvterm_id);


--
-- Name: feature_cvterm_idx1; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX feature_cvterm_idx1 ON feature_cvterm USING btree (feature_id);


--
-- Name: feature_cvterm_idx2; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX feature_cvterm_idx2 ON feature_cvterm USING btree (cvterm_id);


--
-- Name: feature_cvterm_idx3; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX feature_cvterm_idx3 ON feature_cvterm USING btree (pub_id);


--
-- Name: feature_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: feature_cvterm_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: feature_cvterm_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--


COMMIT;
