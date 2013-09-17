BEGIN;

-- Table: raw_virulence_data

-- DROP TABLE raw_virulence_data;

CREATE TABLE raw_virulence_data
(
  serial_id serial NOT NULL,
  genome_id character varying NOT NULL,
  gene_id integer NOT NULL,
  presence_absence integer NOT NULL DEFAULT 0,
  CONSTRAINT raw_virulence_data_pkey PRIMARY KEY (serial_id),
  CONSTRAINT raw_virulence_data_feature_id_fkey FOREIGN KEY (gene_id)
      REFERENCES feature (feature_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_virulence_data
  OWNER TO postgres;


CREATE index raw_virulence_genome_id ON raw_virulence_data
(genome_id);

CREATE index raw_virulence_gene_id ON raw_virulence_data
(gene_id);

COMMIT;

BEGIN;

-- Table: raw_amr_data

-- DROP TABLE raw_amr_data;

CREATE TABLE raw_amr_data
(
  serial_id serial NOT NULL,
  genome_id character varying NOT NULL, -- ID of the genome that constains the current gene
  gene_id integer NOT NULL, -- Is  a foreign key to feature_id the feature tabe
  presence_absence integer NOT NULL DEFAULT 0,
  CONSTRAINT raw_amr_data_pkey PRIMARY KEY (serial_id),
  CONSTRAINT raw_amr_feature_id_fkey FOREIGN KEY (gene_id)
      REFERENCES feature (feature_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT raw_amr_private_feature_id_fkey FOREIGN KEY (gene_id)
      REFERENCES private_feature (feature_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE raw_amr_data
  OWNER TO postgres;
COMMENT ON COLUMN raw_amr_data.genome_id IS 'ID of the genome that constains the current gene';
COMMENT ON COLUMN raw_amr_data.gene_id IS 'Is  a foreign key to feature_id the feature tabe';

CREATE index raw_amr_genome_id ON raw_amr_data
(genome_id);

CREATE index raw_amr_gene_id ON raw_amr_data
(gene_id);

COMMIT;

BEGIN;

-- Table: loci

-- DROP TABLE loci;

CREATE TABLE loci
(
  locus_id serial NOT NULL, -- Serial ID (integer) generated for each locus
  locus_name character varying NOT NULL, -- Locus name (can contain both char and int)
  CONSTRAINT loci_pkey PRIMARY KEY (locus_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE loci
  OWNER TO postgres;
COMMENT ON TABLE loci
  IS 'Stores the names and, in the future, other info (accession, location, other properties) of loci used to compare groups of strains.';
COMMENT ON COLUMN loci.locus_id IS 'Serial ID (integer) generated for each locus';
COMMENT ON COLUMN loci.locus_name IS 'Locus name (can contain both char and int)';

COMMIT;

BEGIN;

-- Table: loci_genotypes

-- DROP TABLE loci_genotypes;

CREATE TABLE loci_genotypes
(
  locus_genotype_id serial NOT NULL,
  feature_id character varying NOT NULL, -- Strain ID
  locus_id integer NOT NULL, -- Stores a locus ID from the loci table
  locus_genotype integer NOT NULL DEFAULT 0, -- Presence absence value for each locus for each strain. Will have a value either 0 or 1. Default is 0.
  CONSTRAINT loci_genotypes_pkey PRIMARY KEY (locus_genotype_id),
  CONSTRAINT locus_id_fkey FOREIGN KEY (locus_id)
      REFERENCES loci (locus_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE loci_genotypes
  OWNER TO postgres;
COMMENT ON TABLE loci_genotypes
  IS 'Presence absence values for each locus for each strain ';
COMMENT ON COLUMN loci_genotypes.feature_id IS 'Strain ID';
COMMENT ON COLUMN loci_genotypes.locus_id IS 'Stores a locus ID from the loci table';
COMMENT ON COLUMN loci_genotypes.locus_genotype IS 'Presence absence value for each locus for each strain. Will have a value either 0 or 1. Default is 0.';

-- Index: loci_genotypes_idx2

-- DROP INDEX loci_genotypes_idx2;

CREATE INDEX loci_genotypes_idx2
  ON loci_genotypes
  USING btree
  (locus_id);

COMMIT;

BEGIN;

-- Table: snps

-- DROP TABLE snps;

CREATE TABLE snps
(
  snp_id serial NOT NULL, -- Serial ID generated for each snp
  snp_name character varying NOT NULL, -- Snp name (can contain both char and int)
  CONSTRAINT snp_pkey PRIMARY KEY (snp_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE snps
  OWNER TO postgres;
COMMENT ON TABLE snps
  IS 'Stores the names and, in the future, other info (accession, location, other properties) of snps used to compare groups of strains.';
COMMENT ON COLUMN snps.snp_id IS 'Serial ID generated for each snp';
COMMENT ON COLUMN snps.snp_name IS 'Snp name (can contain both char and int)';

COMMIT;

BEGIN;

-- Table: snps_genotypes

-- DROP TABLE snps_genotypes;

CREATE TABLE snps_genotypes
(
  snp_genotype_id serial NOT NULL,
  feature_id character varying NOT NULL, --StrainID
  snp_id integer NOT NULL, -- Stores a snp ID from the snps table
  snp_a integer NOT NULL DEFAULT 0, -- Presence absence value for base "A" for each locus for each strain. Default is 0.
  snp_t integer NOT NULL DEFAULT 0, -- Presence absence value for base "T" for each locus for each strain. Default is 0.
  snp_c integer NOT NULL DEFAULT 0, -- Presence absence value for base "C" for each locus for each strain. Default is 0.
  snp_g integer NOT NULL DEFAULT 0, -- Presence absence value for base "G" for each locus for each strain. Default is 0.
  CONSTRAINT snp_genotypes_pkey PRIMARY KEY (snp_genotype_id),
  CONSTRAINT snp_genotypes_snp_id FOREIGN KEY (snp_id)
      REFERENCES snps (snp_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE snps_genotypes
  OWNER TO postgres;
COMMENT ON TABLE snps_genotypes
  IS 'Presence absence values for each snp for each strain';
COMMENT ON COLUMN snps_genotypes.feature_id IS 'Strain ID';
COMMENT ON COLUMN snps_genotypes.snp_id IS 'Stores a snp ID from the snps table';
COMMENT ON COLUMN snps_genotypes.snp_a IS 'Presence absence value for base "A" for each locus for each strain. Default is 0.';
COMMENT ON COLUMN snps_genotypes.snp_t IS 'Presence absence value for base "T" for each locus for each strain. Default is 0.';
COMMENT ON COLUMN snps_genotypes.snp_c IS 'Presence absence value for base "C" for each locus for each strain. Default is 0.';
COMMENT ON COLUMN snps_genotypes.snp_g IS 'Presence absence value for base "G" for each locus for each strain. Default is 0.';


-- Index: snps_genotypes_idx2

-- DROP INDEX snps_genotypes_idx2;

CREATE INDEX snps_genotypes_idx2
  ON snps_genotypes
  USING btree
  (snp_id);

COMMIT;



