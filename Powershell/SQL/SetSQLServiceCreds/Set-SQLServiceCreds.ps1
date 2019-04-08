function Set-SQLServiceCreds([String]$strComputerName, [String]$strNewUser, [String]$strNewPassword) {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | out-null
  
    $SMO = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $strComputerName
    $Service = $SMO.Services | where {$_.type -like 'SQL*' -and $_.Startmode -eq "Auto"}
    Write-Host 'Properties before Change'
    $Service | select name, ServiceAccount, DisplayName, StartMode  | Format-Table
    $Service.SetServiceAccount($strNewUser, $strNewPassword)

    Write-Host 'Properties after Change'
    $Service | select name, ServiceAccount, DisplayName, StartMode | Format-Table
    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name MSSQLServer  |
            Restart-Service -Verbose
    }
    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name SQLSERVERAGENT  |
            Restart-Service -Verbose
    }
}
