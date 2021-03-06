
###########################################################################
# newnode: dump and restore
#/usr/bin/pg_dump --host 130.56.102.41 --port 5432 --username "ivan_hanigan" --role "ivan_hanigan" --no-password  --format plain --encoding UTF8 --verbose --file "/home/ivan_hanigan/projects/DROUGHT-BOM-GRIDS/data/bom_grids.rain_nsw_1890_2008_4.backup" --table "bom_grids.rain_nsw_1890_2008_4" "delphe"


#pg_dump -h 130.56.102.41 -p 5432 -U ivan_hanigan -F t -v -i -f "/home/ivan_hanigan/projects/DROUGHT-BOM-GRIDS/data/bom_grids.rain_nsw_1890_2008_4.backup" -t \"bom_grids\".\"rain_nsw_1890_2008_4\" delphe
#cd /home/ivan_hanigan/projects/DROUGHT-BOM-GRIDS/data/
#psql -h 115.146.95.82 -d ewedb -U postgres < "bom_grids.rain_nsw_1890_2008_4.backup"

pg_dump -h 130.56.102.41 -p 5432 -U ivan_hanigan -i -t \"bom_grids\".\"grid_aus\" delphe | psql -h 115.146.95.82 -U postgres ewedb
pg_dump -h 130.56.102.41 -p 5432 -U ivan_hanigan -i -t \"bom_grids\".\"grid_nsw\" delphe | psql -h 115.146.95.82 -U postgres ewedb

#in pgadmin
CREATE TABLE bom_grids.rain_aus_1890_2008_4
(
  gid integer NOT NULL,
  timeid integer NOT NULL,
  year integer,
  month integer,
  rain double precision,
  rain6mo double precision,
  pctile double precision,
  rescaledpctile double precision,
  indexbelowthreshold double precision,
  sum double precision,
  count integer,
  CONSTRAINT r_aus_pk PRIMARY KEY (gid , timeid )
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bom_grids.rain_aus_1890_2008_4
  OWNER TO postgres;
GRANT ALL ON TABLE bom_grids.rain_aus_1890_2008_4 TO postgres;
GRANT ALL ON TABLE bom_grids.rain_aus_1890_2008_4 TO public_group;



pg_dump -h 130.56.102.41 -p 5432 -U ivan_hanigan -i -t \"bom_grids\".\"rain_nsw_1890_2008_4\" delphe | psql -h 115.146.95.82 -U postgres ewedb
