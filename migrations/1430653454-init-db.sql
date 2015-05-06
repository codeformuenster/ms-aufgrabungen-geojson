-- ====  UP  ====
BEGIN;

SET client_encoding = 'UTF8';

--
-- Enable postgis
--
CREATE EXTENSION postgis;

--
-- create a table into which ogr2ogr can insert
--

CREATE TABLE do_not_insert_aufbrueche (
    ogc_fid integer NOT NULL,
    wkb_geometry geometry(Polygon,4326),
    id double precision,
    vtraeger character varying(100),
    strassen character varying(226),
    spuren character varying(135),
    beginn character varying(10)
);
ALTER TABLE do_not_insert_aufbrueche OWNER TO postgres;
CREATE SEQUENCE aufbrueche_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE aufbrueche_ogc_fid_seq OWNER TO postgres;
ALTER SEQUENCE aufbrueche_ogc_fid_seq OWNED BY do_not_insert_aufbrueche.ogc_fid;
ALTER TABLE ONLY do_not_insert_aufbrueche ALTER COLUMN ogc_fid SET DEFAULT nextval('aufbrueche_ogc_fid_seq'::regclass);
ALTER TABLE ONLY do_not_insert_aufbrueche ADD CONSTRAINT aufbrueche_pkey PRIMARY KEY (ogc_fid);
CREATE INDEX aufbrueche_geom_idx ON do_not_insert_aufbrueche USING gist (wkb_geometry);

--
-- create a table in which the data is actually stored in
--

CREATE TABLE aufgrabungen (
  id integer PRIMARY KEY,
  vtraeger varchar(255),
  strassen varchar(255),
  spuren varchar(255),
  beginn date,
  created_at timestamp,
  updated_at timestamp
);
SELECT AddGeometryColumn('aufgrabungen', 'the_geom', 4326, 'POLYGON', 2);
CREATE INDEX geom_index ON aufgrabungen USING GIST (the_geom);
ALTER TABLE aufgrabungen ADD CONSTRAINT id_geom_unique UNIQUE (the_geom, id);

--
-- create a view on the ogr2ogr table (do_not_insert_aufbrueche)
--

CREATE VIEW aufbrueche AS SELECT * FROM do_not_insert_aufbrueche;

--
-- create a procedure and trigger to insert the data into the acutual table
--

CREATE OR REPLACE FUNCTION transform_and_insert() RETURNS TRIGGER AS $transform_and_insert$
BEGIN
  SET datestyle = 'ISO, DMY';

  UPDATE "aufgrabungen" SET the_geom=NEW.wkb_geometry, vtraeger = NEW.vtraeger, strassen = NEW.strassen, spuren = NEW.spuren, beginn = NEW.beginn::date, updated_at = current_timestamp WHERE id = NEW.id AND (SELECT NOT ST_EQUALS(the_geom, NEW.wkb_geometry)) AND vtraeger <> NEW.vtraeger AND strassen <> NEW.strassen AND spuren <> NEW.spuren AND beginn <> NEW.beginn::date;

  INSERT INTO "aufgrabungen" ("the_geom" , "id", "vtraeger", "strassen", "spuren", "beginn", "created_at", "updated_at") SELECT NEW.wkb_geometry, NEW.id, NEW.vtraeger, NEW.strassen, NEW.spuren, NEW.beginn::date, current_timestamp, current_timestamp WHERE NOT EXISTS (SELECT 1 FROM "aufgrabungen" WHERE id = NEW.id AND the_geom = NEW.wkb_geometry AND vtraeger = NEW.vtraeger AND strassen = NEW.strassen AND spuren = NEW.spuren AND beginn = NEW.beginn::date);

  RETURN NEW;
END;
$transform_and_insert$ LANGUAGE plpgsql;

CREATE TRIGGER transform_and_insert_trig INSTEAD OF INSERT ON aufbrueche FOR EACH ROW EXECUTE PROCEDURE transform_and_insert();


--
-- create schema postgrest operates on
--
CREATE SCHEMA "1";

--
-- create view for postgrest
--

CREATE OR REPLACE VIEW "1".aufgrabungen_polygon AS
SELECT * FROM (SELECT
   'Feature'::text AS type,
   ST_AsGeoJSON(lg.the_geom, 6)::json As geometry,
   row_to_json((SELECT l FROM (SELECT
      id,
      vtraeger,
      strassen,
      spuren,
      beginn,
      created_at,
      updated_at) As l
      )) As properties
   FROM "public".aufgrabungen AS lg) AS f;

CREATE OR REPLACE VIEW "1".aufgrabungen AS
SELECT * FROM "1".aufgrabungen_polygon;

CREATE OR REPLACE VIEW "1".aufgrabungen_point AS
SELECT * FROM (SELECT
   'Feature'::text AS type,
   ST_AsGeoJSON(ST_Centroid(lg.the_geom), 6)::json As geometry,
   row_to_json((SELECT l FROM (SELECT
      id,
      vtraeger,
      strassen,
      spuren,
      beginn,
      created_at,
      updated_at) As l
      )) As properties
   FROM "public".aufgrabungen AS lg) AS f;

CREATE OR REPLACE VIEW "1".attribution AS
SELECT
'Tiefbauamt der Stadt Münster, http://www.muenster.de/stadt/tiefbauamt/' as data_provider,
'https://www.govdata.de/web/guest/daten/-/details/aufgrabungsmeldung-stadt-munster'::text as source,
'Datenlizenz Deutschland Namensnennung dl-de-by-1.0 http://www.daten-deutschland.de/bibliothek/Datenlizenz_Deutschland/dl-de-by-1.0'::text as license,
'This is an automated shapefile to postgis to geojson service of the open data "Aufgrabungsmeldung Stadt Münster" by the Tiefbauamt Münster which is only provided as a zipped shapefile download. It is an attempt to provide a better way to interact with the data. If you use this, always attribute the source of the data from govdata.de. For more information please look at the sourcecode at https://github.com/ubergesundheit/ms-aufgrabungen-geojson This is a project of Code for Münster (https://codeformuenster.org)'::text as info;

--
-- create user for postgrest
--

CREATE ROLE anon NOLOGIN;
GRANT USAGE ON SCHEMA "1" TO anon;
GRANT SELECT ON "1".aufgrabungen TO anon;
GRANT SELECT ON "1".aufgrabungen_polygon TO anon;
GRANT SELECT ON "1".aufgrabungen_point TO anon;
GRANT SELECT ON "1".attribution TO anon;

COMMIT;

-- ==== DOWN ====
-- probably never used.. we only migrate up
