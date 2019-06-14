#Requires -Modules SqlServer
#requires -version 2
<#
.SYNOPSIS
  Silent installation of SQL server
.DESCRIPTION
  Silent installation of SQL server
  $computername = target new empty sql server
  $file = path to master sql server file
  $sapwd = "SA password"

  #Version 1 - Final
  #Version 1.1 small fixes
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [ValidateLength(1, 11)][Parameter(Mandatory = $true)][string]$computername,
    [Parameter(Mandatory = $false)][string]$file = "\\fileserver\d$\ISO\SQL\SQLISO\2016",
    [Parameter(Mandatory = $false)][String]$path = "OU=SQL Access,OU=Global Groups,DC=domain,DC=se",
    [System.Management.Automation.CredentialAttribute()]$Credential,
    [Parameter(Mandatory = $true)][string]$sapwd,
    [Parameter(Mandatory = $false)][string]$addomain = "domain",
    [Parameter(Mandatory = $false)][string]$sqlcollation = 'Finnish_Swedish_CI_AS'

)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

function Clear-KerberosTicket {
    #http://blogs.technet.com/b/tspring/archive/2014/06/23/viewing-and-purging-cached-kerberos-tickets.aspx
    #https://gallery.technet.microsoft.com/scriptcenter/Clear-Kerberos-Ticket-on-18764b63
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Computer name variable
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $ComputerName,

        # Session Name (Local System or Network Service)
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('LocalSystem', 'NetworkService')]
        $SessionName
    )

    Begin {
        switch ($SessionName) {
            'LocalSystem' { $ID = '0x3e7' }
            'NetworkService' { $ID = '0x3e4' }
            Default { Write-Error 'Invalid Session Name' -ErrorAction Stop }
        }
    } # End Begin
    Process {
        foreach ($Computer in $ComputerName) {
            $date = Get-Date
            Write-Verbose "$Date : Attempting to connnect to $Computer"
            If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                Write-Verbose "Clearing Kerberos Ticket on $Computer for $SessionName"
                $Result = invoke-command -ComputerName $Computer -ScriptBlock { klist -li $Using:ID purge }
                If ($Result[4].TrimStart() -like 'Ticket(s) Purged!') {
                    $date = Get-Date
                    Write-Output "$Date : Success - $Computer"
                }
                Else {
                    Write-Warning "Failure - $Computer"
                } # End If
            }
            Else {
                Write-Warning "Unable to connect to $Computer"
            } # End If
        } # End Foreach
    } # End Process
} # End Clear-KerberosTicket

function Set-SQLServiceCreds([String]$strComputerName, [String]$strNewUser, [String]$strNewPassword) {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | out-null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
    
    
    $SMO = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $strComputerName
    $Service = $SMO.Services | Where-Object { $_.type -like 'SQLServer' }
    $ServiceAgent = $SMO.Services | Where-Object { $_.type -like 'SQLAgent*' }
    #    $SMO.Services
    $date = Get-Date
    Write-Output "$Date : Properties before Change"
    $Service | Select-Object name, ServiceAccount, DisplayName, StartMode | Format-Table
    $Service.SetServiceAccount($strNewUser, $strNewPassword)
    $ServiceAgent.SetServiceAccount($strNewUser, $strNewPassword)

    $date = Get-Date
    Write-Output "$Date : Properties after Change"
    $Service | Select-Object name, ServiceAccount, DisplayName, StartMode | Format-Table
    $ServiceAgent | Select-Object name, ServiceAccount, DisplayName, StartMode | Format-Table
    $SMO
    $date = Get-Date
    Write-Output "$Date : Closing SMO.."
    Remove-Variable -Name SMO

    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name MSSQLServer |
        Restart-Service -Verbose -force
    }
    Invoke-Command -Computer $strComputerName -ScriptBlock {
        Get-Service -Name SQLSERVERAGENT |
        Restart-Service -Verbose -Force
    }

}


#Start
$date = Get-Date
Write-Output "$Date : Start binaries..."

$computername = $computername.tolower()
$accountname = "svc-$computername"
$MaxLength = 15 # samaccountname max lenght
if ($accountname.Length -gt $MaxLength) {
    $accountname = $accountname.Substring(0, $MaxLength)
}
else {
    $accountname
} 

$credential = Get-Credential -Message "enter your own admin account for target server"
$LoginPSCredential = Get-credential -UserName perfdb -Message "enter sql password for perfdb sqllogin"

#PS session
$session = New-PSSession -ComputerName $computerName 
#-Authentication CredSSP -Credential $credential
# domain admin


#Create MSA account in AD
try {
    New-ADServiceAccount -Name $accountname -Path "cn=Managed Service Accounts, dc=domain,dc=se" -enabled $true -RestrictToSingleComputer -Verbose
} 
catch {
    Write-Warning "Failed to create user: $accountname $($error[0])"
    #Throw
}


