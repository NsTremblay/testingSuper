BEGIN;

COPY loci (locus_id, locus_name) FROM '/home/amanji/repos/computational_platform/Data/binary_processed_names.txt';

COMMIT;

BEGIN;

COPY loci_genotypes (feature_id, locus_id, locus_genotype) FROM '/home/amanji/repos/computational_platform/Data/binary_processed_data.txt';

COMMIT;
