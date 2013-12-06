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
	pangenome_region integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n',
	position         integer NOT NULL DEFAULT -1,
	gap_offset       integer NOT NULL DEFAULT 0,
	aln_block        integer NOT NULL DEFAULT 0,
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
	ADD CONSTRAINT snp_core_pangenome_region_fkey FOREIGN KEY (pangenome_region) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Constraints
--
ALTER TABLE ONLY snp_core
    ADD CONSTRAINT snp_core_c1 UNIQUE (pangenome_region, position, gap_offset);

ALTER TABLE ONLY snp_core
    ADD CONSTRAINT snp_core_c2 UNIQUE (aln_block, aln_column);


--
-- Indices
--


-----------------------------------------------------------------------------
--
-- Table Name: snp_variation; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE snp_variation (
	snp_variation_id integer NOT NULL,
	snp              integer NOT NULL,
	contig_collection integer NOT NULL,
	contig           integer NOT NULL,
	locus            integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n',
	position         integer NOT NULL DEFAULT -1,
	gap_offset       integer NOT NULL DEFAULT 0
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
	ADD CONSTRAINT snp_variation_snp_fkey FOREIGN KEY (snp) REFERENCES snp_core(snp_core_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_contig_collection_fkey FOREIGN KEY (contig_collection) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_contig_fkey FOREIGN KEY (contig) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY snp_variation
	ADD CONSTRAINT snp_variation_locus_fkey FOREIGN KEY (locus) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Constraints
--  
ALTER TABLE ONLY snp_variation
    ADD CONSTRAINT snp_variation_c1 UNIQUE (snp, contig_collection);

--
-- Indices
--
CREATE INDEX snp_variation_idx1 ON snp_variation USING btree (snp);

CREATE INDEX snp_variation_idx2 ON snp_variation USING btree (contig_collection);



-----------------------------------------------------------------------------
--
-- Table Name: private_snp_variation; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE private_snp_variation (
	snp_variation_id integer NOT NULL,
	snp              integer NOT NULL,
	contig_collection integer NOT NULL,
	contig           integer NOT NULL,
	locus            integer NOT NULL,
	allele           char(1) NOT NULL DEFAULT 'n',
	position         integer NOT NULL DEFAULT -1,
	gap_offset       integer NOT NULL DEFAULT 0
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
	ADD CONSTRAINT private_snp_variation_snp_fkey FOREIGN KEY (snp) REFERENCES snp_core(snp_core_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_contig_collection_fkey FOREIGN KEY (contig_collection) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_contig_fkey FOREIGN KEY (contig) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY private_snp_variation
	ADD CONSTRAINT private_snp_variation_locus_fkey FOREIGN KEY (locus) REFERENCES private_feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Constraints
--
ALTER TABLE ONLY private_snp_variation
    ADD CONSTRAINT private_snp_variation_c1 UNIQUE (snp, contig_collection);

--
-- Indices
--
CREATE INDEX private_snp_variation_idx1 ON private_snp_variation USING btree (snp);

CREATE INDEX private_snp_variation_idx2 ON private_snp_variation USING btree (contig_collection);


COMMIT;
