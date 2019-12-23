USE [PerfDB]
GO

/****** Object:  StoredProcedure [dbo].[waitsstatsnew]    Script Date: 2019-12-23 13:55:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[waitsstatsnew]
as
begin

    IF OBJECT_ID('tempdb..#WaitStatsNew') IS NOT NULL BEGIN
        DROP TABLE #WaitStatsNew
    END

    SELECT DateAdded = GETDATE()
    , wait_type
    , waiting_tasks_count 
    , wait_time_ms
    , max_wait_time_ms
    , signal_wait_time_ms
    INTO #WaitStatsNew
    FROM sys.dm_os_wait_stats
    where wait_type != 'MISCELLANEOUS'

    INSERT INTO WaitStats
        (DateStart, DateEnd, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
    SELECT DateStart = ISNULL(l.DateAdded, (SELECT create_date
        FROM sys.databases
        WHERE name = 'tempdb'))
    , DateEnd = n.DateAdded
    , wait_type = n.wait_type
    , waiting_tasks_count = n.waiting_tasks_count - ISNULL(l.waiting_tasks_count, 0)
    , wait_time_ms = n.wait_time_ms - ISNULL(l.wait_time_ms, 0)
    , max_wait_time_ms = n.max_wait_time_ms --It's a max, not cumulative
    , signal_wait_time_ms = n.signal_wait_time_ms - ISNULL(l.signal_wait_time_ms, 0)
    FROM #WaitStatsNew n
        LEFT OUTER JOIN WaitStatsLast l ON n.wait_type = l.wait_type AND l.DateAdded > (SELECT create_date
            FROM sys.databases
            WHERE name = 'tempdb')

    TRUNCATE TABLE WaitStatsLast

    INSERT INTO WaitStatsLast
        (DateAdded, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
    SELECT DateAdded
    , wait_type
    , waiting_tasks_count
    , wait_time_ms
    , max_wait_time_ms
    , signal_wait_time_ms
    FROM #WaitStatsNew

    DROP TABLE #WaitStatsNew

end





GO


