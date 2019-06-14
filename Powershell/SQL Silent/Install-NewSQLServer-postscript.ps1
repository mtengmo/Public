#Requires -Modules SqlServer
<#
.SYNOPSIS
    .
.DESCRIPTION
.\Install-NewSQLserver.ps1 -server "sqlserver"     .
.PARAMETER Server
    The instance of SQL Server as target .
.PARAMETER scriptpath
    $server,  #SQL Server instance "Server\instance
#>

Param(
    [Parameter(Mandatory = $true)][String]$server, #SQL Server instance "Server\instance"
    [System.Management.Automation.PSCredential]$LoginPSCredential      

)
$date = Get-Date
Write-Host "$Date : Start postscripting..."

$scriptpath_perfdb = "$PSScriptRoot\Perfdb"
$scriptpath_maintancejobs = "$PSScriptRoot\MaintanceJobs"

#Perfdb
$DatabaseName = "perfdb"
$loginname = $DatabaseName

#Dskunder hardcoded server
$dskunderinstance = 'managementserver' 


if (Get-Module -Name SQLServer) {
    Write-Host "Module SQLServer exists"
}
else {
    Write-Host "Module does not exist, installing module"
    #need to be admin
    Install-module SQLServer
}

# This function determines whether a database exists in the system.
function New-SQLDatabase {
    [cmdletbinding()]
    Param
    (
        # set variables for the database
        [string]$Server                      #server name to create the db
        , [string]$DatabaseName                      #database name
        , [double]$NumberOfFilesInUserFilegroup      #number of files in the user filegroup
 
        # optional db variables
        , [boolean]$UseDefaultFileLocations = $true
        , [string]$NonDefaultFileLocation
        , [string]$NonDefaultLogLocation
        , [string]$Collation
        , [string]$RecoveryModel
        , [string]$DatabaseOwner = "sa"
 
        #set the user data size, maxsize and growth
        , [double]$UserDataFileSize
        , [double]$USerDataFileMaxSize
        , [double]$UserDataFileGrowth #use 0 for no growth
 
        #set the log size and growth
        , [double]$LogSize
        , [double]$LogGrowth
 
        #set the primary file size in MB (will be converted to kb later)
        , [double]$PrimaryFileSize = 10
        , [double]$PrimaryFileGrowth = 10
        , [double]$PrimaryFileMaxSize = 100
    )
 
    #set the error action to stop on any errors
    $ErrorActionPreference = "Stop"
 
    #Verbose message to show the server
    $Message = "Instantiating smo object for server $Server"
    Write-Verbose $Message
 
    #instantiate the sql server object
    Write-Host $server
    $SQLServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Server
    $SQLServer.ConnectionContext.StatementTimeout = 600
    
    # if we are using the default file locations, get them from the server
    if ($UseDefaultFileLocations -eq $true) {
        #get the default file locations; if the master is in the default location we use that path as the default file will not be set
        $LocalDataDrive = if ($SQLServer.DefaultFile -eq [DBNULL]::value)
        { $SQLServer.MasterDBPath }
        else
        { $SQLServer.DefaultFile }
        $LocalLogDrive = $SQLServer.DefaultLog
    }
    elseif ($UseDefaultFileLocations -eq $false -and ($NonDefaultFileLocation -eq $Null -or $NonDefaultLogLocation -eq $Null)) {
        Write-Error "Non Default file locations selected, but are not supplied"
    }
 
    #output message in verbose mode
    $Message = "Setting local Data drive to $LocalDataDrive and local log drive to $LocalLogDrive"
    write-verbose $Message
 
    #check to see if the database already exists.
    if ($SQLServer.Databases[$DatabaseName].Name -ne $Null) {
        Write-Host "Database $DatabaseName already exists on $Server" -ForegroundColor Yellow
    }
    else {
     
 
        #create the new db object
        $Message = "Creating smo object for new database $DatabaseName"
        Write-Verbose $Message
        $NewDB = New-Object Microsoft.SqlServer.Management.Smo.Database($SQLServer, $DatabaseName)
 
        #add the primary filegroup and a primary file
        $Message = "Creating PRIMARY filegroup"
        Write-Verbose $Message
 
        $PrimaryFG = new-object Microsoft.SqlServer.Management.Smo.Filegroup($NewDB, "PRIMARY")
        $NewDB.Filegroups.Add($PrimaryFG)
 
        #add the primary file
        $PrimaryFileName = $DatabaseName + "_PRIMARY"
        $Message = "Creating file name $PrimaryFileName in filegroup PRIMARY"
        Write-Verbose $Message
        #create the filegroup object
        $PrimaryFile = new-object Microsoft.SqlServer.Management.Smo.DataFile($PrimaryFG, $PrimaryFileName)
        $PrimaryFile.FileName = $LocalDataDrive + "\" + $PrimaryFileName + ".mdf"
        $PrimaryFile.Size = ($PrimaryFileSize * 1024)
        $PrimaryFile.GrowthType = "KB"
        $PrimaryFile.Growth = ($PrimaryFileGrowth * 1024)
        $PrimaryFile.MaxSize = ($PrimaryFileMaxSize * 102400)
        $PrimaryFile.IsPrimaryFile = "true"
        #add the file to the filegroup
        $PrimaryFG.Files.Add($PrimaryFile)
 
        #add the user data file group
        $UserFilegroupName = $DatabaseName + "_MainData"
        $Message = "Creating user filegroup $UserFileGroupName"
        Write-Verbose $Message
 
        $UserFG = new-object Microsoft.SqlServer.Management.Smo.Filegroup($NewDB, $UserFilegroupName)
        $NewDB.Filegroups.Add($UserFG)
 
        #add the required number of files to the filegroup in a loop
        #set the filecounter
        $FileCounter = 1
 
        #open a loop while the filecounter is less than the required number of files
        While ($FileCounter -le $NumberOfFilesInUserFilegroup) {
            #Set the file name
            $UserFileName = $UserFileGroupName + "_" + [string]$FileCounter
            $Message = "Creating file name $UserFileName in filegroup $UserFileGroupName"
            Write-Verbose $Message
            #create the smo object for the file
            $UserFile = new-object Microsoft.SQLServer.Management.Smo.Datafile($UserFG, $UserFileName)
            $UserFile.FileName = $LocalDataDrive + "\" + $USerFileName + ".ndf"
            $UserFile.Size = ($UserDataFileSize * 1024)
            $UserFile.GrowthType = "KB"
            $UserFile.Growth = ($UserDataFileGrowth * 1024)
            $UserFile.MaxSize = ($USerDataFileMaxSize * 1024)
            #add the file to the filegroup
            $UserFG.Files.Add($UserFile)
            #increment the file counter
            $FileCounter = $FileCounter + 1
        }
 
        #now create the log file
        $LogName = $DatabaseName + "_Log"
        $Message = "Creating log $LogName"
        Write-Verbose $Message
        #add the log to the db
        $TLog = new-object Microsoft.SqlServer.Management.Smo.LogFile($NewDB, $LogName)
        $TLog.FileName = $LocalLogDrive + "\" + $LogName + ".ldf"
        $TLog.Size = ($LogSize * 1024)
        $TLog.GrowthType = "KB"
        $TLog.Growth = ($LogGrowth * 1024)
        #add the log to the db
        $NewDB.LogFiles.Add($TLog)
 
        #set database settings; collation, owner, recovery model
 
        #set the collation
        if ($Collation.Length -eq 0) {
            $Message = "USing default server collation"
            Write-Verbose $Message
        }
        else {
            $Message = "Setting collation to $Collation"
            Write-Verbose $Message
            $NewDB.Collation = $Collation
        }
 
        #set the recovery model
        if ($RecoveryModel.Length -eq 0) {
            $Message = "Using default recovery model from the Model database"
            Write-Verbose $Message
        }
        else {
            $Message = "Setting recovery model to $RecoveryMode"
            Write-Verbose $Message
            $NewDB.RecoveryModel = $RecoveryModel
        }
 
        #we should now be able to create the db, and run any other config settings afterwards
        $Message = "Creating Datbase $DatabaseName"
        Write-Verbose $Message
        $NewDb.Create()
 
        #now do post db creation work, set the dbowner and set the default filegroup
        #Set the owner
        $Message = "Setting database owner to $DatabaseOwner"
        Write-Verbose $Message
        $NewDB.SetOwner($DatabaseOwner)
 
        #set the user filegroup to be the default
        $Message = "Setting default filegroup to $UserFileGroupName"
        Write-Verbose $Message
        $NewDB.SetDefaultFileGroup($UserFileGroupName)
 
        #Write completed message
        $Message = "Completed creating database $DatabaseName"
        Write-Output $Message
 
        #reset the error action
        $ErrorActionPreference = "Continue"
    }
}
 


