
BEGIN;

-- Table: raw_amr_data

-- DROP TABLE raw_amr_data;

CREATE TABLE raw_amr_data
(
  serial_id serial NOT NULL,
  strain text,
  gene_name text,
  presence_absence text,
  CONSTRAINT raw_amr_data_pkey PRIMARY KEY (serial_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_amr_data
  OWNER TO postgres;

CREATE index raw_amr_strain ON raw_amr_data
(strain);

CREATE index raw_amr_gene ON raw_amr_data
(gene_name);

COMMIT;

BEGIN;

-- Table: raw_binary_data

-- DROP TABLE raw_binary_data;

CREATE TABLE raw_binary_data
(
  serial_id serial NOT NULL,
  strain text,
  locus_name text,
  presence_absence text,
  CONSTRAINT raw_binary_data_pkey PRIMARY KEY (serial_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_binary_data
  OWNER TO postgres;

CREATE index raw_binary_strain ON raw_binary_data
(strain);

CREATE index raw_binary_locus ON raw_binary_data
(locus_name);

COMMIT;

BEGIN;

-- Table: raw_snp_data

-- DROP TABLE raw_snp_data;

CREATE TABLE raw_snp_data
(
  serial_id serial NOT NULL,
  strain text,
  locus_name text,
  snp text,
  CONSTRAINT raw_snp_data_pkey PRIMARY KEY (serial_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_snp_data
  OWNER TO postgres;


CREATE index raw_snp_strain ON raw_snp_data
(strain);

CREATE index raw_snp_locus ON raw_snp_data
(locus_name);

COMMIT;

BEGIN;

-- Table: raw_virulence_data

-- DROP TABLE raw_virulence_data;

CREATE TABLE raw_virulence_data
(
  serial_id serial NOT NULL,
  strain text,
  gene_name text,
  presence_absence text,
  CONSTRAINT raw_virulence_data_pkey PRIMARY KEY (serial_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_virulence_data
  OWNER TO postgres;

CREATE index raw_virulence_strain ON raw_virulence_data
(strain);

CREATE index raw_virulence_locus ON raw_virulence_data
(gene_name);

COMMIT;

BEGIN;

-- Table: data_loci_names

-- DROP TABLE data_loci_names;

CREATE TABLE data_loci_names
(
  serial_id serial NOT NULL,
  locus_name varchar(50),
  CONSTRAINT data_loci_names_pkey PRIMARY KEY (serial_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE data_loci_names
  OWNER TO postgres;

CREATE index locus_name ON data_loci_names
(locus_name);

COMMIT;

