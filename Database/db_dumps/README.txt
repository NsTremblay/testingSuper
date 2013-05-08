Genodo PostgresDB Snapshots README
-----------------------------------

Directory contains dumps of the genodo db using the pg_dump tool.

1. genodo_chado_schema.sql
	Base Chado database. Only loaded with ontology data. Contains none of the additional tables created for genodo.

2. genodo.sql
	Current db snapshot. Contains up-to-date schema with all additional tables as well as base data (i.e. ontologies).

3. create_login_tables.sql
	Schema for the login and sessions tables. Additions on top of base.
