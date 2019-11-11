use PerfDB
exec dba_ForEachDB_Custom @statement = 'begin try
exec sp_a46_agrqueuecheck
end try
begin catch
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @DBNAME NVARCHAR(128);
	SET @DBNAME = DB_NAME();
	  
    SET @ErrorMessage =  ''Problem with db: '' + @DBNAME + '' Error: '' + ERROR_MESSAGE()
	
RAISERROR(@ErrorMessage, 16, 1)
--RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
		
end catch
', @status = 'prod', @type = 'agr'

