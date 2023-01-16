use perfdb
-- aggreate commandlog data, used in monserver webinfo solution
-- performance trends
-- Magnus Tengmo (magnus at highcloud.se) - 2020-06-02
/*
create table commandlog_stats
(
startdate date,
databasename varchar(256),
commandtype varchar(256),
runtime_ss int,
runtime_avg_ss int,
counts int
)
create unique clustered  index ixcu1_commandlog_stats_stats on commandlog_stats (
startdate asc,databasename asc,commandtype asc)
*/

insert into commandlog_stats
    select cast(starttime as date) as startdate
, databasename
, commandtype
, sum(datediff(SECOND, starttime, endtime)) as runtime_ss 
, sum(datediff(SECOND, starttime, endtime))/count(*) runtime_avg_ss
, count(*) as counts
    from master.dbo.commandlog
    where errornumber = 0
        and StartTime > convert(date,getdate()-1)
        and StartTime < convert(date,getdate())
    group by  cast(starttime as date),databasename,commandtype
union all
    select cast(starttime as date) as startdate
, '_Alla' as databasename
, commandtype
, sum(datediff(SECOND, starttime, endtime)) as runtime_ss 
, sum(datediff(SECOND, starttime, endtime))/count(*) runtime_avg_ss
, count(*) as counts
    from master.dbo.commandlog
    where errornumber = 0
        and StartTime > convert(date,getdate()-1)
        and StartTime < convert(date,getdate())
    group by  cast(starttime as date),commandtype

