

CREATE   view [dbo].[PerfmonStats_Actuals_with_baseline]
as
    (
            select c.[ServerName]
      , c.[object_name]
      , c.[counter_name] + '_baseline' as [counter_name]
      , c.[instance_name]
      , cast(t.checkdate as datetime) as checkdate
      --,c.[cntr_value]
      --,c.[JoinKey]
	  , avg(c.cntr_value) as cntr_value
        -- ,DATENAME(dw,c.[CheckDate] ) DayName
        -- ,DATEPART(dw, c.[CheckDate]) DayN
        -- ,DATEPART(hh, c.[CheckDate]) Hour
        --  ,COUNT(c.[CheckDate]) Instances
        FROM [dbo].[BlitzFirst_PerfmonStats_Actuals] c
  CROSS APPLY (
  select distinct(dateadd(hour, datediff(hour, 0, CheckDate), 0)) as CheckDate
            from [BlitzFirst_PerfmonStats_Actuals]
            where counter_name = 'Lock Timeouts/sec' -- just to get a datelist
   ) t
        where 1=1
            and DATENAME(dw, c.[CheckDate] ) = DATENAME(dw, t.CheckDate ) -- week
            and DATEPART(hh, c.[CheckDate]) = DATEPART(hh, t.CheckDate)
        -- hour
        -- and c.object_name = 'MSSQL$DB_PR01:Locks'
        -- and c.counter_name = 'Lock Timeouts/sec'
        --and c.instance_name = '_Total'
        --and DATEPART(dw, c.[CheckDate]) = 3
        --and DATEPART(hh, c.[CheckDate]) = 23
        GROUP BY c.servername, c.object_name, c.counter_name, c.instance_name, DATENAME(dw, c.[CheckDate] ), DATEPART(dw, c.[CheckDate]), DATEPART(hh, c.[CheckDate]),t.CheckDate
    union all
        SELECT [ServerName]
      , [object_name]
      , [counter_name]
      , [instance_name]
      , cast([CheckDate] as datetime) as checkdate
      , [cntr_value]
        -- ,[JoinKey]
        FROM [dbo].[BlitzFirst_PerfmonStats_Actuals] c
        where 1=1
--	and c.object_name = 'MSSQL$DB_PR01:Locks'
  --and c.counter_name = 'Lock Timeouts/sec'
 -- and c.instance_name = '_Total'
  --and DATEPART(dw, c.[CheckDate]) = 3
  --and DATEPART(hh, c.[CheckDate]) = 23
  --  order by checkdate 
    )



  
GO


