# Made togheter with ChatGPT :)
# Maybe 20-30 iterations
# The script is used to generate a SQL Server restore script from the latest backup files stored in an Azure Blob Storage container.
# The script takes the following parameters:
# - StorageAccountName: The name of the Azure Storage Account where the backup files are stored.
# - ContainerName: The name of the container within the Azure Storage Account where the backup files are stored.
# - LocalBackupPath: The local path where the generated restore script will be saved.
# - DefaultDataPath: The default path where the data files will be restored.
# - DefaultLogPath: The default path where the log files will be restored.
# - FromDatabase: The name of the database to restore. If specified, only the restore script for this database will be generated.
   
function Generate-SqlRestoreScriptFromBlob {
    param (
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$LocalBackupPath,
        [string]$DefaultDataPath = "",
        [string]$DefaultLogPath = "",
        [string]$FromDatabase = "",
        [string]$SqlInstance = "localhost"
    )

    # Check if already authenticated
    $azContext = Get-AzContext
    if (-not $azContext) {
        Write-Host "Authenticating to Azure..."
        Connect-AzAccount
    }
    else {
        Write-Host "Already authenticated to Azure."
    }

    # Get the storage account context using the authenticated user
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName

    # Get list of blob files from Azure Blob Storage container
    $blobs = Get-AzStorageBlob -Context $ctx -Container $ContainerName

    # Initialize hashtable to store latest backup and log files for each database
    $backupFilesHash = @{}

    # Filter and select backup and log files
    foreach ($blob in $blobs) {
        if ($blob.Name -match "^(?<DatabaseName>[^_]+)_[^_]+_(?<Timestamp>\d{14})(\+\d{2})?\.(?<Extension>bak|log)$") {
            $databaseName = $matches["DatabaseName"]
            $timestamp = $matches["Timestamp"]
            $extension = $matches["Extension"]
            $fileName = $blob.Name

            # Parse the timestamp
            $timestampParsed = [datetime]::ParseExact($timestamp, "yyyyMMddHHmmss", $null)

            if ($extension -eq "bak") {
                # If the database is not in the hashtable or if the current bak file is newer, update the entry
                if (-not $backupFilesHash.ContainsKey($databaseName) -or $backupFilesHash[$databaseName].Timestamp -lt $timestampParsed) {
                    $backupFilesHash[$databaseName] = @{
                        DatabaseName = $databaseName
                        FileName = $fileName
                        Timestamp = $timestampParsed
                        Extension = $extension
                        LogFiles = @()
                    }
                }
            } elseif ($extension -eq "log") {
                # If the database is not in the hashtable, create an entry with an empty bak file
                if (-not $backupFilesHash.ContainsKey($databaseName)) {
                    $backupFilesHash[$databaseName] = @{
                        DatabaseName = $databaseName
                        FileName = ""
                        Timestamp = $timestampParsed
                        Extension = ""
                        LogFiles = @()
                    }
                }
                # Append the log file to the LogFiles array
                $backupFilesHash[$databaseName].LogFiles += @{
                    FileName = $fileName
                    Timestamp = $timestampParsed
                }
            }
        }
    }

    # Sort the hash table by database name
    $sortedBackupFilesHash = $backupFilesHash.GetEnumerator() | Sort-Object Name

    # Generate SQL Server restore script based on the backup files
    $restoreScript = ""
    foreach ($entry in $sortedBackupFilesHash) {
        $backupFile = $entry.Value

        # Skip if the FromDatabase parameter is specified and the current database doesn't match
        if ($FromDatabase -and $backupFile.DatabaseName -ne $FromDatabase) {
            continue
        }

        $restoreScript += "/* Restore sequence for database [$($backupFile.DatabaseName)] */`n"
        if ($backupFile.FileName -ne "") {
            $backupUrl = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$($backupFile.FileName)"

            $restoreScript += "RESTORE DATABASE [$($backupFile.DatabaseName)] FROM URL = '$backupUrl' WITH REPLACE, NORECOVERY"

            # Add MOVE options if default paths are specified
            if ($DefaultDataPath -ne "") {
                $restoreScript += ", MOVE '$($backupFile.DatabaseName)' TO '$DefaultDataPath\$($backupFile.DatabaseName).mdf'"
            }
            if ($DefaultLogPath -ne "") {
                $logicalLogFileName = "$($backupFile.DatabaseName)_log"
                $restoreScript += ", MOVE '$logicalLogFileName' TO '$DefaultLogPath\$($backupFile.DatabaseName)_Log.ldf'"
            }

            $restoreScript += ";" + "`n"
        }
        if ($backupFile.LogFiles.Count -gt 0) {
            foreach ($logFile in $backupFile.LogFiles | Sort-Object Timestamp) {
                $restoreScript += "RESTORE LOG [$($backupFile.DatabaseName)] FROM URL = 'https://$StorageAccountName.blob.core.windows.net/$ContainerName/$($logFile.FileName)' WITH NORECOVERY;" + "`n"
            }
        }
        # Add final recovery step for this database
        $restoreScript += "RESTORE DATABASE [$($backupFile.DatabaseName)] WITH RECOVERY;" + "`n"
        $restoreScript += "/* End of restore sequence for database [$($backupFile.DatabaseName)] */`n`n"

        # Exit loop if FromDatabase parameter is specified
        if ($FromDatabase) {
            break
        }
    }

    # Save restore script to a file
    $restoreScript | Out-File -FilePath "$LocalBackupPath\RestoreScript.sql" -Encoding ASCII

    Write-Host "Restore script generated successfully and saved to: $LocalBackupPath\RestoreScript.sql"
}

connect-azaccount -devicecode -Subscription xxxx  -Tenantid xxxx
Update-AzConfig -EnableLoginByWam $false
Generate-SqlRestoreScriptFromBlob -StorageAccountName stotbdvoxprodonprbkpeuw -ContainerName sesql31visma -LocalBackupPath c:\backup -DefaultDataPath "C:\Program Files\Microsoft SQL Server\MSSQL15\MSSQL\DATA" -DefaultLogPath "C:\Program Files\Microsoft SQL Server\MSSQL15\MSSQL\DATA"

