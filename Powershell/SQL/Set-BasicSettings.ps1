#Requires -Modules SqlServer
<#
.SYNOPSIS
    .
.DESCRIPTION
Set-basicsettings  .
.PARAMETER Server
    The instance of SQL Server as target .
#>

Param(
    [Parameter(Mandatory = $true)][String]$server, #SQL Server instance "Server"
      [Parameter(Mandatory = $false)][string]$cost = "40", # https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-cost-threshold-for-parallelism-server-configuration-option?view=sql-server-2017
    [Parameter(Mandatory = $false)][int]$sqlminfreememory = 4092 # sqlminfreememory or 10% of server memory.
)

#basic settings
#sqlmaxmem
$PysicalMemory = Get-WmiObject -class "win32_physicalmemory" -namespace "root\CIMV2" -ComputerName $server 
$PysicalMemoryMB = $((($PysicalMemory).Capacity | Measure-Object -Sum).Sum / 1MB)
if (($PysicalMemoryMB * 0.1) -le $sqlminfreememory) {
    $sqlmaxmem = $sqlminfreememory
} else {
    $sqlmaxmem = $PysicalMemoryMB * 0.9
}
$date = Get-Date
Write-Host "$date : PysicalMemoryMB: $PysicalMemoryMB" 
Write-Host "$date : sqlmaxmem: $sqlmaxmem"


#mdop
$NumberOfCores = (Get-WmiObject -class Win32_processor -ComputerName $server).NumberOfCores 
if ($NumberOfCores -le 3) {
    # if cores less then 3 mdop = 1
    $mdop = "1"
} elseif (($NumberOfCores -gt 3) -and ($NumberOfCores -le 9)) {
    # if cores < 9 and > 3 mdop = 2
    $mdop = "2"
} elseif ($NumberOfCores -ge 8) {
    $mdop = "4"
} else {
    # else 
    $mdop = "1"
}

$date = Get-Date
Write-Host "$date : mdop: $mdop"
Write-Host "$date : NumberOfCores: $NumberOfCores"

$query = "EXEC sys.sp_configure 'show advanced options', 1;"
$date = Get-Date
Write-Host "$date : Query: $query"
Invoke-sqlcmd -ServerInstance $server -Query $query
$query = "Reconfigure;"
$date = Get-Date
Write-Host "$date : Query: $query"
Invoke-sqlcmd -ServerInstance $server -Query $query
$query = "EXEC sys.sp_configure 'cost threshold for parallelism', $cost"
$date = Get-Date
Write-Host "$date : Query: $query"
Invoke-sqlcmd -ServerInstance $server -Database "master" -Query $query
$query = "EXEC sys.sp_configure 'max degree of parallelism', $mdop;"
$date = Get-Date
Write-Host "$date : Query: $query"
Invoke-sqlcmd -ServerInstance $server -Database "master" -Query $query
$query = "EXEC sys.sp_configure 'max server memory (MB)', $sqlmaxmem;"
$date = Get-Date
Write-Host "$date : Query: $query"
Invoke-sqlcmd -ServerInstance $server -Database "master" -Query "EXEC sys.sp_configure 'max server memory (MB)', $sqlmaxmem;"
