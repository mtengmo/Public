
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[WaitStats_Deltas]
AS
    WITH
        RowDates
        as
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY sample_time) as ID
				, sample_time
            FROM [dbo].[utbl_waitstats]
            --where sample_time > getdate()-2
            GROUP BY  [sample_time]
        ),
        sample_times
        as
        (
            SELECT ThisDate.sample_time,
                LastDate.sample_time as Previoussample_time
            FROM RowDates ThisDate
                JOIN RowDates LastDate
                ON ThisDate.ID = LastDate.ID + 1
        )
    SELECT w.sample_time, w.wait_type, COALESCE(wc.WaitCategory, 'Other') AS WaitCategory, COALESCE(wc.Ignorable,0) AS Ignorable
, DATEDIFF(ss, wPrior.sample_time, w.sample_time) AS ElapsedSeconds
, (w.wait_time_ms - wPrior.wait_time_ms) AS wait_time_ms_delta
, (w.wait_time_ms - wPrior.wait_time_ms) / 60000.0 AS wait_time_minutes_delta
, (w.wait_time_ms - wPrior.wait_time_ms) / 1000.0 / DATEDIFF(ss, wPrior.sample_time, w.sample_time) AS wait_time_minutes_per_minute
, (w.signal_wait_time_ms - wPrior.signal_wait_time_ms) AS signal_wait_time_ms_delta
, (w.waiting_tasks_count - wPrior.waiting_tasks_count) AS waiting_tasks_count_delta
    --, w.ServerName + CAST(w.sample_time AS NVARCHAR(50)) AS JoinKey
    FROM [dbo].[utbl_waitstats] w
        INNER HASH JOIN sample_times Dates
        ON Dates.sample_time = w.sample_time
        INNER JOIN [dbo].[utbl_waitstats] wPrior
        ON --w.ServerName = wPrior.ServerName AND 
w.wait_type = wPrior.wait_type AND Dates.Previoussample_time = wPrior.sample_time
        LEFT OUTER JOIN [dbo].[BlitzFirst_WaitStats_Categories] wc ON w.wait_type = wc.WaitType
    WHERE DATEDIFF(MI, wPrior.sample_time, w.sample_time) BETWEEN 1 AND 1440
        AND [w].[wait_time_ms] >= [wPrior].[wait_time_ms];
GO


