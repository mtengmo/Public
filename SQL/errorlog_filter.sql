
DROP TABLE IF EXISTS #errorLog;
-- this is new syntax in SQL 2016 and later
CREATE TABLE #errorLog
(
    LogDate DATETIME,
    ProcessInfo VARCHAR(64),
    [Text] VARCHAR(MAX)
);


INSERT INTO #errorLog
EXEC sp_readerrorlog


INSERT INTO #errorLog
EXEC sp_readerrorlog 1


INSERT INTO #errorLog
EXEC sp_readerrorlog 2


INSERT INTO #errorLog
EXEC sp_readerrorlog 3

/*
INSERT INTO #errorLog
EXEC sp_readerrorlog 4


INSERT INTO #errorLog
EXEC sp_readerrorlog 5


INSERT INTO #errorLog
EXEC sp_readerrorlog 6


INSERT INTO #errorLog
EXEC sp_readerrorlog 7


INSERT INTO #errorLog
EXEC sp_readerrorlog 8  -- specify the log number or use nothing for active error log



INSERT INTO #errorLog
EXEC sp_readerrorlog 9



INSERT INTO #errorLog
EXEC sp_readerrorlog 10



INSERT INTO #errorLog
EXEC sp_readerrorlog 11



INSERT INTO #errorLog
EXEC sp_readerrorlog 12



INSERT INTO #errorLog
EXEC sp_readerrorlog 13



INSERT INTO #errorLog
EXEC sp_readerrorlog 14



INSERT INTO #errorLog
EXEC sp_readerrorlog 15



INSERT INTO #errorLog
EXEC sp_readerrorlog 16



INSERT INTO #errorLog
EXEC sp_readerrorlog 17



INSERT INTO #errorLog
EXEC sp_readerrorlog 18


INSERT INTO #errorLog
EXEC sp_readerrorlog 19


INSERT INTO #errorLog
EXEC sp_readerrorlog 20

*/
/*
create table database.dbo.errorlog_errors 
(
cntr_name nvarchar(255),
cntr_name_desc nvarchar(max),
datelist datetime,
cntr_value int
)
*/
truncate table database.dbo.errorlog_errors
INSERT INTO database.dbo.errorlog_errors
SELECT -- ProcessInfo
    Text as cntr_name
, null as cntr_name_desc
--,Logdate as datelist
, dateadd(hour, datediff(hour, 0, Logdate), 0) as datelist
, COUNT(*) as cntr_value
FROM #errorLog a
where Text like 'Error%'
--or Text like '%Warning%'
--or Text like '%Fatal%'
--or Text like '%Failed%'
--or Text like '%Dump%'
group by dateadd(hour, datediff(hour, 0, a.Logdate), 0), text
order by datelist desc

