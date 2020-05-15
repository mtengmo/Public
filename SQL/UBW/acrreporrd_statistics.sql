
-- aggreate report runtime, invoketime, counts from Unit4 BusinessWorld (Agresso) per day, used in monserver webinfo solution
-- performance trends
-- Magnus Tengmo (magnus@highcloud.se) - 2020-05-20
/*
create table agresso_acrrepord_stats
(
invoke_date date,
report_name varchar(255),
ing_status int,
counts int,
runtime_ss int,
runtime_avg_ss int,
invoke_time_ss int,
invoke_time_avg_ss int,
)
create unique clustered  index ixcu1_agresso_acrrepord_stats on agresso_acrrepord_stats (
invoke_date asc,report_name asc,ing_status asc)
*/

insert into agresso_acrrepord_stats
    select
        cast(invoke_time as date) as invoke_date
, report_name
, ing_status
, count(*) as counts
, sum(DATEDIFF(ss,date_started,date_ended)) as runtime_ss
, sum(DATEDIFF(ss,date_started,date_ended))/count(*) as runtime_avg_ss
, sum(DATEDIFF(ss,invoke_time,date_started)) as invoke_time_ss
, sum(DATEDIFF(ss,invoke_time,date_started))/count(*) as invoke_time_avg_ss
    from db_p_agresso.dbo.acrrepord
    where status = 't'
        and invoke_time > convert(date,getdate()-1)
        and invoke_time < convert(date,getdate())
    group by cast(invoke_time as date), report_name, ing_status, convert(date,invoke_time,12)
union all
    select
        cast(invoke_time as date) as invoke_date
, '_Alla' as report_name
, ing_status
, count(*) as counts
, sum(DATEDIFF(ss,date_started,date_ended)) as runtime_ss
, sum(DATEDIFF(ss,date_started,date_ended))/count(*) as runtime_avg_ss
, sum(DATEDIFF(ss,invoke_time,date_started)) as invoke_time_ss
, sum(DATEDIFF(ss,invoke_time,date_started))/count(*) as invoke_time_avg_ss
    from db_p_agresso.dbo.acrrepord
    where status = 't'
        and invoke_time > convert(date,getdate()-1)
        and invoke_time < convert(date,getdate())
    group by cast(invoke_time as date), ing_status, convert(date,invoke_time,12)
