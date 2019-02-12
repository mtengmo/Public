CREATE TABLE Timetable (ID INT IDENTITY(0,1), TIMEVALUE DATETIME);
create clustered index ix1_timetable on timetable (id)

DECLARE @start DATETIME;
DECLARE @end DATETIME;

SET @start = '20190201';
SET @end = '20210101';

WITH CTE_DT AS 
(
    SELECT @start AS DT
    UNION ALL
    SELECT DATEADD(MINUTE,10,DT) FROM CTE_DT
    WHERE DT< @end
)
INSERT INTO Timetable
SELECT DT FROM CTE_DT
OPTION (MAXRECURSION 0);


select top 10 * from Timetable