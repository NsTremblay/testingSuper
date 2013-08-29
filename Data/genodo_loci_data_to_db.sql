BEGIN;

COPY :nametable (:nametablecolid, :nametablecolname) FROM :outnamefile;

COMMIT;

BEGIN;

COPY :datatable (:datatablefeatureid, :datatablecolid, :datatablegenotype) FROM :outdatafile;

COMMIT;