Function Invoke-SQLfile {
    Param(
        [Parameter(Mandatory = $true)][string]$server
        , [Parameter(Mandatory = $true)][string]$databasename
        , [Parameter(Mandatory = $true)][string]$scriptfile
    )

       
    try {
        $date = Get-Date
        Write-Host "$date : Execute $scriptfile on server $server.$databasename"
        Invoke-SqlCmd -ServerInstance $server -Database $DatabaseName -inputfile $scriptfile -OutputSqlErrors $true -verbose -DisableVariables -QueryTimeout 600 -ConnectionTimeout 60
    }
    catch [Exception] {
        Write-Warning "Get-ExecuteScripts (Connection: [$server].[$databasename])"
        Write-Warning $_.Exception.Message
        Write-Warning "Query: $getscriptinfo --Id $scriptfile"
    }
    finally {
    }
}

$date = Get-Date
Write-Host "$Date : New DB"
New-SQLDatabase -Server $server -DatabaseName $DatabaseName -NumberOfFilesInUserFilegroup 4 -UserDataFileSize 256 -UserDataFileMaxSize 10240 -UserDataFileGrowth 256 -LogSize 256 -LogGrowth 256
Start-Sleep 60

$logins = Get-SqlLogin -ServerInstance $server
if ($logins.name -eq $loginname) {
    Write-host "login $loginname exists"
}
else {
    #Write-Host "Set SQL Login perfdb password" -ForegroundColor green 
    if (-not $LoginPSCredential) {
        $LoginPSCredential = Get-credential -UserName $loginname -Message "enter password"
    }
    Write-Host "Adding SQL Login: $loginname" -ForegroundColor green
    Add-SqlLogin -Server $server  -logintype "sqllogin" -defaultdatabase $DatabaseName -LoginPSCredential $LoginPSCredential -Enable -GrantConnectSql 

    Write-Host "Adding user $loginname to $loginname on $databasename" -ForegroundColor green
    Invoke-sqlcmd -ServerInstance $server -Database $DatabaseName -Query "CREATE USER [$loginname] FOR LOGIN [$loginname]"
    Write-Host "Adding role db_owner to $loginname on $databasename" -ForegroundColor green
    Invoke-sqlcmd -ServerInstance $server -Database $DatabaseName -Query "EXEC sp_addrolemember 'db_owner', '$loginname'"

    Write-Host "Adding user $loginname to $loginname on msdb" -ForegroundColor green
    Invoke-sqlcmd -ServerInstance $server -Database "msdb" -Query "CREATE USER [$loginname] FOR LOGIN [$loginname]"
    Write-Host "Adding role db_reader to $loginname on msdb" -ForegroundColor green
    Invoke-sqlcmd -ServerInstance $server -Database "msdb" -Query "EXEC sp_addrolemember 'db_datareader', '$loginname'"
}


