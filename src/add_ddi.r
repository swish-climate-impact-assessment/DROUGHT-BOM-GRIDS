
################################################################
# name:add_ddi
setwd('~/projects/DROUGHT-BOM-GRIDS')
source('~/projects/disentangle/src/df2ddi.r')
source('~/projects/disentangle/src/connect2postgres.r')
ewedb <- connect2postgres()
if(!require(rgdal)) install.packages('rgdal'); require(rgdal)
if(!require(RJDBC)) install.packages('RJDBC'); require(RJDBC)
connect2oracle <- function(){
if(!require(RJDBC)) install.packages('RJDBC'); require(RJDBC)
drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            '/u01/app/oracle/product/11.2.0/xe/jdbc/lib/ojdbc6.jar')
p <- readline('enter password: ')
h <- readline('enter target ipaddres: ')
d <- readline('enter database name: ')
ch <- dbConnect(drv,paste("jdbc:oracle:thin:@",h,":1521",sep=''),d,p)
return(ch)
}
ch <- connect2oracle()

#dir.create('metadata')
#s <- dbGetQuery(ch, "select * from stdydscr where IDNO = 'DROUGHTBOMGRIDS'")
s <- add_stdydscr(ask=T)
#write.table(s,'metadata/stdydscr.csv',sep=',',row.names=F)

s$PRODDATESTDY=format(as.Date( substr(s$PRODDATESTDY,1,10),'%Y-%m-%d'),"%d/%b/%Y")
s$PRODDATEDOC=format(as.Date( substr(s$PRODDATEDOC,1,10),'%Y-%m-%d'),"%d/%b/%Y")

dbSendUpdate(ch,
# cat(
paste('
insert into STDYDSCR (',paste(names(s), sep = '', collapse = ', '),')
VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(s),'',s)),sep='',collapse="', '"),"'",sep=''),')',sep='')
)

f <- add_filedscr(fileid = 1, idno = 'DROUGHTBOMGRIDS', ask=T)
f$FILELOCATION <- 'bom_grids'
#f$IDNO <- 'DROUGHTBOMGRIDS'
dbSendUpdate(ch,
# cat(
paste('
insert into FILEDSCR (',paste(names(f), sep = '', collapse = ', '),')
VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(f),'',f)),sep='',collapse="', '"),"'",sep=''),')',sep='')
)

#setwd('../data')
#setwd('abs_sla')
#test <- readOGR(dsn = 'tassla06.shp', layer = 'tassla06')
fid <- dbGetQuery(ch,
#                  cat(
                  paste("select FILEID
                  from filedscr
                  where filelocation = '",f$FILELOCATION,"'
                  and filename = '",f$FILENAME,"'",
                  sep=''))

df <- dbGetQuery(ewedb,
                 'select * from bom_grids.rain_nsw_1890_2008_4 limit 1'
                 )
df
d <- add_datadscr(data_frame = df, fileid = fid[1,1], ask=T)


for(i in 1:nrow(d)){
dbSendUpdate(ch,
#i = 1
# cat(
paste('
insert into DATADSCR (',paste(names(d), sep = '', collapse = ', '),')
VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(d[i,]),'',d[i,])),sep='',collapse="', '"),"'",sep=''),')',sep='')
)
}


###################################################
# make xml
s <- dbGetQuery(ch, "select * from stdydscr where idno = 'DROUGHTBOMGRIDS'")
s
f <- dbGetQuery(ch, "select * from filedscr where idno = 'DROUGHTBOMGRIDS'")
f
for(fi in f){
d <- dbGetQuery(ch,
                paste("select * from datadscr where FILEID = ",f$FILEID,
                      sep = '')
                )
d
ddixml <- make_xml(s,f,d)
}
out <- dir(pattern='xml')
file.remove(file.path('/xmldata', out))
file.copy(out, '/xmldata')

################################################################
# name:add_ddi
source('~/disentangle/src/df2ddi.r')
source('~/disentangle/src/connect2postgres.r')
ewedb <- connect2postgres()
if(!require(rgdal)) install.packages('rgdal'); require(rgdal)
if(!require(RJDBC)) install.packages('RJDBC'); require(RJDBC)
drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            '/u01/app/oracle/product/11.2.0/xe/jdbc/lib/ojdbc6.jar')
p <- readline('enter password: ')
h <- readline('enter target ipaddres: ')
d <- readline('enter database name: ')
ch <- dbConnect(drv,paste("jdbc:oracle:thin:@",h,":1521",sep=''),d,p)

#dir.create('metadata')
s <- dbGetQuery(ch, "select * from stdydscr where IDNO = 'BOUNDARIES_ELECTORATES'")
# s <- add_stdydscr(ask=T)
#write.table(s,'metadata/stdydscr.csv',sep=',',row.names=F)

s$PRODDATESTDY=format(as.Date( substr(s$PRODDATESTDY,1,10),'%Y-%m-%d'),"%d/%b/%Y")
s$PRODDATEDOC=format(as.Date( substr(s$PRODDATEDOC,1,10),'%Y-%m-%d'),"%d/%b/%Y")

## dbSendUpdate(ch,
## # cat(
## paste('
## insert into STDYDSCR (',paste(names(s), sep = '', collapse = ', '),')
## VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(s),'',s)),sep='',collapse="', '"),"'",sep=''),')',sep='')
## )

f <- add_filedscr(fileid = 1, idno = 'BOUNDARIES_ELECTORATES', ask=T)
f$FILELOCATION <- 'BOUNDARIES_ELECTORATES'

dbSendUpdate(ch,
# cat(
paste('
insert into FILEDSCR (',paste(names(f), sep = '', collapse = ', '),')
VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(f),'',f)),sep='',collapse="', '"),"'",sep=''),')',sep='')
)
f <- dbGetQuery(ch, "select * from filedscr where IDNO = 'BOUNDARIES_ELECTORATES'")
f

fid <- dbGetQuery(ch,
#                  cat(
                  paste("select FILEID
                  from filedscr
                  where filelocation = '",f$FILELOCATION,"'
                  and filename = '",f$FILENAME,"'",
                  sep=''))

df <- dbGetQuery(ewedb,
                 'select elect_div, state from boundaries_electorates.electorates2009 limit 1'
                 )
df[1,]
df <- readOGR2(hostip = '115.146.94.209', user = 'steven_mceachern',
                 db = 'ewedb', layer =
                 'boundaries_electorates.electorates2009')
df@data[1:10,]
d <- add_datadscr(data_frame = df, fileid = fid[1,1], ask=T)
d

for(i in 1:nrow(d)){
dbSendUpdate(ch,
#i = 1
# cat(
paste('
insert into DATADSCR (',paste(names(d), sep = '', collapse = ', '),')
VALUES (',paste("'",paste(gsub("'","",ifelse(is.na(d[i,]),'',d[i,])),sep='',collapse="', '"),"'",sep=''),')',sep='')
)
}


###################################################
# make xml
studyID <- 'BOUNDARIES_ELECTORATES'
s <- dbGetQuery(ch, paste("select * from stdydscr where idno = '",studyID,"'",sep=''))
s
f <- dbGetQuery(ch, paste("select * from filedscr where idno = '",studyID,"'",sep=''))
f
for(fi in f){
d <- dbGetQuery(ch,
                paste("select * from datadscr where FILEID = ",f$FILEID,
                      sep = '')
                )
d
ddixml <- make_xml(s,f,d)
}
out <- dir(pattern='xml')
file.remove(file.path('/xmldata', out))
file.copy(out, '/xmldata')
# go to indexer.jsp
out
