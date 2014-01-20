BEGIN;

--
-- SQL for creating additional table for storing private/public snps
--

SET search_path = public, pg_catalog;
SET default_tablespace = '';


-----------------------------------------------------------------------------
--
-- Table Name: snp_core; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE snp_core (
	snp_core_id      integer NOT NULL,
	pangenome_region_id integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n',
	position         integer NOT NULL DEFAULT -1,
	gap_offset       integer NOT NULL DEFAULT 0,
	aln_column       integer NOT NULL DEFAULT 0
);

ALTER TABLE public.snp_core OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE snp_core_snp_core_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.snp_core_snp_core_id_seq OWNER TO postgres;

ALTER SEQUENCE snp_core_snp_core_id_seq OWNED BY snp_core.snp_core_id;

ALTER TABLE ONLY snp_core ALTER COLUMN snp_core_id SET DEFAULT nextval('snp_core_snp_core_id_seq'::regclass);

ALTER TABLE ONLY snp_core
	ADD CONSTRAINT snp_core_pkey PRIMARY KEY (snp_core_id);

--
-- foreign keys
--
ALTER TABLE ONLY snp_core
	ADD CONSTRAINT snp_core_pangenome_region_id_fkey FOREIGN KEY (pangenome_region_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Constraints
--
ALTER TABLE ONLY snp_core
    ADD CONSTRAINT snp_core_c1 UNIQUE (pangenome_region_id, position, gap_offset);

ALTER TABLE ONLY snp_core
    ADD CONSTRAINT snp_core_c2 UNIQUE (aln_column);


--
-- Indices
--


-----------------------------------------------------------------------------
--
-- Table Name: snp_variation; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE snp_variation (
	snp_variation_id integer NOT NULL,
	snp_id           integer NOT NULL,
	contig_collection_id integer NOT NULL,
	contig_id           integer NOT NULL,
	locus_id            integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n'
);

ALTER TABLE public.snp_variation OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE snp_variation_snp_variation_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.snp_variation_snp_variation_id_seq OWNER TO postgres;

ALTER SEQUENCE snp_variation_snp_variation_id_seq OWNED BY snp_variation.snp_variation_id;

ALTER TABLE ONLY snp_variation ALTER COLUMN snp_variation_id SET DEFAULT nextval('snp_variation_snp_variation_id_seq'::regclass);

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_pkey PRIMARY KEY (snp_variation_id);

--
-- Foreign keys
--
ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_snp_id_fkey FOREIGN KEY (snp_id) REFERENCES snp_core(snp_core_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_contig_collection_id_fkey FOREIGN KEY (contig_collection_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_contig_id_fkey FOREIGN KEY (contig_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_locus_id_fkey FOREIGN KEY (locus_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Constraints
--  
ALTER TABLE ONLY snp_variation
    ADD CONSTRAINT snp_variation_c1 UNIQUE (snp_id, contig_collection_id);

--
-- Indices
--
CREATE INDEX snp_variation_idx1 ON snp_variation USING btree (snp_id);

CREATE INDEX snp_variation_idx2 ON snp_variation USING btree (contig_collection_id);



-----------------------------------------------------------------------------
--
-- Table Name: private_snp_variation; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE private_snp_variation (
	snp_variation_id integer NOT NULL,
	snp_id           integer NOT NULL,
	contig_collection_id integer NOT NULL,
	contig_id        integer NOT NULL,
	locus_id         integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n'
);

ALTER TABLE public.private_snp_variation OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE private_snp_variation_snp_variation_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.private_snp_variation_snp_variation_id_seq OWNER TO postgres;

ALTER SEQUENCE private_snp_variation_snp_variation_id_seq OWNED BY private_snp_variation.snp_variation_id;

ALTER TABLE ONLY private_snp_variation ALTER COLUMN snp_variation_id SET DEFAULT nextval('private_snp_variation_snp_variation_id_seq'::regclass);

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_pkey PRIMARY KEY (snp_variation_id);

--
-- Foreign keys
--
ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_snp_id_fkey FOREIGN KEY (snp_id) REFERENCES snp_core(snp_core_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_contig_collection_id_fkey FOREIGN KEY (contig_collection_id) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_contig_id_fkey FOREIGN KEY (contig_id) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_locus_id_fkey FOREIGN KEY (locus_id) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Constraints
--
ALTER TABLE ONLY private_snp_variation
    ADD CONSTRAINT private_snp_variation_c1 UNIQUE (snp_id, contig_collection_id);

--
-- Indices
--
CREATE INDEX private_snp_variation_idx1 ON private_snp_variation USING btree (snp_id);

CREATE INDEX private_snp_variation_idx2 ON private_snp_variation USING btree (contig_collection_id);

-----------------------------------------------------------------------------
--
-- Table Name: snp_alignment; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE snp_alignment (
	snp_alignment_id integer NOT NULL,
	name character varying(100),
	aln_column integer NOT NULL,
	alignment text
);

ALTER TABLE public.snp_alignment OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE snp_alignment_snp_alignment_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.snp_alignment_snp_alignment_id_seq OWNER TO postgres;

ALTER SEQUENCE snp_alignment_snp_alignment_id_seq OWNED BY snp_alignment.snp_alignment_id;

ALTER TABLE ONLY snp_alignment ALTER COLUMN snp_alignment_id SET DEFAULT nextval('snp_alignment_snp_alignment_id_seq'::regclass);

ALTER TABLE ONLY snp_alignment
	ADD CONSTRAINT snp_alignment_pkey PRIMARY KEY (snp_alignment_id);


--
-- Constraints
--
ALTER TABLE ONLY snp_alignment
    ADD CONSTRAINT snp_alignment_c1 UNIQUE (name);



COMMIT;
