EXEC dbo.sp_BlitzCache @Top = 30,
@SortOrder = 'memory grant' -- reads/ CPU/ duration/ executions/ XPM/ memory grant/ recent compilations. XPM=executions per minute
,
@ExpertMode = 1 --No DBCC FREEPROCCACHE (0x02000......)
,
@QueryFilter = 'ALL' --procedure/ statement/ ALL
,
@DatabaseName = 'xxxx' -- databasename
,
@ExportToExcel = 1 -- excel
,
@reanalyze = 0 -- 1 skip collecting fresh data from cache, just change sort, 0 fresh from cache