#Create tables and logins
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\1 DB and Logins.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\2 Tables for perfdb.sql"
#SQL Jobs 3*
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3a PerfDB_info.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3b PerfDB_RefreshTotal.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3c Run number of connections.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3d Set DB Permission to AD Groups.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3e Sp_whoisactive.sql"
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3f waitstatsnew.sql"
#Start sleep until waitstats have run
Write-Host "Start sleeping 610s, waiting for waitstats data to clean..."
Start-Sleep 610
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\3g waitstats_clean_first_group.sql"

# 10
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\10 Upgrade_perfdb_ver2.sql"
# last step
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile "$scriptpath_perfdb\6 Update SQLJOB to write status to eventlog.sql"



#MaintanceJobs
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\01_Basic_Server_Settings.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\02_MaintenanceSolution.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\03_OlaHallengreen_Cleanup_Existing.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_01.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_02.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_03.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_04.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_05.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_06.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\04_Maintenance_Tasks_Creation_part_07.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\05_Cycle_Errorlog.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\05_Other_Maintenence_Tasks.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\06_DatabaseBackupCheckJob.sql
Invoke-SQLfile -database $DatabaseName -server $server -scriptfile $scriptpath_maintancejobs\06_DatabaseStatusCheckjob.sql

#Linked server
$date = Get-Date
Write-Host "$date : Adding linked server... $server on $dskunderinstance"

$pw = $LoginPSCredential.GetNetworkCredential().Password
$querydropremoteserver = "IF EXISTS(SELECT * FROM sys.servers WHERE name = N'$server')
EXEC master.sys.sp_dropserver '$server','droplogins'  
GO"
$querylinkedserver1 = "EXEC master.dbo.sp_addlinkedserver @server = '$server', @srvproduct=N'SQL Server'"
$querylinkedserver2 = "EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname='$server',@useself=N'False',@locallogin=NULL,@rmtuser=N'perfdb',@rmtpassword='$pw'"

Invoke-sqlcmd -server $dskunderinstance $querydropremoteserver -database master
Invoke-sqlcmd -server $dskunderinstance $querylinkedserver1 -database master
Invoke-sqlcmd -server $dskunderinstance $querylinkedserver2  -database master

#Finish
$date = Get-Date
Write-Host "$date : Stop postscripting..."