while ($running -eq $null) {
    if ($CheckUser -le '10') {
        $CheckUser++
        start-sleep -s 10
        $running = Get-ADServiceAccount -Identity $accountname
    }
    else {
        Throw "Unable to create $accountname serviceaccount"
    }
}

try {
    Add-AdComputerServiceAccount -Identity $computername -ServiceAccount $accountname -Verbose
}
catch {
    Write-Warning "Failed to create user: $accountname $($error[0])"
}

# group msa
#Set-ADServiceAccount -Identity $accountname -PrincipalsAllowedToRetrieveManagedPassword $computername


# Enable CredSSP on the local workstation, to communicate with the system for which we install MSA
Enable-WSManCredSSP -Role Client -DelegateComputer $computername -Force
# Enable CredSSP on target machine
Invoke-Command -Session $session -scriptblock { Enable-PSRemoting -Force }
Invoke-Command -Session $session -ScriptBlock { Enable-WSManCredSSP -Role Server -Force } 
#Invoke-Command -Session $session -ScriptBlock {Enable-WSManCredSSP -role Client -DelegateComputer $computername  -Force} 
$session2 = New-PSSession -ComputerName $computerName -Credential $credential -Authentication CredSSP

# Add MSA account locally on target
Invoke-Command -cn $computername -Authentication Credssp -Credential $credential -ScriptBlock { param($account)
    #try to install service account
    # https://www.reddit.com/r/PowerShell/comments/3icmt6/installadserviceaccount_unable_to_use_remoting/
    # https://www.codeproject.com/Tips/847119/Resolve-Double-Hop-Issue-in-PowerShell-Remoting
    
    Import-Module ActiveDirectory;
    Install-ADServiceAccount -Identity $account -Verbose
    $date = Get-Date
    Write-Output "$date Installed ADServiceAccount : $account" -ForegroundColor Green;
} -ArgumentList $accountname

#Creating AD groups for SQL admins
try {
    New-ADGroup -Name "sql-$computername-sysadm" -GroupCategory security -GroupScope global -Path $path -verbose
}
catch {
    Write-Warning "Failed to create group: sql-$computername-sysadm $($error[0])"
}
try {
    New-ADGroup -Name "sql-$computername-readall" -GroupCategory security -GroupScope global -Path $path -verbose
}
catch {
    Write-Warning "Failed to create group: sql-$computername-readall $($error[0])"
}
try {
    New-ADGroup -Name "sql-$computername-writeall" -GroupCategory security -GroupScope global -Path $path -verbose
}
catch {
    Write-Warning "Failed to create group: sql-$computername-writeall $($error[0])"
} 

# sql silent
$destpath = "c:\install"
$testfile = "2016\ConfigurationFile.ini"
$test = "$destpath\$testfile"
$existsOnRemote = Invoke-Command -Session $session2 { param($fullpath) Test-Path $fullPath } -argumentList $test; 
$testsource = Test-Path "filesystem::$file" -Verbose

if (-not $testsource) { Write-Error "No source"; throw } 
if (-not $existsOnRemote) {
    try {
        $date = Get-Date
        Write-Output "$Date : Start copy files, takes time...."
        Invoke-Command -Session $session2 -scriptblock { param($destpath)New-Item -ItemType directory -Path $destpath -Force -Verbose } -argumentList $destpath
    }
    catch {
        Throw
    }
    $copied = Copy-Item -Path $file -ToSession $session2 -Destination $destpath -recurse -Force -PassThru
    $Date = Get-Date
    Write-Output "$Date Copied $copied.fullname"
}  

Write-Output "Get-adcomputer -Identity $computerName -properties *"
Get-adcomputer -Identity $computerName -properties * | Format-List

$adserviceaccount = Get-ADServiceAccount -Identity svc-sqlmagnus$ -Properties serviceprincipalnames
$adserviceaccount.serviceprincipalnames
$computer = get-adcomputer -Identity sqlmagnus -Properties "serviceprincipalname"
$computer.serviceprincipalname

#PS session
#Clear-KerberosTicket -ComputerName $computername -SessionName LocalSystem -Verbose
#klist purge
Remove-PSSession $session
$session = New-PSSession -ComputerName $computerName -Authentication CredSSP -Credential $credential




