function Set-SQLServiceCreds([String]$strComputerName, [String]$strNewUser, [String]$strNewPassword) {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | out-null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")| out-null
    
    
    $SMO = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $strComputerName
    $Service = $SMO.Services | where {$_.type -like 'SQLServer'}
    $ServiceAgent = $SMO.Services | where {$_.type -like 'SQLAgent*'}
#    $SMO.Services
    Write-Host 'Properties before Change'
    $Service | select name, ServiceAccount, DisplayName, StartMode  | Format-Table
    $Service.SetServiceAccount($strNewUser,$strNewPassword)
    $ServiceAgent.SetServiceAccount($strNewUser,$strNewPassword)

    Write-Host 'Properties after Change'
    $Service | select name, ServiceAccount, DisplayName, StartMode | Format-Table
    $ServiceAgent | select name, ServiceAccount, DisplayName, StartMode | Format-Table

    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name MSSQLServer  |
            Restart-Service -Verbose -force
    }
    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name SQLSERVERAGENT  |
            Restart-Service -Verbose
    }
}
