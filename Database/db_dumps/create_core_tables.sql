BEGIN;

--
-- SQL for creating additional table for storing core pangenome presence / absence strings
--

SET search_path = public, pg_catalog;
SET default_tablespace = '';


-----------------------------------------------------------------------------
--
-- Table Name: core_region; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE core_region (
	core_region_id         integer NOT NULL,
	pangenome_region_id    integer NOT NULL,
	aln_column             integer NOT NULL DEFAULT 0
);

ALTER TABLE public.core_region OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE core_region_core_region_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.core_region_core_region_id_seq OWNER TO postgres;

ALTER SEQUENCE core_region_core_region_id_seq OWNED BY core_region.core_region_id;

ALTER TABLE ONLY core_region ALTER COLUMN core_region_id SET DEFAULT nextval('core_region_core_region_id_seq'::regclass);

ALTER TABLE ONLY core_region
	ADD CONSTRAINT core_region_pkey PRIMARY KEY (core_region_id);

--
-- foreign keys
--
ALTER TABLE ONLY core_region
	ADD CONSTRAINT core_region_pangenome_region_id_fkey FOREIGN KEY (pangenome_region_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Constraints
--
ALTER TABLE ONLY core_region
    ADD CONSTRAINT core_region_c1 UNIQUE (pangenome_region_id);

ALTER TABLE ONLY core_region
    ADD CONSTRAINT core_region_c2 UNIQUE (aln_column);


--
-- Indices
--


-----------------------------------------------------------------------------
--
-- Table Name: core_alignment; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE core_alignment (
	core_alignment_id integer NOT NULL,
	name character varying(100),
	aln_column integer NOT NULL,
	alignment text
);

ALTER TABLE public.core_alignment OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE core_alignment_core_alignment_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.core_alignment_core_alignment_id_seq OWNER TO postgres;

ALTER SEQUENCE core_alignment_core_alignment_id_seq OWNED BY core_alignment.core_alignment_id;

ALTER TABLE ONLY core_alignment ALTER COLUMN core_alignment_id SET DEFAULT nextval('core_alignment_core_alignment_id_seq'::regclass);

ALTER TABLE ONLY core_alignment
	ADD CONSTRAINT core_alignment_pkey PRIMARY KEY (core_alignment_id);


--
-- Constraints
--
ALTER TABLE ONLY core_alignment
    ADD CONSTRAINT core_alignment_c1 UNIQUE (name);


COMMIT;


