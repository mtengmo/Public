
CREATE   VIEW [dbo].[FileStats_Deltas_1h_summary]
AS
    WITH
        RowDates
        as
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY [ServerName], dateadd(hour, datediff(hour, 0, CheckDate), 0)) ID,
                dateadd(hour, datediff(hour, 0, CheckDate), 0) as CheckDate
            FROM [dbo].[BlitzFirst_FileStats]
            GROUP BY [ServerName], dateadd(hour, datediff(hour, 0, CheckDate), 0)
        ),
        CheckDates
        as
        (
            SELECT ThisDate.CheckDate,
                LastDate.CheckDate as PreviousCheckDate
            FROM RowDates ThisDate
                JOIN RowDates LastDate
                ON ThisDate.ID = LastDate.ID + 1
        )
    SELECT f.ServerName,
        f.CheckDate,
        -- f.DatabaseID,
        --  f.DatabaseName,
        --  f.FileID,
        --  f.FileLogicalName,
        f.TypeDesc,
        --  f.PhysicalName,
        sum(f.SizeOnDiskMB) as SizeOnDiskMB,
        DATEDIFF(ss, fPrior.CheckDate, f.CheckDate) AS ElapsedSeconds,
        sum(f.SizeOnDiskMB - fPrior.SizeOnDiskMB) AS SizeOnDiskMBgrowth,
        sum(f.io_stall_read_ms - fPrior.io_stall_read_ms) AS io_stall_read_ms,
        io_stall_read_ms_average = CASE
                                           WHEN sum(f.num_of_reads - fPrior.num_of_reads) = 0
                                           THEN 0
                                           ELSE sum(f.io_stall_read_ms - fPrior.io_stall_read_ms) /     sum(f.num_of_reads   -           fPrior.num_of_reads)
                                       END,
        sum(f.num_of_reads - fPrior.num_of_reads) AS num_of_reads,
        sum(f.bytes_read - fPrior.bytes_read) / 1024.0 / 1024.0 AS megabytes_read,
        sum(f.io_stall_write_ms - fPrior.io_stall_write_ms) AS io_stall_write_ms,
        io_stall_write_ms_average = CASE
                                            WHEN sum(f.num_of_writes - fPrior.num_of_writes) = 0
                                            THEN 0
                                            ELSE sum(f.io_stall_write_ms - fPrior.io_stall_write_ms) /         sum(f.num_of_writes   -       fPrior.num_of_writes)
                                        END,
        sum(f.num_of_writes - fPrior.num_of_writes) AS num_of_writes,
        sum(f.bytes_written - fPrior.bytes_written) / 1024.0 / 1024.0 AS megabytes_written,
        f.ServerName + CAST(f.CheckDate AS NVARCHAR(50)) AS JoinKey
    FROM [dbo].[BlitzFirst_FileStats] f
        INNER JOIN CheckDates DATES ON dateadd(hour, datediff(hour, 0, f.CheckDate), 0) = DATES.CheckDate
        INNER JOIN [dbo].[BlitzFirst_FileStats] fPrior ON f.ServerName =                 fPrior.ServerName
            AND f.DatabaseID = fPrior.DatabaseID
            AND f.FileID = fPrior.FileID
            AND dateadd(hour, datediff(hour, 0, fPrior.CheckDate), 0) =   DATES.PreviousCheckDate

    WHERE  f.num_of_reads >= fPrior.num_of_reads
        AND f.num_of_writes >= fPrior.num_of_writes
        AND DATEDIFF(MI, fPrior.CheckDate, f.CheckDate) BETWEEN 60 AND 60
    GROUP BY f.ServerName,        f.CheckDate, f.typedesc,fPrior.CheckDate, f.CheckDate;
GO


