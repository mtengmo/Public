-- Define variables for source and destination database
ALTER DATABASE [agrtest] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

DECLARE @SourceDatabase NVARCHAR(100) = 'agrprod'
DECLARE @TargetDatabase NVARCHAR(100) = 'agrtest'
DECLARE @BackupFolder NVARCHAR(255) = 'e:\Restore\' -- Adjust to your backup file location

-- Define paths for the restored database files
DECLARE @DataPath NVARCHAR(255) = 'F:\MSSQL15.MSSQLSERVER\MSSQL\Data\agrtest_Data.mdf'
DECLARE @LogPath NVARCHAR(255) = 'G:\MSSQL15.MSSQLSERVER\MSSQL\Log\agrtest_Log.ldf'

-- List of backup files
DECLARE @BackupFiles TABLE (FileName NVARCHAR(255), FileType NVARCHAR(10)) -- FileType can be 'FULL' or 'LOG'

INSERT INTO @BackupFiles (FileName, FileType)
VALUES
    ('agrprod_backup_2024_11_24_000002_9168853.bak', 'FULL'),
    ('agrprod_backup_2024_11_24_003002_6805441.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_013002_3593939.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_023002_9187000.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_033003_2592699.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_043002_4833118.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_053003_1293599.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_063002_9875646.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_073002_0943931.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_083002_7032765.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_093002_0725256.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_103002_6724094.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_113002_4969271.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_123003_4500500.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_133001_9743246.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_143001_8339391.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_153002_6534999.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_163006_0273496.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_173003_0372605.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_183002_3583183.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_193002_8477274.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_203002_1854148.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_213002_1938850.trn', 'LOG'),
    ('agrprod_backup_2024_11_24_223001_6376715.trn', 'LOG') ;

-- Restore the full backup with MOVE and NORECOVERY
DECLARE @FileName NVARCHAR(255), @FileType NVARCHAR(10)
SELECT TOP 1 @FileName = FileName, @FileType = FileType
FROM @BackupFiles WHERE FileType = 'FULL'

DECLARE @FullBackupPath NVARCHAR(255) = @BackupFolder + @FileName

PRINT 'Restoring Full Backup: ' + @FullBackupPath

RESTORE DATABASE @TargetDatabase
FROM DISK = @FullBackupPath
WITH MOVE 'agrprod_Data' TO @DataPath,  -- Replace 'agrprod_Data' with the logical name of the data file in the source database
     MOVE 'agrprod_Log' TO @LogPath,   -- Replace 'agrprod_Log' with the logical name of the log file in the source database
     NORECOVERY, REPLACE, STATS = 10;

-- Restore transaction logs in sequence
DECLARE BackupCursor CURSOR FOR
SELECT FileName FROM @BackupFiles WHERE FileType = 'LOG' ORDER BY FileName

OPEN BackupCursor
FETCH NEXT FROM BackupCursor INTO @FileName

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @LogBackupPath NVARCHAR(255) = @BackupFolder + @FileName
    PRINT 'Restoring Transaction Log: ' + @LogBackupPath

    RESTORE LOG @TargetDatabase
    FROM DISK = @LogBackupPath
    WITH NORECOVERY, STATS = 10;

    FETCH NEXT FROM BackupCursor INTO @FileName
END

CLOSE BackupCursor
DEALLOCATE BackupCursor

-- Restore database with RECOVERY
PRINT 'Finalizing Database Restore with RECOVERY'
RESTORE DATABASE @TargetDatabase WITH RECOVERY;

