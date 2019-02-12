/* 
Loop trough tables/linked servers with dynamic sql used for building a dynamic view
*/

DECLARE @Table TABLE
(
TableName VARCHAR(500),
Id int identity(1,1)
)

INSERT INTO @Table
select '[' + name + '].database.dbo.table_name' as table_name from sys.servers  where is_linked = '1' and provider = 'sqlncli'

DECLARE @max int
DECLARE @SQL VARCHAR(MAX) 
DECLARE @TableName VARCHAR(500)
DECLARE @id int = 1

select @max = MAX(Id) from @Table


WHILE (@id <= @max)
BEGIN

SELECT @TableName = TableName FROM @Table WHERE Id = @id
SET @SQL =     'select * from '+ @TableName + '
union all '

set @SQL = left(@SQL, len(@SQL) - 10) --remove the last UNION ALL
PRINT(@SQL)  --COMMENT THIS LINE OUT AND COMMENT IN THE NEXT EXEC(@SQL) IF YOU SEE THE CORRECT OUTPUT
--EXEC(@SQL)
SET @id = @id +1
END

