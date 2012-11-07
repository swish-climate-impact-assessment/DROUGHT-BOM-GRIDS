
################################################################
  # name:testDroughtSmallMultiples
  source('~/tools/delphe-project/tools/connect2postgres.r')
  pwd <-  readline('session password = ')
  ch <- connect2postgres('130.56.102.41','delphe','ivan_hanigan',p=pwd)
  ewedb <- connect2postgres('115.146.94.209','ewedb','ivan_hanigan',p=pwd)
  source('~/tools/delphe-project/tools/readOGR2.r')
  require('rgdal')
  source('~/tools/delphe-project/tools/fixGeom.r')

d <- readOGR2('130.56.102.41','ivan_hanigan','delphe','spatial.admin00_aus_states', p = pwd)
d <- d[d@data$admin_name == 'New South Wales',]
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





# going to want to do a straight copy and an enhanced version with
# continuous levels?  not yet
dir.create('data')
setwd('data')
for(j in 1970:1980){
#j <- 1970
  print(j)
    year <- j

             for(i in 1:12){
#i <- 1
               month <- i
               try(shp <- readOGR2('115.146.94.209','ivan_hanigan','ewedb',paste('tempdrt',year,month,sep=''),
               p = pwd)
               )
               if(exists('shp')) {writeOGR(shp,
               paste('tempdrt',year,month,'.shp',sep=''), layer =
               paste('tempdrt',year,month,sep=''), 'ESRI Shapefile')
                                }
# plot(shp,add=T, col='black')
               #plot_drought(j,i)
             }

    }

  png('../droughtAdvRet_19722008.png',res=150,height=2000,width=1000)
  par(mfrow=c(41,13),mar=c(0,0,0,0))
  plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')

  for(mm in toupper(c('j','f','m','a', 'm','j','j','a','s','o','n','d'))){
    plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
    text(1.5,1.5,mm)
    }

    for(j in 1972:2011){
    print(j)
    year <- j
             plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
             text(1.5,1.5,j) #substr(j,3,4))

             for(i in 1:12){
               plot(d)
               month <- i

             try(shp <- readOGR(paste('tempdrt',year,month,'.shp',sep=''),paste('tempdrt',year,month,sep='')
             )
             )
             if(exists('shp')) { plot(shp,add=T, col='black')}
             rm(shp)
             }

    }

    # this is the first one 1972-2008 savePlot('droughtAdvRet.jpg',type=c('jpg'))
    #savePlot('droughtAdvRet_19002008.tiff',type=c('tiff'))
    dev.off()

  dbSendQuery(ewedb,
              paste('drop table tempdrt',year,month,sep='')
              )
