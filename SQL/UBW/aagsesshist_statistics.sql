use db_u_monserver

-- aggreate session statistics from Unit4 BusinessWorld (Agresso) per day, used in monserver webinfo solution
-- performance trends
-- Magnus Tengmo (magnus@highcloud.se) - 2020-05-20
-- added unique
--
-- U = Unknown user
-- C Illegal combination of user and client
-- S Check user status
-- P Illegal password
-- M Check Password parameters
-- X Password expired
-- E Not allowed to logon at this time (too early)
-- L Not allowed to logon at this time (too late)


/*
--drop table agresso_aagsesshist_stats
create table agresso_aagsesshist_stats
(
login_date date,
system_name char(8),
client varchar(25),
status char(1),
counts int,
counts_unique int
)
create unique clustered  index ixcu1_agresso_aagsesshist_stats on agresso_aagsesshist_stats (
login_date asc,client asc,system_name asc,status asc)
*/

insert into agresso_aagsesshist_stats
    select
        convert(date,login_time) as login_date
, system_name
, client
, status 
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from db_p_agresso.dbo.aagsesshist
    where login_time > convert(date,getdate()-1)
        and login_time < convert(date,getdate())
    group by convert(date,login_time), system_name, status,client
union all
    select
        convert(date,login_time) as login_date
, system_name
, '_Alla' as client
, status 
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from db_p_agresso.dbo.aagsesshist
    where login_time > convert(date,getdate()-1)
        and login_time < convert(date,getdate())
    group by convert(date,login_time), system_name, status
--order by login_date desc


