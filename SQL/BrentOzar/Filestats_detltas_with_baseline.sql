create view Filestats_detltas_with_baseline
as
    with
        cte
        as
        (
                            SELECT [ServerName]
      , cast([CheckDate] as datetime) as checkdate
    --  ,[DatabaseID]
      , [DatabaseName]
	  , typedesc
    --  ,[FileID]
      , [FileLogicalName]
    --  ,[TypeDesc]
      , [PhysicalName]
      , [SizeOnDiskMB]
    --  ,[ElapsedSeconds]
      , [SizeOnDiskMBgrowth]
      , [io_stall_read_ms]
      , [io_stall_read_ms_average]
      , [num_of_reads]
      , [megabytes_read]
      , [io_stall_write_ms]
      , [io_stall_write_ms_average]
      , [num_of_writes]
      , [megabytes_written]
      , num_of_reads / ElapsedSeconds as iops_read
      , num_of_writes / ElapsedSeconds as iops_write
                FROM [DB_U_MONSERVER].[dbo].[FileStats_Deltas] c
                where 1=1
                --typedesc = 'rows'
                -- and DATEPART(dw, c.[CheckDate]) = 3
                -- and DATEPART(hh, c.[CheckDate]) = 23
            union all
                select [ServerName]
      , cast([CheckDate] as datetime) as checkdate
    --  ,[DatabaseID]
      , '_All' as [DatabaseName]
	    , typedesc
    --  ,[FileID]
     , '_All' as [FileLogicalName]
     , '_All' as [PhysicalName]
      , sum([SizeOnDiskMB]) as [SizeOnDiskMB]
    --  ,[ElapsedSeconds]
      , sum([SizeOnDiskMBgrowth]) as SizeOnDiskMBgrowth
      , sum([io_stall_read_ms]) as [io_stall_read_ms]
      , sum([io_stall_read_ms_average]) as [io_stall_read_ms_average]
      , sum([num_of_reads]) as [num_of_reads]
      , sum([megabytes_read]) as [megabytes_read]
      , sum([io_stall_write_ms]) as [io_stall_write_ms]
      , sum([io_stall_write_ms_average]) as [io_stall_write_ms_average]
      , sum([num_of_writes]) as [num_of_writes]
      , sum([megabytes_written]) as [megabytes_written]
       , sum(num_of_reads / ElapsedSeconds) as iops_read
      , sum(num_of_writes / ElapsedSeconds) as iops_write
                FROM [DB_U_MONSERVER].[dbo].[FileStats_Deltas] c
                where 1=1
                -- and DATEPART(dw, c.[CheckDate]) = 3
                -- and DATEPART(hh, c.[CheckDate]) = 23
                group by servername, checkdate,   typedesc

        )
            select *
        from cte
    union all
        select [ServerName]
      , cast(t.[CheckDate] as datetime) as checkdate
    --  ,[DatabaseID]
      , databasename + '_baseline' as [DatabaseName]
    --  ,[FileID]
     , [FileLogicalName] + '_baseline' as [FileLogicalName]
      , [TypeDesc]
     , [PhysicalName] + '_baseline' as [PhysicalName]
      , avg([SizeOnDiskMB]) as [SizeOnDiskMB]
    --  ,[ElapsedSeconds]
      , avg([SizeOnDiskMBgrowth]) as SizeOnDiskMBgrowth
      , avg([io_stall_read_ms]) as [io_stall_read_ms]
      , avg([io_stall_read_ms_average]) as [io_stall_read_ms_average]
      , avg([num_of_reads]) as [num_of_reads]
      , avg([megabytes_read]) as [megabytes_read]
      , avg([io_stall_write_ms]) as [io_stall_write_ms]
      , avg([io_stall_write_ms_average]) as [io_stall_write_ms_average]
      , avg([num_of_writes]) as [num_of_writes]
      , avg([megabytes_written]) as [megabytes_written]
      , avg(iops_read)
      , avg(iops_write)
        FROM cte c
   CROSS APPLY (
  select distinct(dateadd(hour, datediff(hour, 0, CheckDate), 0)) as CheckDate
            from cte
            where DatabaseName = 'master' -- creating datelist, filter table only master
   ) t
        where 1=1
            and DATENAME(dw, c.[CheckDate] ) = DATENAME(dw, t.CheckDate ) -- week
            and DATEPART(hh, c.[CheckDate]) = DATEPART(hh, t.CheckDate)
        -- hour
        --and c.typedesc = 'rows'
        --	  and DATEPART(dw, c.[CheckDate]) = 3
        --and DATEPART(hh, c.[CheckDate]) = 23
        GROUP BY c.servername, DATENAME(dw, c.[CheckDate] ), DATEPART(dw, c.[CheckDate]), DATEPART(hh, c.[CheckDate]),t.CheckDate, c.DatabaseName, c.FileLogicalName, c.PhysicalName, c.TypeDesc
	   --order by checkdate
  /*
 union all
 
 SELECT  [ServerName]
      ,cast([CheckDate] as datetime) as checkdate
    --  ,[DatabaseID]
      ,[DatabaseName]
    --  ,[FileID]
      ,'_All' as [FileLogicalName]
        ,'_All' as [TypeDesc]
     ,'_All' as [PhysicalName]
      ,sum([SizeOnDiskMB]) as [SizeOnDiskMB]
    --  ,[ElapsedSeconds]
      ,sum([SizeOnDiskMBgrowth]) as SizeOnDiskMBgrowth
      ,sum([io_stall_read_ms]) as [io_stall_read_ms]
      ,sum([io_stall_read_ms_average]) as [io_stall_read_ms_average]
      ,sum([num_of_reads]) as [num_of_reads]
      ,sum([megabytes_read]) as [megabytes_read]
      ,sum([io_stall_write_ms]) as [io_stall_write_ms]
      ,sum([io_stall_write_ms_average]) as [io_stall_write_ms_average]
      ,sum([num_of_writes]) as [num_of_writes]
      ,sum([megabytes_written]) as [megabytes_written]
      ,sum(num_of_reads / ElapsedSeconds) as iops_read
      ,sum(num_of_writes / ElapsedSeconds) as iops_write
  FROM [DB_U_MONSERVER].[dbo].[FileStats_Deltas]
    where typedesc = 'rows'
    group by servername, checkdate, databasename
  union all
  select [ServerName]
      ,cast([CheckDate] as datetime) as checkdate
    --  ,[DatabaseID]
      ,'_All' as [DatabaseName]
    --  ,[FileID]
      ,'_All' as [FileLogicalName]
        ,'_All' as [TypeDesc]
     ,'_All' as [PhysicalName]
      ,sum([SizeOnDiskMB]) as [SizeOnDiskMB]
    --  ,[ElapsedSeconds]
      ,sum([SizeOnDiskMBgrowth]) as SizeOnDiskMBgrowth
      ,sum([io_stall_read_ms]) as [io_stall_read_ms]
      ,sum([io_stall_read_ms_average]) as [io_stall_read_ms_average]
      ,sum([num_of_reads]) as [num_of_reads]
      ,sum([megabytes_read]) as [megabytes_read]
      ,sum([io_stall_write_ms]) as [io_stall_write_ms]
      ,sum([io_stall_write_ms_average]) as [io_stall_write_ms_average]
      ,sum([num_of_writes]) as [num_of_writes]
      ,sum([megabytes_written]) as [megabytes_written]
      ,sum(num_of_reads / ElapsedSeconds) as iops_read
      ,sum(num_of_writes / ElapsedSeconds) as iops_write
  FROM [DB_U_MONSERVER].[dbo].[FileStats_Deltas]
    where typedesc = 'rows'
  group by servername, checkdate
  order by checkdate asc, databasename asc
  */
 