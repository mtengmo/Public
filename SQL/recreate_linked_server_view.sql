CREATE PROCEDURE [dbo].[recreate_linked_server_view]
    @viewname    nvarchar(max),
    @tablename   nvarchar(max),
    @columns     nvarchar(max),
    @where    nvarchar(max)
AS
BEGIN

    /*
declare  @viewname    nvarchar(max)
set @viewname = 'testview'
declare  @tablename    nvarchar(max)
set @tablename = 'acrrepord_audit'
declare  @columns    nvarchar(max)
set @columns = '[timestamp],[datestamp],[hourminutestamp],[weekday],[databaseserver],[databasename],[report_name],[server_queue],[status],[count]'
declare  @where    nvarchar(max)
set @where = 'where status = ''n'''
*/



    DECLARE @SQL NVARCHAR(MAX)
    SELECT @SQL =  'create view ' + @viewname  + ' as ' + STUFF((
		    SELECT CHAR(13) + 'UNION ALL' + CHAR(13) + 'SELECT ' + @columns + ' FROM ' + quotename (s.name) + '.[perfdb].[dbo].' + quotename(@tablename) + ' ' + @where + ' '
        from sys.servers s
        where is_linked = 1
            and provider = 'SQLNCLI'
            and name like 'pd%'
        for xml path(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,11,'')

    print @sql

    DECLARE @SQL2 NVARCHAR(MAX)
    SELECT @SQL2 = 'drop view if exists ' + @viewname  + CHAR(13) + ''

    exec sp_executesql @SQL2
    exec sp_executesql @sql
