
################################################################
  # name:advanceRetreateGraph
  # this is in my old  files at
  # ~/Dropbox/data/drought/HutchinsonIndex/versions/AdvancRetreatGraph
  # small multiples graph
  source('~/tools/delphe-project/tools/connect2postgres.r')
  ch <- connect2postgres('130.56.102.41','delphe','ivan_hanigan')
  source('~/tools/delphe-project/tools/readOGR2.r')
  require('rgdal')
  source('~/tools/delphe-project/tools/fixGeom.r')
  pwd <-  readline('session password = ')

  #################################################################
  # N:\NCEPH_IT\Data Management\projects\9.999 Ivan's PhD\Papers\Suicide and Drought in NSW\data\drought\load_drought_data.r
  # author:
  # ihanigan
  # date:
  # 2010-08-17
  # description:
  # a project of great importance
  #################################################################

  # changelog
  Sys.Date()
  # 2010-08-17  make the small multiples plot again but for a longer time period, had to change the extract_pgis arguments to work on nceph machine


  #source('i:/my dropbox/tools/transformations.r')
  #library(RODBC)
  #ch=odbcConnect('delphe')
  #source('i:/my dropbox/tools/extract_pgis.r')
  library(maptools)



  qc <- dbGetQuery(ch,"select t2.geoid,SD_code,SD_name,year,month,
    cast(year || '-' || month || '-' || 1 as date) as indexdate,
    avg(t1.sum) as avsum,avg(t1.count) as avcount,
    avg(t1.rain) as avrain,
    case when avg(t1.count) >= 5  then avg(t1.count) else 0 end as threshold
  from bom_grids.rain_NSW_1890_2008_4 as t1 join (
          select abs_sd.nswsd91.gid as geoid,abs_sd.nswsd91.SD_code,abs_sd.nswsd91.SD_name,bom_grids.grid_NSW.*
          from abs_sd.nswsd91, bom_grids.grid_NSW
          where st_intersects(abs_sd.nswsd91.the_geom,bom_grids.grid_NSW.the_geom)
          order by SD_code,bom_grids.grid_NSW.gid
  ) as t2
  on t1.gid=t2.gid
  where year>=1970
  group by t2.geoid,SD_code,SD_name,year,month;")

  head(qc)

  ## sdlist=names(table(qc$sd_name))
  ## sdlist

  ## par(mfrow=c(2,6),mar=c(4,3,3,1))

  ## for(sdi in sdlist){
  ## #sdi=sdlist[1]

  ## with(qc,
  ## plot(indexdate[sd_name==sdi],avcount[sd_name==sdi],type='l',col='red',main=sdi)
  ## )

  ## with(qc,
  ## points(indexdate[sd_name==sdi],threshold[sd_name==sdi])
  ## )
  ## }

  ## qc=sqlQuery(ch,'select t2.geoid,SD_code,SD_name,year,month,avg(t1.sum) as avsum,avg(t1.count) as avcount,avg(t1.rain) as avrain,
  ## case when avg(t1.count) >= 5  then avg(t1.count) else 0 end as threshold
  ## from bom_grids.rain_NSW_1890_2008_4 as t1 join (
  ##         select abs_sd.nswsd91.gid as geoid,abs_sd.nswsd91.SD_code,abs_sd.nswsd91.SD_name,bom_grids.grid_NSW.*
  ##         from abs_sd.nswsd91, bom_grids.grid_NSW
  ##         where st_intersects(abs_sd.nswsd91.the_geom,bom_grids.grid_NSW.the_geom)
  ##         order by SD_code,bom_grids.grid_NSW.gid
  ## ) as t2
  ## on t1.gid=t2.gid
  ## where year>=1970
  ## group by t2.geoid,SD_code,SD_name,year,month;')

  ## # send to local
  ## #local=odbcConnect('ilocal')
  ## #sqlQuery(local,"SET search_path =ivan_hanigan, pg_catalog")
  ## #sqlSave(local,qc,tablename='suicidedroughtnsw19702007_drought')


  ## # make some qc maps
  ## #extract_pgis(psql='select gid, admin_name, st_simplify(the_geom,0.01) as the_geom FROM spatial.admin00_aus_states where admin_name = \'New South Wales\'','nsw.shp',
  ##   #host='130.56.102.30',user='ivan_hanigan',db='delphe',pgpath='C:\\Program Files\\PostgreSQL\\8.3\\bin\\pgsql2shp')

  ## #d=readShapePoly('nsw.shp')
  ## plot(d)
  ## axis(2)
  ## axis(1)
  ## box()

  ## #extract_pgis(psql='select * FROM bom_grids.grid_nsw','grid_nsw.shp')
  ## #grd=readShapePoly('grid_nsw.shp')
  ## plot(grd,add=T)

  ## # check fields
  ## #sqlQuery(ch,'select * FROM bom_grids.grid_nsw limit 1')
  ## #sqlQuery(ch,'select * FROM bom_grids.rain_NSW_1890_2008_4 limit 1')

  ## # get drought data on grid
  ## extract_pgis(psql='select t2.gid,year,month,t1.count,t1.rain,case when t1.count >= 5  then 1 else 0 end as threshold, t2.the_geom from bom_grids.rain_NSW_1890_2008_4 as t1 join bom_grids.grid_NSW as t2 on t1.gid=t2.gid where year=1973 and month = 1 and t1.count >= 5;','197301.shp')

  ## #grd=readShapePoly('197301.shp')
  ## plot(grd,add=T,col=grd@data$THRESHOLD)

  ## # good.  want to reproduce http://www.dpi.nsw.gov.au/agriculture/emergency/drought/planning/climate/advance-retreat
  ## # get the data to local
  ## cat("\"C:\\PostgreSQL\\8.4\\bin\\pg_dump.exe\" -h 130.56.102.30 -U ivan_hanigan -i -t bom_grids.grid_NSW | \"C:\\PostgreSQL\\8.4\\bin\\psql\" -h localhost postgis")

  ## #bom_grids.rain_NSW_1890_2008_4

tassla06 <-
  readOGR2(hostip='115.146.94.209',user='gislibrary',db='pgisdb',
           layer='tassla06')
plot(tassla06)
  #d=readShapePoly('nsw.shp')
  d <- readOGR2('130.56.102.41','ivan_hanigan','delphe','abs_sd.nswsd01', p = pwd)
  plot(d)

  plot_drought=function(year,month){
  extract_pgis(psql=paste('select t2.gid,year,month,t1.count,t1.rain,case when t1.count >= 4  then 1 else 0 end as threshold, t2.the_geom from bom_grids.rain_NSW_1890_2008_4 as t1 join bom_grids.grid_NSW as t2 on t1.gid=t2.gid where year=',year,' and month = ',month,' and t1.count >= 5;',sep=''),'drt.shp',host='130.56.102.30',user='ivan_hanigan',db='delphe',pgpath='C:\\Program Files\\PostgreSQL\\8.3\\bin\\pgsql2shp')
  plot(d)

  if(length(dir(pattern='drt.shp'))>0){
          grd=readShapePoly('drt.shp')
          plot(grd,add=T,col=grd@data$THRESHOLD)
          file.remove('drt.shp')
          file.remove('drt.shx')
          file.remove('drt.dbf')
          file.remove('drt.prj')
          }
  }

  # newnode THE graph
  windows(height=20,width=6)
  Sys.setenv(R_GSCMD="C:\\gs\\gs8.56\\bin\\gswin32c.exe")

  bitmap('droughtAdvRet_19002008.jpg',type='jpeg',res=400,height=20,width=5)
  par(mfrow=c(110,13),mar=c(0,0,0,0))
  plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')

  for(mm in c('j','f','m','a', 'm','j','j','a','s','o','n','d')){
  plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
  text(1.5,1.5,mm)
  }

  for(j in 1900:2008){
  print(j)
           plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
           text(1.5,1.5,j) #substr(j,3,4))

           for(i in 1:12){
           plot_drought(j,i)
           }

  }

  # this is the first one 1972-2008 savePlot('droughtAdvRet.jpg',type=c('jpg'))
  #savePlot('droughtAdvRet_19002008.tiff',type=c('tiff'))
  dev.off()
