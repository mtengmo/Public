DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX)

select @cols = STUFF((SELECT distinct ',' + QUOTENAME((servername))
    from vmsdb_sysjobs
    FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT name, ' + @cols + ' , Total
            from 
            (
               select name, 
            
				 (p.servername) enabled,
                count(*) over(partition by name) Total
               from vmsdb_sysjobs p
			   where enabled = ''1''
                       ) x
            pivot 
            (
                count(enabled)
                for enabled in (' + @cols + ')
            ) p 
            where name is not null
            order by name'

--select @query
execute(@query)