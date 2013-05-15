create view genome_names as select feature_id, name, uniquename, type_id from feature where type_id = 1542;

create view private_genome_names as select feature_id, name, uniquename, type_id, upload_id from private_feature where type_id = 1542;