#https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-2017#Accounts
$date = Get-Date
$sqlsvcaccount = "NT Service\MSSQL$MSSQLSERVER"
$agtsvcaccount = $sqlsvcaccount
$arguments = "/ConfigurationFile=c:\install\2016\ConfigurationFile.ini /SAPWD=$sapwd /SECURITYMODE=SQL /SQLCOLLATION=$sqlcollation /INSTANCEDIR=D:\"
$date = Get-Date
Write-Output "$date : Starting SQL installation with arguments: $arguments"
Invoke-Command -Session $session2 -ScriptBlock { param($arguments)start-process -filepath c:\install\2016\setup.exe $arguments -Verb RunAs -wait } -ArgumentList $arguments 
$date = Get-Date 
Write-Output "$date : Start sleep 30s after sql installation"
Start-Sleep 30 # wait for WMI
$adserviceaccount = Get-ADServiceAccount -Identity svc-sqlmagnus$ -Properties serviceprincipalnames
$adserviceaccount.serviceprincipalnames
$computer = get-adcomputer -Identity sqlmagnus -Properties "serviceprincipalname"
$computer.serviceprincipalname

#Change to MSA account and restart service
Set-SQLServiceCreds -strComputerName $computername -strNewUser "$addomain\$accountname$" -strNewPassword "xxxVASD#45" # password not needed for MSA account, so use hardcoded to "xxx"

Start-Sleep 10
$adserviceaccount = Get-ADServiceAccount -Identity svc-sqlmagnus$ -Properties serviceprincipalnames
$adserviceaccount.serviceprincipalnames
$computer = get-adcomputer -Identity sqlmagnus -Properties "serviceprincipalname"
$computer.serviceprincipalname


#CIM Session for FW
$CIMsession = New-CimSession -ComputerName $computerName


Write-Output ========= SQL Server Ports ===================
Write-Output "Enabling SQLServer default instance port 1433"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 1433" -Direction inbound -LocalPort 1433 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 1433" -Direction outbound -LocalPort 1433 -Protocol TCP -Action Allow -cimsession $CIMSession

Write-Output "Enabling Dedicated Admin Connection port 1434"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 1434" -Direction inbound -LocalPort 1434 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 1434" -Direction outbound -LocalPort 1434 -Protocol TCP -Action Allow -cimsession $CIMSession

Write-Output "Enabling conventional SQL Server Service Broker port 4022"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 4022" -Direction inbound -LocalPort 4022 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 4022" -Direction outbound -LocalPort 4022 -Protocol TCP -Action Allow -cimsession $CIMSession
Write-Output "Enabling Transact-SQL Debugger/RPC port 135"

#netsh firewall set portopening TCP 135 "SQL Debugger/RPC"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 135" -Direction inbound -LocalPort 135 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 135" -Direction outbound -LocalPort 135 -Protocol TCP -Action Allow -cimsession $CIMSession

Write-Output ========= Analysis Services Ports ==============
Write-Output Enabling SSAS Default Instance port 2383
#netsh firewall set portopening TCP 2383 "Analysis Services"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 2383" -Direction inbound -LocalPort 2383 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 2383" -Direction outbound -LocalPort 2383 -Protocol TCP -Action Allow -cimsession $CIMSession
Write-Output "Enabling SQL Server Browser Service port 2382"

#netsh firewall set portopening TCP 2382 "SQL Browser"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 2382" -Direction inbound -LocalPort 2382 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 2382" -Direction outbound -LocalPort 2382 -Protocol TCP -Action Allow -cimsession $CIMSession
Write-Output ========= Misc Applications ==============
Write-Output "Enabling HTTP port 80"

#netsh firewall set portopening TCP 80 "HTTP"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 80" -Direction inbound -LocalPort 80 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 80" -Direction outbound -LocalPort 80 -Protocol TCP -Action Allow -cimsession $CIMSession
Write-Output "Enabling SSL port 443"

#netsh firewall set portopening TCP 443 "SSL"
$rule = New-NetFirewallRule -DisplayName "Allow inbound TCP Port 443" -Direction inbound -LocalPort 443 -Protocol TCP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TCP Port 443" -Direction outbound -LocalPort 443 -Protocol TCP -Action Allow -cimsession $CIMSession

Write-Output "Enabling port for SQL Server Browser Services Browse"
$rule = New-NetFirewallRule -DisplayName "Allow inbound UDP Port 1434" -Direction inbound -LocalPort 1434 -Protocol UDP -Action Allow -cimsession $CIMSession
$rule = New-NetFirewallRule -DisplayName "Allow outbound TDP Port 1434" -Direction outbound -LocalPort 1434 -Protocol UDP -Action Allow -cimsession $CIMSession

#
$date = Get-Date 
Write-Output "$date : Start sleep 180s after sql installation, until sql is started"
Start-Sleep 180 # wait for sql instance probably not needed
$date = Get-Date
Write-Output "$Date : Invoke postscripting..."

$ScriptPath = Split-Path $MyInvocation.InvocationName
& ("$ScriptPath\Install-NewSQLserver-postscript.ps1") -server $computername -LoginPSCredential $LoginPSCredential


