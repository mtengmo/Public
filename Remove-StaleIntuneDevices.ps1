<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

function Read-HostYesNo ([string]$Title, [string]$Prompt, [boolean]$Default)
{
    # Set up native PowerShell choice prompt with Yes and No
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    
    # Set default option
    $defaultChoice = 0 # first choice = Yes
    if ($Default -eq $false) { # only if it was given and is false
        $defaultChoice = 1 # second choice = No
    }

    $result = $Host.UI.PromptForChoice($Title, $Prompt, $options, $defaultChoice)
    
    if ($result -eq 0) { # 0 is yes
        return $true
    } else {
        return $false
    }
}

function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User,
    $Password
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }

# Getting path to ActiveDirectory Assemblies
# If the module count is greater than 1 find the latest version

    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

$resourceAppIdURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$Tenant"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

        if($Password -eq $null){

            $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        }

        else {

            if(test-path "$Password"){

            $UserPassword = get-Content "$Password" | ConvertTo-SecureString

            $userCredentials = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $userUPN,$UserPassword

            $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $clientid, $userCredentials).Result;

            }

            else {

            Write-Host "Path to Password file" $Password "doesn't exist, please specify a valid path..." -ForegroundColor Red
            Write-Host "Script can't continue..." -ForegroundColor Red
            Write-Host
            break

            }

        }

        if($authResult.AccessToken){

        # Creating header for Authorization token

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}

Function Get-StaleManagedDevices(){

    <#
    .SYNOPSIS
    This function is used to get Intune Managed Devices from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Intune Managed Device that has not synced with the service in the past 90 days
    .EXAMPLE
    Get-StaleManagedDevices
    Returns all managed devices but excludes EAS devices registered within the Intune Service that have not checked in for 90+ days
    .NOTES
    NAME: Get-StaleManagedDevices
    #>
    
    [cmdletbinding()]
    
    param
    (
    )
    
    # Defining Variables
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices"
    # this will get the date/time at the time this is run, so if it is 3pm on 2/27, the 90 day back mark would be 11/29 at 3pm, meaning if a device checked in on 11/29 at 3:01pm it would not meet the check
    $cutoffDate = (Get-Date).AddDays(-720).ToString("yyyy-MM-dd")
    
    $uri = ("https://graph.microsoft.com/{0}/{1}?filter=managementAgent eq 'mdm' or managementAgent eq 'easMDM' and lastSyncDateTime le {2}" -f $graphApiVersion, $Resource, $cutoffDate)
        
    try { 
               
        $devices = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        return $devices
    }
    
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    } 

function Export-DeviceList(){

    <#
    .SYNOPSIS
    This function is used to build a list of PowerShell objects to easily display to the end user in a table or export to CSV
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Intune Managed Device that has not synced with the service in the past 90 days and displays them to the admin running the script
    .EXAMPLE
    Export-DeviceList
    Returns all stale devices in a custom PowerShell object or exports the objects to a CSV for review by the person executing the script
    .NOTES
    NAME: Export-DeviceList
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]$Devices
    )

    $deviceInfo = @()

    foreach($device in $Devices) {
        $info = New-Object -TypeName psobject
        $info | Add-Member -MemberType NoteProperty -Name ID -Value $device.ID 
        $info | Add-Member -MemberType NoteProperty -Name DeviceName -Value $device.deviceName 
        $info | Add-Member -MemberType NoteProperty -Name UserID -Value $device.userPrincipalName
        $info | Add-Member -MemberType NoteProperty -Name ManagementAgent -Value $device.managementAgent
        $info | Add-Member -MemberType NoteProperty -Name LastSyncTime -Value $device.lastSyncDateTime
        $info | Add-Member -MemberType NoteProperty -Name EnrolledDate -Value $device.enrolledDateTime

        $deviceInfo += $info
    }

    return $deviceInfo
}

function Remove-StaleDevices(){

<#
    .SYNOPSIS
    This function retires all stale devices in Intune that have not checked in within 90 days
    .DESCRIPTION
    The function connects to the Graph API Interface and retires any Intune Managed Device that has not synced with the service in the past 90 days
    .EXAMPLE
    Remove-StaleDevices -Devices $deviceList
    Executes a retire command against all devices in the list provided and then deletes the record from the console
    .NOTES
    NAME: Remove-StaleDevices
    #>
        
    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory=$true)]$DeviceID
    )

    $graphApiVersion = "Beta"

    try {

        $Resource = "deviceManagement/managedDevices/$DeviceID/retire"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Write-Host $uri
        Write-Verbose "Sending retire command to $DeviceID"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

	Start-Sleep -s 1

        $Resource = "deviceManagement/managedDevices('$DeviceID')"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Write-Host $uri
        Write-Verbose "Sending delete command to $DeviceID"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete

        }

    catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break

        }
}

####################################################

#region Authentication

#update info with service account and credential.txt file location
$User = "serviceaccount@contoso.onmicrosoft.com"
$Password = "c:\temp\credentials.txt" #example - can be stored anywhere on the PC

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User -Password "$Password"

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User -Password "$Password"

}

#endregion

####################################################

#region Retrieve Stale Devices
$staleDevices = Get-StaleManagedDevices

if($staleDevices -eq $null){
    Write-Host "There are no devices that are out of date; ending script..."
    return
}

$deviceInfo = @()
$deviceInfo += Export-DeviceList -Devices $staleDevices

if($deviceInfo.Count -gt 1){
    Write-Host "Retrieved "$deviceInfo.count " number of devices..."
}

else{
    Write-Host "Retrieved "$deviceInfo.count " device..."
}

$displayTable = Read-HostYesNo -Prompt "Do you want to examine the devices returned?" -Default $true

if($displayTable){
    $deviceInfo | Format-Table
    Write-Host
}

$exportCSV = Read-HostYesNo -Prompt "Do you want to export all returned devices to a CSV?" -Default $true

if($exportCSV){
    $path = "c:\temp"
    $append = "_$(Get-Date -f m)"
    if(! (Test-Path -Path $path -PathType Container)){
        New-Item -Path $path -ItemType Directory
    }
    $deviceInfo | Export-Csv -Path ("{0}\devices{1}.csv" -f $path, $append)
    Write-Host ("CSV created at {0}\devices{1}.csv containing device info..." -f $path, $append)
    Write-Host
}

$continue = Read-HostYesNo -Prompt "Are you ready to issue the Retire/Delete command to the devices returned?" -Default $false

if($continue){
    foreach($device in $deviceInfo){
        #Remove-StaleDevices -DeviceID $device.ID #-Verbose
    }
}

####################################################
Write-Host