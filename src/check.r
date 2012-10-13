
###########################################################################
# newnode: check
  source('~/tools/delphe-project/tools/connect2postgres.r')
  ewedb <- connect2postgres()
  source('~/tools/delphe-project/tools/readOGR2.r')
  require('rgdal')
  source('~/tools/delphe-project/tools/fixGeom.r')
  pwd <-  readline('session password = ')
# ~/Dropbox/data/drought/HutchinsonIndex/versions/2011-04-23/reports/DroughtDSpatial.png

## Professor Mike Hutchinson’s Drought Index integrates six-monthly percentiles beyond a threshold by counting the number of months with the threshold exceeded (or summing the rescaled percentiles such that lower values approach -4 and zero is the median value).  The sequence of steps in the algorithm are shown in the figure by 5 panels.  The third panel shows the threshold below which months are integrated by a solid grey polygon.  The fourth and fifth panes show that when the counts/sums reach a threshold then a drought is declared and when the rainfall measure in the third panel rises above that threshold once more the drought has broken.

## The data in the figure represents the central pixel of the Central West Division of NSW (somewhere close to the town of Parkes) and you can see a few droughts between 1979 and 1983.  Mike questions whether the rain in May to July 1980 was really enough to say the drought had broken.  In discussion with Mike I agreed to explore the spatial and temporal variation in the rescaled percentile

## I started with a graph inspired by the drought maps at want to reproduce .

## The result is:

## So it looks like the drought probably continued right through 1980 until April 1981.

## I had so much fun I thought I’d share the R code and results here.

## I use the gislibrary extract function from:

#source('http://alliance.anu.edu.au/access/content/group/4e0f55f1-b540-456a-000a-24730b59fccb/How_to_wiki_files/ClimateDataChallenge/anu_gislibrary_extract.r')

# But am extracting data from NCEPH’s database so you won’t be able to replicate my analysis.

# first I get all the data as one shapefile per month
setwd('data')
for(year in 1978:1983){
#year <- 1978
      for(month in 1:12){
#month <- 1
      tablename <- paste('Drt',year,month,sep='')
      psql <- paste("select t2.gid,year,month,t1.count,t1.rain,
case when t1.count >= 5  then 1 else 0 end as threshold,
rescaledpctile, t2.the_geom
into ",tablename,"
from bom_grids.rain_NSW_1890_2008_4 as t1
join
(select sds.SD_name,  bom_grids.grid_NSW.gid,
 bom_grids.grid_NSW.the_geom       from (     select elect_div as SD_name,the_geom
                                         as the_geom
                                         from boundaries_electorates.electorates2009     where
                                         elect_div= 'Calare'
                                         ) sds,
 bom_grids.grid_NSW where
 st_intersects(sds.the_geom,
               bom_grids.grid_NSW.the_geom)
 order by SD_name,bom_grids.grid_NSW.gid) as t2 on t1.gid=t2.gid
where year=",year," and month = ",month,";",sep='')
# cat(psql)
dbSendQuery(ewedb, psql)
fixGeom('ivan_hanigan',tablename)
dbSendQuery(ewedb,
paste("
 INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, \"type\")
 SELECT '', 'ivan_hanigan', '",tolower(tablename),"', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
 FROM ivan_hanigan.",tablename," LIMIT 1
", sep ="")
)

      filnam <- paste('Drt',year,month,'.shp',sep='')


      # extract_pgis(psql=psql,filename=filnam,host='yourHostIP',user='yourUsername',db='yourDatabase', pwd = 'yourPassword')
      outshp <- readOGR2('115.146.94.209', 'ivan_hanigan', 'ewedb',
       tolower(tablename), p = pwd)
      writeOGR(outshp, filnam, gsub('.shp', '', filnam),
      "ESRI Shapefile")
      dbSendQuery(ewedb,paste('drop table ', tablename))
      dbSendQuery(ewedb,paste("delete from geometry_columns
       WHERE f_table_name = '",tolower(tablename),"'", sep = "")
      )

     }

}

# then I wrote a function to do the plots (NB the sds spatial object is the Central West Division boundary and is preloaded

plot_drought=function(year,month){
require('RColorBrewer')
filnam <- paste('Drt',year,month,'.shp',sep='')
#d <- load_shp(filnam)
d <- readOGR(dsn=filnam, layer=gsub('.shp','',filnam))
stat = 'rscldpc'
bins <-  c(-4,-3,-2,-1,0,1,2,3,4)
d@data$bins = cut(d@data[,stat], bins, include.lowest=TRUE)
x <- seq(-4, 4, 0.1)
cut(x, bins, include.lowest=TRUE)
level.labels <- c('[-4,-3]', '(-3,-2]', '(-2,-1]', '(-1,0]', '(0,1]', '(1,2]', '(2,3]', '(3,4]')
col.vec = brewer.pal(length(bins),"RdYlBu")
levels(d@data$bins) <- col.vec
plot(d,
      border = FALSE,
      axes = FALSE,
      las = 1,
      col = as.character(d@data$bins)
      )
#plot(sds,  add = T)
}

# start graphing.  Setting up the plot device was challenging but there you go

layout(
matrix(c(1:13,92,
14:(14+12),92,
27:(27+12),92,
40:(40+12),92,
53:(53+12),92,
66:(66+12),92,
79:(79+12),92
),ncol=14, byrow=T)
)

# just check the plots are going to go in the right order
layout.show(92)
par(mar=c(0,0,0,0))
# first a header column to show months
plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
for(mm in toupper(c('j','f','m','a', 'm','j','j','a','s','o','n','d'))){
plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
text(1.5,1.5,mm)
}

# now loop through years and months to plot them

for(j in 1978:1983){
      print(j)
      plot(0:3,0:3,axes=F,ylab='',xlab='',type='n')
      text(1.5,1.5,j) #substr(j,3,4))
      for(i in 1:12){
      plot_drought(j,i)
      }
}

# and finally the legend
level.labels <- c('[-4,-3]', '(-3,-2]', '(-2,-1]', '(-1,0]', '(0,1]',
'(1,2]', '(2,3]', '(3,4]')
bins <-  c(-4,-3,-2,-1,0,1,2,3,4)
col.vec = brewer.pal(length(bins),"RdYlBu")
plot(1,1,type = 'n',axes=F)
legend("top", level.labels, fill=col.vec, title="Legend")
