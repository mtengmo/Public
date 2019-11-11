DROP PROCEDURE [dbo].[sp_a46_agrqueuecheck]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[sp_a46_agrqueuecheck]
    @Report_time_W int = 10,
    -- default 10 min checks for (W)aiting reports = long waiting to run reports
    @Report_time_N int = 20,
    -- default 20 min checks for (N)aiting reports = long running reports
    @Queue_time int = 10,
    -- default 10 min checks for server queue checks (should run default every 5 minutes)
    @Queue_Scheduler_time int = 180,
    @Queue_dblogservice_time int = 1500,
    @Queue_ACRALS_time int = 240,
    @Queue_dws_time int = 70

-- AGRqueuecheck
-- version 1.0 /Jimmy
-- version 2.0 (20140218), converted to SP /Magnus
-- version 2.1 added databasename / Magnus
-- version 2.2 Remove [use master]
-- version 2.4 Cleaned and rebuilt, added scheduler/dblogservice 
-- version 2.5 change date_started to order_date on repore time.
--version 2.6 added server_name and status N on aagserverqueue
--ver 2.7, fixed hostname
--ver 2.8, added ALS to same queue as Scheduler 
--ver 3.0b M4
--ver 3.0c M4, added ALS, DWS
-- Example: 
-- exec [sp_a46_queuecheck] @queue_time='30',@report_time_n='5'

AS
BEGIN
    SET NOCOUNT ON

/*

declare 	@Report_time_W int  	-- default 60 min checks for (W)aiting reports = long waiting to run reports
declare 	@Report_time_N int 	-- default 20 min checks for (N)aiting reports = long running reports
declare     @Queue_time int       	-- default 10 min checks for server queue checks (should run default every 5 minutes)
declare		@Queue_Scheduler_time int  -- 
declare		@Queue_dblogservice_time int

set @Queue_dblogservice_time = 1500
set @Queue_Scheduler_time = 70
set @Report_time_W = 1
set @Report_time_N = 1
set @Queue_time = 1

*/



;
;
    with
        queue_cte2
        as
        (
            select end_time as event_time, report_name as description, 'HOSTNAME: ' + server_name as report_name
            from
                (
		                    select report_name, end_time, server_name, row_number() over(partition by report_name order by end_time desc) as rn
                    from aagprocessinfo
                    where process_type = 't'
                        and server_queue in (select server_queue
                        from aagserverqueue
                        where status = 'n')
                        and exit_code = '0'
                union
                    select server_queue, GETDATE()-1 as end_time, server_name, '1' as rn
                    from aagserverqueue
                    where server_queue not in (select distinct(report_name)
                        from aagprocessinfo
                        where process_type = 'T')
                        and controller_type = 'TimedProcess'
                        and status = 'n'
) as t
            where rn = '1'



        )

    -- Check last event_time on server processes
    insert into perfdb.dbo.agrqueuecheck
        (databasename,vilat,last_update,agrqueue,report_name,check_time)
    select @@servername + ' ' +  db_name() as databasename, vilat, last_update, agrqueue, report_name, getdate() as check_time
    from
        (
                            select datediff(MI,event_time,getutcdate()) as vilat,
                event_time as last_update,
                description as agrqueue,
                report_name as report_name
            from queue_cte2
            where datediff(MI,event_time,getutcdate()) >=@Queue_time
                and description != 'Scheduler'
                and description != 'dblogservice'
                and description != 'ACRALS'
                and description != 'DWS'
                or
                datediff(MI,event_time,getutcdate()) >= @Queue_Scheduler_time
                and description = 'Scheduler'
                or
                datediff(MI,event_time,getutcdate()) >= @Queue_ACRALS_time
                and description = 'ACRALS'
                or
                datediff(MI,event_time,getutcdate()) >= @Queue_dblogservice_time
                and description = 'dblogservice'
                or
                datediff(MI,event_time,getutcdate()) >= @Queue_DWS_time
                and description = 'DWS'
        union
            -- Check lastupdate on workflow service
            select datediff(MI,last_update,getdate()) as Vilat,
                last_update,
                'Workflow_Host:' + server_name as agrqueue,
                ' ' as report_name
            from awfservice
            where status = 'n'
                and datediff(MI,last_update,getdate()) >@Queue_time

        union
            -- Check long running and not running reports 
            select datediff(MI,order_date,getdate()) as Vilat,
                order_date as last_update,
                server_queue as agrqueue,
                report_name as report_name
            From acrrepord
            where status ='W'
                and datediff(MI,order_date,getdate())>=@Report_time_W
                and order_date > GETDATE()-1
        -- to only get a list of last days reports

        union
            select datediff(MI,order_date,getdate()) as Vilat,
                order_date as last_update,
                server_queue as agrqueue,
                report_name as report_name
            From acrrepord
            where status ='N'
                and datediff(MI,order_date,getdate())>=@Report_time_N
                and order_date > GETDATE()-1 -- to only get a list of last days reports



)
as temptable

END

GO


