# hutchinsons index as a functon set for 1890-2003 data with placename, year, month, rain
#M:\Environmental_Health\DroughtAndDrying\2Work
#requires a database with gridded rain data
library(RODBC)
ch<-odbcConnect("weather")


# need to calculate 6 month totals BY GRID CELL
sqlQuery(ch,"drop TABLE bom_grids.time;
CREATE TABLE bom_grids.time
( timeid serial,
year integer NOT NULL,
month integer NOT NULL,
   CONSTRAINT time_pkey PRIMARY KEY (timeid)
 );

insert into bom_grids.time (year, month)
select distinct year, month from bom_grids.rain_act_1890_2008;
")

sqlQuery(ch,"select * from bom_grids.rain_act_1890_2008 limit 1;")

##########################################################################################################################
#
#
#
#d=sqlQuery(ch,"select * from bom_grids.rain_act_1890_2008_2 order by gid,timeid;")
months=1:12
states=c('act','nsw','vic','qld','sa','tas','wa','nt')


st=Sys.time()

for(ste in states[8]){
ste=states[1]
        gids=sqlQuery(ch,paste("select distinct gid from bom_grids.rain_",ste,"_1890_2008;",sep=""))
        #calc 6mo
        
        sqlQuery(ch,
				# cat(
				paste("CREATE TABLE bom_grids.rain_",ste,"_1890_2008_1
          (gid integer,
          admin_name character varying(255),
          long double precision,
          lat double precision,
          year integer NOT NULL,
          month integer NOT NULL,
          timeid integer,
          rain double precision,
          CONSTRAINT rain",ste,"1_pkey PRIMARY KEY (gid,timeid)
           );
        
        insert into bom_grids.rain_",ste,"_1890_2008_1 (gid, admin_name, long, lat, year, month,timeid, rain)
            select gid, admin_name, long, lat, bom_grids.rain_",ste,"_1890_2008.year, bom_grids.rain_",ste,"_1890_2008.month,timeid, rain
            from bom_grids.rain_",ste,"_1890_2008 join bom_grids.time on (bom_grids.rain_",ste,"_1890_2008.year= bom_grids.time.year)
            and (bom_grids.rain_",ste,"_1890_2008.month= bom_grids.time.month);",sep="")
          )    
        
        
        sqlQuery(ch,paste("
          CREATE TABLE bom_grids.rain_",ste,"_1890_2008_2
            (gid integer,
             timeid integer,
             year integer NOT NULL,
             month integer NOT NULL,
                  rain double precision,
                  rain6mo double precision,
                   CONSTRAINT rain",ste,"2_pkey PRIMARY KEY (gid,timeid)
                 );
                
                insert into bom_grids.rain_",ste,"_1890_2008_2 (gid, timeid, year, month,rain,rain6mo)
                select t1.gid, t1.timeid, t1.year, t1.month,t1.rain,sum(t2.rain)
                from bom_grids.rain_",ste,"_1890_2008_1 as t1 join bom_grids.rain_",ste,"_1890_2008_1 as t2 
                on (t1.gid=t2.gid)
                where t1.timeid between t2.timeid and t2.timeid+5 
                group by t1.gid, t1.timeid, t1.year, t1.month,t1.rain
                having count(t2.rain)=6
                order by t1.timeid;",sep="")
                )

                sqlQuery(ch,paste("create table bom_grids.rain_",ste,"_1890_2008_3 (
                    gid int4,
                    timeid int4,
                    year int4,
                    month int4, 
                    rain double precision,
                    rain6mo double precision, 
                    pctile double precision,
                    rescaledPctile double precision,
                    droughtIndex double precision,
                    indexBelowThreshold double precision,
                    CONSTRAINT r_",ste,"_pk PRIMARY KEY (gid, timeid))",sep="")
                    )       
          
                    #st=Sys.time()

                      for(g in gids[,1]){
                      
                        #g=gids[1,1]
                        
                        
                        # calc %iles
                
                        

# rank in percentage terms with respect to the rainfall totals for the same sequence of 6-months over all years of record
                                for(month in months){
                                #month=1
                                    sqlQuery(ch,"create table bom_grids.temporary (
                                      rank serial, 
                                      gid int4,
                                      timeid int4,
                                      year int4,
                                      month int4, 
                                      rain double precision,
                                      rain6mo double precision, 
                                      pctile double precision,
                                      rescaledPctile double precision,
                                      droughtIndex double precision,
                                      indexBelowThreshold double precision
                                      )")
                                                  
                                sqlQuery(ch,paste("insert into bom_grids.temporary (gid ,timeid, year, month, rain,rain6mo)
                                      select t1.gid ,t1.timeid, t1.year, t1.month, t1.rain,t1.rain6mo
                                      from bom_grids.rain_",ste,"_1890_2008_2 as t1
                                      where month = ",month," and gid ='",g,"'
                                      order by rain6mo",sep="")
                                      )
                                      
                    
                                    n=sqlQuery(ch,"select count(*) from bom_grids.temporary")
                                    sqlQuery(ch,paste("update bom_grids.temporary set pctile = (cast(rank as numeric)-1)/(",n,"-1);
                                   		  update bom_grids.temporary set rescaledPctile = 8*(pctile-0.5);
                                   		  update bom_grids.temporary  set droughtIndex= 1 where rescaledPctile < -1 ;
                               		      update bom_grids.temporary set indexbelowthreshold  = droughtIndex * rescaledPctile;
                                        
                                        insert into bom_grids.rain_",ste,"_1890_2008_3 (gid ,timeid, year, month, rain,
                                          rain6mo,pctile,rescaledPctile,droughtIndex,indexBelowThreshold) 
                                        select t1.gid ,t1.timeid, t1.year, t1.month, t1.rain,t1.rain6mo,t1.pctile,t1.rescaledPctile,t1.droughtIndex,
                                          t1.indexBelowThreshold from bom_grids.temporary as t1 
                                        order by t1.gid, t1.timeid;",sep="")
                                        )
                                        
                                    sqlQuery(ch,"drop table bom_grids.temporary;")
                                    
                                    }
                          
                            }
 }                         
                          
                              en=Sys.time()

                              print(en-st)
       
########################
#-- are any first months a index month?
#
sqlQuery(ch,paste("select * from bom_grids.rain_",ste,"_1890_2008_3 where year = 1890 and month = 6 
and indexbelowthreshold is not null;",sep=""))  

#sqlQuery(ch,
cat(paste("update bom_grids.rain_",ste,"_1890_2008_3 
set indexbelowthreshold = null
where year = 1890 and month = 6 
and indexbelowthreshold is not null;",sep=""))  


#Hutchinson says "As the percentile value of zero rainfalls is not well defined, if the total rainfall for a six-month period was zero then the percentile value is set to the mid-point of the relative frequency that the six-month sequence is dry"
# I used the (rank-1)/(length-1) 

# I will do NT first and then re-do all the other states, only gids that have zero 6mos.

d=sqlQuery(ch,"select *
 from bom_grids.rain_nt_1890_2008_3 
 where month = 9 and gid ='21082' 
 order by rain6mo")
head(d)
plot(d$rain6mo,d$pctile)
segments(0,(nrow(d[d$rain6mo==0,])-1)/(nrow(d)-1),20,(nrow(d[d$rain6mo==0,])-1)/(nrow(d)-1))

cat(paste("update bom_grids.rain_",ste,"_1890_2008_3 as t1
set pctile = foo.max
from (
select t1.gid, t1.year, t1.month, case when rain6mo = 0 then t2.max else pctile end as max
	from bom_grids.rain_",ste,"_1890_2008_3 as t1 left join
		(
		select gid,month, max(pctile)
		from bom_grids.rain_",ste,"_1890_2008_3
		where rain6mo =0
		group by gid,month
		) t2 
	on t1.gid=t2.gid 
	and t1.month=t2.month
) as foo
where t1.gid=foo.gid 
and t1.month=foo.month
and t1.year=foo.year",sep="")
)

#re-do the rescaling of the pctiles work from above
# insert calcs into bom_grids.rain_",ste,"_1890_2008_5
# delete old ~3 and then rename ~5 to bom_grids.rain_",ste,"_1890_2008_3 and then create bom_grids.rain_",ste,"_1890_2008_4

gids=sqlQuery(ch,paste("select distinct gid from bom_grids.rain_",ste,"_1890_2008;",sep=""))

strt=Sys.time()
 sqlQuery(ch,paste("create table bom_grids.rain_",ste,"_1890_2008_5 (
                    gid int4,
                    timeid int4,
                    year int4,
                    month int4, 
                    rain double precision,
                    rain6mo double precision, 
                    pctile double precision,
                    rescaledPctile double precision,
                    droughtIndex double precision,
                    indexBelowThreshold double precision,
                    CONSTRAINT r5_",ste,"_pk PRIMARY KEY (gid, timeid))",sep="")
                    )       
          
for(g in gids[,1]){
                      
		for(month in months){
		#month=1
		sqlQuery(ch,"create table bom_grids.temporary (
		  rank serial, 
		  gid int4,
		  timeid int4,
		  year int4,
		  month int4, 
		  rain double precision,
		  rain6mo double precision, 
		  pctile double precision,
		  rescaledPctile double precision,
		  droughtIndex double precision,
		  indexBelowThreshold double precision
		  )")
		              
		sqlQuery(ch,paste("insert into bom_grids.temporary (gid ,timeid, year, month, rain,rain6mo,pctile)
		  select t1.gid ,t1.timeid, t1.year, t1.month, t1.rain,t1.rain6mo,t1.pctile
		  from bom_grids.rain_",ste,"_1890_2008_3 as t1
		  where month = ",month," and gid ='",g,"'
		  order by rain6mo",sep="")
		  )
		  
		
		n=sqlQuery(ch,"select count(*) from bom_grids.temporary")
		sqlQuery(ch,paste("
			  update bom_grids.temporary set rescaledPctile = 8*(pctile-0.5);
			  update bom_grids.temporary  set droughtIndex= 1 where rescaledPctile < -1 ;
		    update bom_grids.temporary set indexbelowthreshold  = droughtIndex * rescaledPctile;
		    
		    insert into bom_grids.rain_",ste,"_1890_2008_5 (gid ,timeid, year, month, rain,
		      rain6mo,pctile,rescaledPctile,droughtIndex,indexBelowThreshold) 
		    select t1.gid ,t1.timeid, t1.year, t1.month, t1.rain,t1.rain6mo,t1.pctile,t1.rescaledPctile,t1.droughtIndex,
		      t1.indexBelowThreshold from bom_grids.temporary as t1 
		    order by t1.gid, t1.timeid;",sep="")
		    )
		    
		sqlQuery(ch,"drop table bom_grids.temporary;")
		
		}
}
endd=Sys.time()
print(endd-strt)

d=sqlQuery(ch,"select *
 from bom_grids.rain_nt_1890_2008_5
 where month = 9 and gid ='21082' 
 order by rain6mo")
head(d)

sqlQuery(ch,"drop table bom_grids.rain_nt_1890_2008_3;
alter table bom_grids.rain_nt_1890_2008_5 rename to rain_nt_1890_2008_3;")

d=sqlQuery(ch,"select *
 from bom_grids.rain_nt_1890_2008_3
 where month = 9 and gid ='21082' 
 order by rain6mo")
head(d)


###############################################################################
#calc sums
                             sqlQuery(ch,
														 # cat(
														 paste("
                             begin;
                             drop table  bom_grids.rain_",ste,"_1890_2008_4;
                             end;
                              create table bom_grids.rain_",ste,"_1890_2008_4 (
                              gid int4,
                              timeid int4,
                              year int4,
                              month int4, 
                              rain double precision,
                              rain6mo double precision, 
                              pctile double precision,
                              rescaledPctile double precision,
                              indexBelowThreshold double precision,
                              sum double precision,
                              count int4,
                              CONSTRAINT r4_",ste,"_pk PRIMARY KEY (gid, timeid))",sep="")
                              )       

#close(ch)
library(RODBC)
ch=odbcConnect('weather')
ste=states[8]
ste
        gids=sqlQuery(ch,paste("select distinct gid from bom_grids.rain_",ste,"_1890_2008;",sep=""))                    
                    
                    nrow(gids)
                    doneGids=sqlQuery(ch,paste("select distinct gid from bom_grids.rain_",ste,"_1890_2008_4",sep="")) 
                    nrow(doneGids)
                    tail(doneGids)
                    summary(gids)
hist(gids[,1])                   
                
								    st=Sys.time()

                    for(i in seq(6300,6700,10)){
                           
                           li=i
                           print(li)
                           ui=i+10
                           
                            sqlQuery(ch,
                            paste("insert into bom_grids.rain_",ste,"_1890_2008_4 (
                                      gid, timeid, \"year\", \"month\", rain, rain6mo, pctile, rescaledpctile,
                                      indexbelowthreshold, sum, count)
                                select t3.gid,t3.timeid,t3.year,t3.month,t3.rain,t3.rain6mo,t3.pctile,t3.rescaledpctile,t3.indexbelowthreshold,
                                    sum(t4.indexbelowthreshold),count(t4.indexbelowthreshold)
                                from (select t1.gid, t1.timeid,t1.indexbelowthreshold
                                from bom_grids.rain_",ste,"_1890_2008_3 as t1
                                where t1.gid>=",li," and t1.gid<",ui,"
                                order by t1.gid, t1.timeid) as t4,
                                   (select t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold,max(t2.timeid)
                                      from
                                      (select t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold
                                      from bom_grids.rain_",ste,"_1890_2008_3 as t1
                                      where t1.gid>=",li," and t1.gid<",ui,"
                                      order by t1.gid, t1.timeid) as t1,
                                      (select t1.gid, t1.timeid,t1.indexbelowthreshold
                                      from bom_grids.rain_",ste,"_1890_2008_3 as t1 
                                      where t1.gid>=",li," and t1.gid<",ui,"
                                      order by t1.gid, t1.timeid) as t2
                                      where t1.gid = t2.gid
                                      and t1.timeid >= t2.timeid
                                      and t2.indexbelowthreshold is null 
                                      group by t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold
                                      order by t1.timeid) 
                                    as t3
                                where t3.gid=t4.gid
                                and t3.timeid >= t4.timeid
                                and t3.max <= t4.timeid
                                group by t3.gid, t3.timeid,t3.year,t3.month,t3.rain,t3.rain6mo,t3.pctile,t3.rescaledpctile,t3.indexbelowthreshold
                                order by t3.gid,t3.timeid",sep="")
                                )
                                

        
                    }

en=Sys.time()

print(en-st)









############################
# for some reason got to XXXX and then just took forever to do the rest etc
# workaround by make new table with

#sqlQuery(ch,"delete from bom_grids.rain_qld_1890_2008_4 
# where gid>=22130;") 
 
setgo=22772   
#drop table bom_grids.rain_",ste,"_1890_2008_3test;


library(RODBC)
ch=odbcConnect('weather')
ste=states[8]

sqlQuery(ch,
paste("
create table bom_grids.rain_",ste,"_1890_2008_3test (
                              gid int4,
                              timeid int4,
                              year int4,
                              month int4, 
                              rain double precision,
                              rain6mo double precision, 
                              pctile double precision,
                              rescaledPctile double precision,
                              droughtIndex double precision,
                              indexBelowThreshold double precision,
                              CONSTRAINT r3tst_",ste,"_pk PRIMARY KEY (gid, timeid)
                              );



insert into bom_grids.rain_",ste,"_1890_2008_3test (gid, timeid, \"year\", \"month\", rain, rain6mo, pctile, rescaledpctile, 
       droughtindex, indexbelowthreshold)

SELECT t1.gid, t1.timeid, t1.\"year\", t1.\"month\", t1.rain, t1.rain6mo, t1.pctile, t1.rescaledpctile, 
       t1.droughtindex, t1.indexbelowthreshold 
  FROM bom_grids.rain_",ste,"_1890_2008_3 as t1
  where gid>=",setgo,";
",sep=""))


summary(gids)



st=Sys.time()

                    for(i in seq(setgo,23942,10)){
                           
                           li=i
                           print(li)
                           ui=i+10
                           
                            sqlQuery(ch,
                            paste("insert into bom_grids.rain_",ste,"_1890_2008_4 (
                                      gid, timeid, \"year\", \"month\", rain, rain6mo, pctile, rescaledpctile,
                                      indexbelowthreshold, sum, count)
                                select t3.gid,t3.timeid,t3.year,t3.month,t3.rain,t3.rain6mo,t3.pctile,t3.rescaledpctile,t3.indexbelowthreshold,
                                    sum(t4.indexbelowthreshold),count(t4.indexbelowthreshold)
                                from (select t1.gid, t1.timeid,t1.indexbelowthreshold
                                from bom_grids.rain_",ste,"_1890_2008_3test as t1
                                where t1.gid>=",li," and t1.gid<",ui,"
                                order by t1.gid, t1.timeid) as t4,
                                   (select t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold,max(t2.timeid)
                                      from
                                      (select t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold
                                      from bom_grids.rain_",ste,"_1890_2008_3test as t1
                                      where t1.gid>=",li," and t1.gid<",ui,"
                                      order by t1.gid, t1.timeid) as t1,
                                      (select t1.gid, t1.timeid,t1.indexbelowthreshold
                                      from bom_grids.rain_",ste,"_1890_2008_3test as t1 
                                      where t1.gid>=",li," and t1.gid<",ui,"
                                      order by t1.gid, t1.timeid) as t2
                                      where t1.gid = t2.gid
                                      and t1.timeid >= t2.timeid
                                      and t2.indexbelowthreshold is null 
                                      group by t1.gid, t1.timeid,t1.year,t1.month,t1.rain,t1.rain6mo,t1.pctile,t1.rescaledpctile,t1.indexbelowthreshold
                                      order by t1.timeid) 
                                    as t3
                                where t3.gid=t4.gid
                                and t3.timeid >= t4.timeid
                                and t3.max <= t4.timeid
                                group by t3.gid, t3.timeid,t3.year,t3.month,t3.rain,t3.rain6mo,t3.pctile,t3.rescaledpctile,t3.indexbelowthreshold
                                order by t3.gid,t3.timeid",sep="")
                                )
                                

        
                    }

en=Sys.time()

print(en-st)

#all done?

sqlQuery(ch,paste("select t1.gid, t2.gid from (
SELECT distinct gid
  FROM bom_grids.rain_",ste,"_1890_2008_3) as t1 left join ( 
SELECT distinct gid
  FROM bom_grids.rain_",ste,"_1890_2008_4) as t2 on t1.gid=t2.gid
  where t2.gid is null ",sep=""))

sqlQuery(ch,paste("select gid, year, count(month) from bom_grids.rain_",ste,"_1890_2008_4 
where gid = ",setgo,"
group by gid, year
order by year",sep=""))

sqlQuery(ch,paste("drop table bom_grids.rain_",ste,"_1890_2008_3test",sep=""))
#
 
#qc
sqlQuery(ch,paste("begin;
drop table test82;
    commit;")
sqlQuery(ch,paste("    begin;
  select t1.gid, year, max(sum) as mxsum, max(count) as mxcount, t2.the_geom into test82
    from bom_grids.rain_",ste,"_1890_2008_4 as t1 join bom_grids.grid_aus as t2 on (t1.gid=t2.gid)
    group by t1.gid, year, t2.the_geom
    having year = 1982;
    create unique index tst82pk on test82 (gid);
    commit;
    ",sep="")
    )
    

#  now re-do the other months with zero 6month rains set to the pctile of the relfreq of the month being dry
# find the gids with zeros in the rain6mo using a master table

#drop table bom_grids.rain_aus_1890_2008_4;
#CREATE TABLE bom_grids.rain_aus_1890_2008_4 (
#	gid integer NOT NULL,
#  timeid integer NOT NULL,
#  "year" integer,
#  "month" integer,
#  rain double precision,
#  rain6mo double precision,
#  pctile double precision,
#  rescaledpctile double precision,
#  indexbelowthreshold double precision,
#  sum double precision,
#  count integer,
#  CONSTRAINT r_aus_pk PRIMARY KEY (gid, timeid)
#);
#
#CREATE TABLE bom_grids.rain_nt_1890_2008_4 (
#  gid integer NOT NULL,
#  timeid integer NOT NULL,
#  "year" integer,
#  "month" integer,
#  rain double precision,
#  rain6mo double precision,
#  pctile double precision,
#  rescaledpctile double precision,
#  droughtindex double precision,
#  indexbelowthreshold double precision,
#  sum double precision,
#  count integer,
#  CONSTRAINT r4_nt_pk PRIMARY KEY (gid, timeid)
#);
#
#INSERT INTO bom_grids.rain_nt_1890_2008_4(
#            gid, timeid, "year", "month", rain, rain6mo, pctile, rescaledpctile, 
#            droughtindex, indexbelowthreshold)
#    select * from bom_grids.rain_nt_1890_2008_3;
#
#
#ALTER TABLE bom_grids.rain_qld_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_nt_1890_2008_4  inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_wa_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_sa_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_nsw_1890_2008_4  inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_vic_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_act_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#ALTER TABLE bom_grids.rain_tas_1890_2008_4 inherit bom_grids.rain_aus_1890_2008_4;
#
#
#
#
sqlQuery(ch,"
ALTER TABLE bom_grids.rain_nt_1890_2008_4  inherit bom_grids.rain_aus_1890_2008_4;
ALTER TABLE bom_grids.rain_nsw_1890_2008_4  inherit bom_grids.rain_aus_1890_2008_4;
drop table bom_grids.zero_rain6mo;
select bom_grids.grid_aus.gid, cast(count(*) as numeric) as countsofzero, the_geom 
into bom_grids.zero_rain6mo
from bom_grids.rain_aus_1890_2008_4 join bom_grids.grid_aus on bom_grids.rain_aus_1890_2008_4.gid=bom_grids.grid_aus.gid
group by rain6mo, bom_grids.grid_aus.gid, the_geom
having rain6mo = 0;
create unique index \"bom_grids.zero_rain6mo_pk\" on bom_grids.zero_rain6mo (gid);")

#
# 

# first qld
ste=states[4]
ste

select t1.* 
from bom_grids.rain_",ste,"_1890_2008_4 t1 join bom_grids.zero_rain6mo t2 on t1.gid=t2.gid







# finally add indexes and do partitioned table stuff
for(ste in states){
 cat(paste("ALTER TABLE bom_grids.grid_",ste," ALTER COLUMN the_geom SET NOT NULL;
 CREATE INDEX grid",ste,"_gist on bom_grids.grid_",ste," using GIST(the_geom);
 ALTER TABLE bom_grids.grid_",ste," CLUSTER ON grid",ste,"_gist;",sep="")
)
}

library(RODBC)
ch=odbcConnect("weather")
for(ste in states){
upperi=sqlQuery(ch,paste("select max(gid) from bom_grids.grid_",ste,";",sep="")) 
loweri=sqlQuery(ch,paste("select min(gid) from bom_grids.grid_",ste,";",sep="")) 
 cat(paste("ALTER TABLE bom_grids.grid_",ste," ADD CHECK (gid <=",upperi,"
  and gid >=",loweri,");",sep=""))
}

for(ste in states){
 cat(paste("ALTER TABLE bom_grids.rain_",ste,"_1890_2008_4 CLUSTER ON r4_",ste,"_pk;\n",sep="")
)
}

library(RODBC)
ch=odbcConnect("weather")
for(ste in states){
upperi=sqlQuery(ch,paste("select max(gid) from bom_grids.grid_",ste,";",sep="")) 
loweri=sqlQuery(ch,paste("select min(gid) from bom_grids.grid_",ste,";",sep="")) 
cat(paste("ALTER TABLE bom_grids.grid_",ste," ADD CHECK (gid <=",upperi,"
  and gid >=",loweri,");",sep=""))
}

for(ste in states){
 cat(paste("create index r4_",ste,"_mnth on bom_grids.rain_",ste,"_1890_2008_4 (month);
 	create index r4_",ste,"_yy on bom_grids.rain_",ste,"_1890_2008_4 (year);\n",sep="")
)
}


ls()
###############################################################################
## old work
## calculate the indices  in R
#		data$count<-as.numeric(0)
#		
#		for(j in 2:nrow(data)){
#		  data$count[j]<-ifelse(is.na(data$indexbelowthreshold[j]),0,
#                     ifelse(!is.na(data$indexbelowthreshold[j-1]),1+data$count[j-1],
#                     1))
#		}
#		
#		data$sums<-as.numeric(0)
#		
#		for(j in 2:nrow(data)){
#		  data$sums[j]<-ifelse(is.na(data$indexbelowthreshold[j]),0,
#                    ifelse(!is.na(data$indexbelowthreshold[j-1]),data$indexbelowthreshold[j]+data$sums[j-1],
#                    data$indexbelowthreshold[j]))
#		}
#		
#data[1:100,]	
#
## or in SQL
#sqlQuery(ch,paste("select gid,                 ,timeid,              ,year,                ,month,               ,rain,                ,rain6mo,             ,pctile      ,rescaledpctile,      ,droughtindex,        ,indexbelowthreshold  
#into bom_grids.rain_",ste,"_1890_2008_droughtIndexesTest
#from bom_grids.rain_",ste,"_1890_2008_3 as t1,  bom_grids.rain_",ste,"_1890_2008_3 as t2
#where gid = ",gids[1,1]," 
#order by timeid",sep=""))
#
#
#################################################################################
##checks
#qc=sqlQuery(ch,paste("SELECT gid, timeid, year, month, rain, rain6mo, pctile, rescaledpctile, 
#       droughtindex, indexbelowthreshold
#  FROM bom_grids.rain_",ste,"_1890_2008_3 
#  where gid=6682
#  order by gid, timeid;",sep=""))
#  
#head(qc)
#qc[order(qc$pctile),]
#
#plot(qc$timeid,qc$rain6mo)
#lines(qc$timeid,qc$rain6mo)
#lines(lowess(qc$rain6mo~qc$timeid,f=0.2))
#
## will create a table called droughtIndices
#
## and rain extracted for a single place like 
##  CD_CODE year month      rain
##1 1140101 1890     1  26.86461
##2 1140101 1890     2 167.12060
#
## and called data
#
##set drought threshold
## Hutchinson rescaled percentiles to fall between -4 and +4 to replicate palmer index 
## then set the threshold at -1 which is upper limit of mild drought in palmer index 
## this is 3/8ths, or the 37.5th percentile 
#
#
#droughtIndex<-function(data,droughtThreshold=.375){
#		#calculate 6 month totals
#		x<-ts(data[,4],start=1,end=c(114,12),frequency=12)
#		x<-c(rep(NA,5),x+lag(x,1)+lag(x,2)+lag(x,3)+lag(x,4)+lag(x,5))
#		data$sixmnthtot<-x
#		data<-na.omit(data)
#		# rank in percentage terms with respect to the rainfall totals for the same sequence of 6-months over all years of record
#		for(i in 1:12){
#		  x<-data[data$month==i,5]
#		  x<-na.omit(x)
#		  y<-(rank(x)-1)/(length(x)-1)
#		  # rescale between -4 and +4 to replicate palmer index 
#		  z<-8*(y-.5)
#		  # defualts set the threshold at -1 which is upper limit of mild drought in palmer index (3/8ths, or the 37.5th percentile) 
#		  drought<-x<=quantile(x,droughtThreshold)
#		  # calculate the drought index for any months that fall below the threshold
#		  zd<-z*drought
#		  # save out to the data
#		  dataout<-data[data$month==i,]
#		  dataout$index<-z
#		  dataout$indexBelowThreshold<-zd
#		  sqlSave(ch,dataout,rownames=F,append=T)
#		  }
#		
#		data<-sqlQuery(ch,"select * from dataout order by year, month")
#		sqlDrop(ch,"dataout")
#		
#		# now calculate the indices
#		data$count<-as.numeric(0)
#		
#		for(j in 2:nrow(data)){
#		  data$count[j]<-ifelse(data$indexBelowThreshold[j]==0,0,
#        ifelse(data$indexBelowThreshold[j-1]!=0,1+data$count[j-1],1))
#		}
#		
#		data$sums<-as.numeric(0)
#		
#		for(j in 2:nrow(data)){
#		  data$sums[j]<-ifelse(data$indexBelowThreshold[j]==0,0,
#                      ifelse(data$indexBelowThreshold[j-1]!=0,data$indexBelowThreshold[j]+data$sums[j-1],data$indexBelowThreshold[j]))
#		}
#		droughtIndices<-data
#		#sqlDrop(ch,"droughtIndices")
#		sqlSave(ch,droughtIndices,rownames=F,append=T)
#		}
#