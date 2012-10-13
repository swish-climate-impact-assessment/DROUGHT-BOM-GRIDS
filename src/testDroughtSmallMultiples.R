
################################################################
# name:testDroughtSmallMultiples
source('~/tools/delphe-project/tools/connect2postgres.r')
pwd <-  readline('session password = ')
ch <- connect2postgres('130.56.102.41','delphe','ivan_hanigan',p=pwd)
ewedb <- connect2postgres('115.146.94.209','ewedb','ivan_hanigan',p=pwd)
source('~/tools/delphe-project/tools/readOGR2.r')
require('rgdal')
source('~/tools/delphe-project/tools/fixGeom.r')


d <- readOGR2('130.56.102.41','ivan_hanigan','delphe','abs_sd.nswsd01', p = pwd)
plot(d)
for(year in 1970:1980){
#year <- 1972
  for(month in 1:12){
  #  month <- 12
  psql=paste('select t2.gid,year,month,t1.count,t1.rain,
   case when t1.count >= 4  then 1 else 0 end as threshold,
   t2.the_geom
   into tempdrt',year,month,'
             from bom_grids.rain_NSW_1890_2008_4 as t1
             join bom_grids.grid_NSW as t2
             on t1.gid=t2.gid
             where year=',year,' and month = ',month,' and t1.count >= 5;
             alter table tempdrt',year,month,' add column gid2 serial primary key;
             ',sep='')
  dbSendQuery(ewedb, psql)

  #fixGeom(schema='ivan_hanigan',table=paste('tempdrt',year,month,sep=''))
  dbSendQuery(ewedb,
  #cat(
  paste("
   INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, \"type\")
   SELECT '', 'ivan_hanigan', 'tempdrt",year,month,"', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
   FROM ivan_hanigan.tempdrt",year,month," LIMIT 1;
              ",sep=""))
  }
}

shp <- readOGR2('115.146.94.209','ivan_hanigan','ewedb',paste('tempdrt',year,month,sep=''), p = pwd)
plot(d)
plot(shp,add=T, col='black')

dbSendQuery(ewedb,
            paste('drop table tempdrt',year,month,sep='')
            )
