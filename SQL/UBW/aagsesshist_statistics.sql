use db_u_monserver

-- aggreate session statistics from Unit4 BusinessWorld (Agresso) per day, used in monserver webinfo solution
-- performance trends
-- Magnus Tengmo (magnus at highcloud.se) - 2020-05-20
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
drop table agresso_aagsesshist_stats
create table agresso_aagsesshist_stats
(
login_date date,
system_name char(8),
client varchar(25),
status char(1),
status_desc varchar(255),
name_suffix varchar(255),
counts int,
counts_unique int
)
create unique clustered  index ixcu1_agresso_aagsesshist_stats on agresso_aagsesshist_stats (
login_date asc,client asc,system_name asc,status asc,status_desc asc,name_suffix asc)
*/

;
with
    cte_temp
    as
    (
        select
            [c_guid]
      , [client]
      , [counter]
      , [login_time]
      , [logout_time]
      , [status]
      , [system_name]
      , [terminal]
      , [used_bio]
      , [used_cpu]
      , [used_dio]
      , [user_id]
      , [agrtid]
	  , CASE
    WHEN [status] =  'n' THEN 'Normal'
    WHEN [status] =  'u' THEN 'Unknown user'
    WHEN [status] =  'c' THEN 'Illegal combination of user and client'
    WHEN [status] =  's' THEN 'Check user status'
	WHEN [status] =  'p' THEN 'Illegal password'
	WHEN [status] =  'm' THEN 'Check password parameters'
	WHEN [status] =  'x' THEN 'Password expired'
	WHEN [status] =  'e' THEN 'Not allowed to logon at this time (too early)'
	WHEN [status] =  'l' THEN 'Not allowed to logon at this time (too late)'
		else status
	END AS status_desc
        FROM [DB_P_AGRESSO].[dbo].[aagsesshist]
        where login_time > convert(date,getdate()-1000)
            and login_time < convert(date,getdate())
    )
insert into agresso_aagsesshist_stats
    select
        convert(date,login_time) as login_date
, system_name
, client
, status 
, status_desc
, 'S*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where user_id like 's%'
    group by convert(date,login_time), system_name, status,status_desc, client
union all
    select
        convert(date,login_time) as login_date
, system_name
, '_Alla' as client
, status 
, status_desc
, 'S*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where user_id like 's%'
    group by convert(date,login_time), system_name, status,status_desc
union all
    select
        convert(date,login_time) as login_date
, system_name
, client
, status 
, status_desc
, 'A*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where  user_id like 'a%'
    group by convert(date,login_time), system_name, status,status_desc,client
union all
    select
        convert(date,login_time) as login_date
, system_name
, '_Alla' as client
, status 
, status_desc
, 'A*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where user_id  like 'a%'
    group by convert(date,login_time), system_name, status,status_desc
union all
    select
        convert(date,login_time) as login_date
, system_name
, client
, status 
, status_desc
, 'Not A* or S*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where   user_id not like 'a%'
        and user_id not like 's%'
    group by convert(date,login_time), system_name, status,status_desc,client
union all
    select
        convert(date,login_time) as login_date
, system_name
, '_Alla' as client
, status 
, status_desc
, 'Not A* or S*' as name_suffix
, count(*) as counts
, count(distinct(user_id)) as counts_unique
    from cte_temp
    where   user_id not like 'a%'
        and user_id not like 's%'
    group by convert(date,login_time), system_name, status, status_desc



