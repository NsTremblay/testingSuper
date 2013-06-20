BEGIN;

--
-- SQL for creating additional tables for hosts and associated sources
--

SET search_path = public, pg_catalog;
SET default_tablespace = '';


-----------------------------------------------------------------------------
--
-- Table Name: upload; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TYPE upload_type AS ENUM ('public','release','private','undefined');

CREATE TABLE upload (
	upload_id        integer NOT NULL,
	login_id         integer NOT NULL DEFAULT 0,
	tag              varchar(50) NOT NULL DEFAULT '',
	release_date     DATE NOT NULL DEFAULT 'infinity'::timestamp,
	category         upload_type NOT NULL DEFAULT 'undefined',
	upload_date      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.upload OWNER TO postgres;

--
-- primary key
--
CREATE SEQUENCE upload_upload_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE public.upload_upload_id_seq OWNER TO postgres;

ALTER SEQUENCE upload_upload_id_seq OWNED BY upload.upload_id;

ALTER TABLE ONLY upload ALTER COLUMN upload_id SET DEFAULT nextval('upload_upload_id_seq'::regclass);

ALTER TABLE ONLY upload
	ADD CONSTRAINT upload_pkey PRIMARY KEY (upload_id);

--
-- foreign keys
--
ALTER TABLE ONLY upload
	ADD CONSTRAINT upload_login_id_fkey FOREIGN KEY (login_id) REFERENCES login(login_id);

COMMENT ON CONSTRAINT upload_login_id_fkey ON upload IS 'Cannot delete user if they have upload entries remaining in upload table.';

--
-- Indices 
--
CREATE INDEX upload_idx1 ON upload USING btree (login_id);


