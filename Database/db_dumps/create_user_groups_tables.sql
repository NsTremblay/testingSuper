BEGIN;

-- Table: user_groups

-- DROP TABLE user_groups;

CREATE TABLE user_groups
(
  user_group_id serial NOT NULL,
  username character varying(20) NOT NULL,
  last_modified timestamp without time zone NOT NULL,
  user_groups text,
  CONSTRAINT user_groups_pkey PRIMARY KEY (user_group_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE user_groups
  OWNER TO postgres;
COMMENT ON TABLE user_groups
  IS 'Saves user defined groups and group collections from shiny app in JSON format';

COMMIT;
