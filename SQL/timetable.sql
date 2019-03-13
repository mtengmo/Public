use WB_DSkunder
drop table timetable
CREATE TABLE Timetable
(
    ID INT IDENTITY(0,1),
    TIMESTAMP DATETIME,
    DATESTAMP varchar(25),
    HOURMINUTESTAMP float,
    WEEKDAY float
);


create clustered index ix1_timetable on timetable (id)


DECLARE @start DATETIME;
DECLARE @end DATETIME;

SET @start = '20190201';
SET @end = '20210101';

WITH
    CTE_DT
    AS
    (
                    SELECT @start AS DT
        UNION ALL
            SELECT DATEADD(MINUTE,10,DT)
            FROM CTE_DT
            WHERE DT< @end
    )
INSERT INTO Timetable
    (timestamp, datestamp, hourminutestamp, weekday)
SELECT DT --as timestamp
	, format(DT , 'yyyy-MM-dd') --as datestamp
    , cast(FORMAT(DATEADD(mi, DATEDIFF(mi, 0, DT)/5*5, 0),'HH%m') as float) --as hourminutestamp
	, DATEPART(dw,DATEADD(MINUTE,10,DT))-- as weekday
FROM CTE_DT
OPTION
(MAXRECURSION
0);


select top 1000
    *
from Timetable
where datestamp = '2019-02-06'
order by HOURMINUTESTAMP
