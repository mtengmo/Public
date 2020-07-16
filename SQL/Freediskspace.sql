SELECT DISTINCT @@servername, dovs.logical_volume_name AS LogicalName,
    dovs.volume_mount_point AS Drive,
    CONVERT(INT,dovs.available_bytes/1048576.0) AS FreeSpaceInMB,
    CONVERT(INT,dovs.total_bytes/1048576.0) AS total_bytesInMB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
ORDER BY FreeSpaceInMB ASC
GO
