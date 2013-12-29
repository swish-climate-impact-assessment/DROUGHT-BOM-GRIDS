
###########################################################################
# newnode: prepare ewedb

psql -h 115.146.94.209 -d ewedb -U postgres
CREATE ROLE public_group;
CREATE SCHEMA bom_grids;
grant usage on schema bom_grids to public_group;
CREATE ROLE ivan_hanigan LOGIN PASSWORD 'XXXX';
GRANT ALL ON SCHEMA bom_grids to ivan_hanigan;
\q
# add to pg_hba
reload
select pg_reload_conf();
