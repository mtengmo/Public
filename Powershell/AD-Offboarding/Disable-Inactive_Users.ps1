<# 
    .SYNOPSIS 
        This Azure Automation runbook disables expired accounts in Active Directory.  
 
    .DESCRIPTION 
        The runbook implements a simple solution for disabling accounts which are expired in the Active Directory.
        This script was developed to block sign in for accounts synchonized to Azure Active Directory (Microsoft Office 365)
        that use Password Hash Synchronization. Microsoft currently allows expired accounts to sign into Microsoft Online Services
        even though the account has expired.
        
        Script Version: 1.0
        Author: Peter Selch Dahl
        WWW: blog.peterdahl.net
        Last Updated: 9/18/2017
        The script is provided �AS IS� with no warranties or guarantees.
	Modified to Company X / Magnus

        Azure Feeback: Sync "Account Expired" UserAccountControl to Azure AD (AccountEnabled)
        https://feedback.azure.com/forums/169401-azure-active-directory/suggestions/31459621-sync-account-expired-useraccountcontrol-to-azure

        Use AAD Connect to disable accounts with expired on-premises passwords:
        https://blogs.technet.microsoft.com/undocumentedfeatures/2017/09/15/use-aad-connect-to-disable-accounts-with-expired-on-premises-passwords

        Supported scenario from Microsoft:
        "Account expiration
        If your organization uses the accountExpires attribute as part of user account management, 
        be aware that this attribute is not synchronized to Azure AD. As a result, an expired Active Directory 
        account in an environment configured for password synchronization will still be active in Azure AD. 
        We recommend that if the account is expired, a workflow action should trigger a PowerShell script that
        disables the user's Azure AD account. Conversely, when the account is turned on, the Azure AD instance 
        should be turned on."
        Source: https://docs.microsoft.com/en-us/azure/active-directory/connect/active-directory-aadconnectsync-implement-password-synchronization

    .PARAMETER ADSearchBase 
        Provide the Active Directory LDAP search base for finding the user objects. 

        Example 1: "CN=Users,DC=example,DC=com"
        Example 3: "DC=example,DC=com"
  
        For for details on LDAP Search:
        https://technet.microsoft.com/en-us/library/cc978021.aspx

    .EXAMPLE 
       See the documentation at: 
       
       http://blog.peterdahl.net/?p=60700&preview=true

    .OUTPUTS 
       Active Directory accounts that was disabled by the script.
#> 
 
param( 
    [parameter(Mandatory = $false)][String] $ADSearchBase = "OU=companyTechnology,DC=company,DC=intra",
    [parameter(Mandatory = $false)][int]$softoffboarding_delay_days = "-1",
    [parameter(Mandatory = $false)][int]$hardoffboarding_delay_days = "-35",
    [parameter(Mandatory = $false)][String] $tenantid = "xxxxx", #azuretenantid
    [parameter(Mandatory = $false)][String] $Applicationid = "xxxxxx", # $applicationid = (Get-AzureADApplication -Filter "DisplayName eq 'companyTown-Onboarding-script'").Appid
    [parameter(Mandatory = $false)][String] $thumb = "xxxxxx", # thumbprint for selfsigned certificate on sedirsync01 used for authenticate
    [parameter(Mandatory = $false)][String] $hybridworker = "GlobalIT",
    [parameter(Mandatory = $false)][String] $webhookuri = "https://outlook.office.com/webhook/teams....."
) 
 

Import-Module ActiveDirectory

#$param = @{
#    UsersOnly      = $True
#    AccountExpired = $false
#    SearchBase     = $ADSearchBase 
#}

$timestamp = Get-Date
Write-Output "$timestamp : Start searching for AD users to disable"
#$users = Search-ADAccount @param |
#Get-ADuser -Properties Department, Title, AccountExpirationDate, SAMAccountName, UserPrincipalName, Title, ExtensionAttribute5 #| where { $_.enabled -eq $true }

$users = Get-ADuser -SearchBase $ADSearchBase  -Properties Department, Title, AccountExpirationDate, SAMAccountName, UserPrincipalName, Title, ExtensionAttribute5, ExtensionAttribute9, ExtensionAttribute14, ExtensionAttribute15 -Filter *




#connect to az
#Connect to Azure Runbook
# Ensures you do not inherit an AzureRMContext in your runbook
Disable-AzureRmContextAutosave –Scope Process
# Connect to Azure with RunAs account
$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Write-Output "$timestamp : ServicePrincipalConnection: $ServicePrincipalConnection"
$tenantid = $ServicePrincipalConnection.TenantId
Write-Output "$timestamp : tenantid: $tenantid"
$ApplicationId = $ServicePrincipalConnection.ApplicationId
Write-Output "$timestamp : ApplicationId: $ApplicationId"
$CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
Write-Output "CertificateThumbprint: $CertificateThumbprint"
Add-AzureRmAccount -ServicePrincipal -tenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
$timestamp = Get-Date
$SubscriptionID = $ServicePrincipalConnection.SubscriptionID
Write-Output "$timestamp : AzureRmSubscription $SubscriptionID"
$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID

if ($AzureContext -eq $null) { Write-Output "$timestamp : Throw"; Throw }

$i = 0
$j = 0
$k = 0
$disabledusers = @()
$softoffboarded = @()
$hardoffboarded = @()
$StartTime = $(get-date)


#start looping users
$timestamp = Get-Date

Write-Output "$timestamp : Starting search for accounts that should be disabled and revoke access tokens"
ForEach ($user in $users) {
    $date = Get-Date
    if (($user.enabled -eq $true `
                -and $user.AccountExpirationDate -lt $date `
                -and $user.AccountExpirationDate -ne $null) `
            -or ( $user.enabled -eq $true `
                -and $user.ExtensionAttribute5 -eq 'Terminated'  )
    ) {
        $timestamp = Get-Date
        Write-Output "$timestamp : Disabling user: $($user.SAMAccountName)"
        #Disable AD account
        Try {
            Disable-ADAccount -Identity $user.SAMAccountName -Verbose
            Set-ADUser -Identity $($user.SAMAccountName) -replace @{ExtensionAttribute15 = "disabled" }
            $timestamp = (get-date -Format yyyy-MM-dd)
            Set-ADUser -Identity $($user.SAMAccountName) -replace @{ExtensionAttribute14 = $timestamp }
        }
        Catch {
            $timestamp = Get-Date
            $body = ConvertTo-JSON -Depth 2 @{
                title = "Error Disabling user $($user.SAMAccountName)"
                text  = "$timestamp : $_.Exception.Message"
            }
             
            Invoke-RestMethod -uri $webhookuri -Method Post -body $body -ContentType 'application/json'
            
            Write-Error -Message $_.Exception.Message -ErrorAction Stop
            return

        }
        $body = ConvertTo-JSON -Depth 2 @{
            title = 'Disable user'
            text  = "$timestamp : Disabling user: $($user.SAMAccountName), $($user.Name) "
        }
         
        Invoke-RestMethod -uri $webhookuri -Method Post -body $body -ContentType 'application/json'
        

        $disabledusers += $($user.UserPrincipalName)
        
        $i++   
    }  
}  

sleep 30
$users = Get-ADuser -SearchBase $ADSearchBase  -Properties Department, Title, AccountExpirationDate, SAMAccountName, UserPrincipalName, Title, ExtensionAttribute5, ExtensionAttribute9, ExtensionAttribute14, ExtensionAttribute15 -Filter *

$users = $users | where { $_.ExtensionAttribute9 -ne $null }
$timestamp = Get-Date
Write-Output "$timestamp : Starting soft offboarding"
ForEach ($user in $users) {
    $date = Get-Date
    [datetime]$last_working_date = $user.ExtensionAttribute9
   
    if ($user.enabled -eq $false `
            -and $last_working_date -lt $date.AddDays($softoffboarding_delay_days) `
            -and $user.title -ne "resource" `
            -and $user.ExtensionAttribute15 -ne 'softoffboarded' `
            -and $user.ExtensionAttribute15 -ne 'hardoffboarded' `
    ) {  
    
    
        #$date = Get-Date
        #$date = $date.AddDays($softoffboarding_delay_days) 
        #$date = $date.ToShortDateString()
        #$last_working_date = $user.ExtensionAttribute9
        #$AccountExpirationDate = $($user.AccountExpirationDate)
        #$AccountExpirationDate = $AccountExpirationDate.AddDays(-1) # removeing one day because of AD adds one day in attribute by default
        #$AccountExpirationDate = $AccountExpirationDate.ToShortDateString()
        #Write-Output "$($user.UserPrincipalName) $last_working_date"
        # if ($user.title -ne "resource" `
        #         -and $last_working_date -eq $date  
        # ) {
        $timestamp = Get-Date
        Write-Output "$timestamp : Match, start soft offboarding of $($user.UserPrincipalName) with last working date: $last_working_date"
        #start runbook offboarding office365
        $params = @{ }
        $params = @{"userPrincipalName" = $($user.UserPrincipalName) }
        #$timestamp = Get-Date
        Write-Output "$timestamp : Start runbook Offboarding-Office365-user params: $($user.UserPrincipalName)"
        Start-AzureRmAutomationRunbook -AutomationAccountName 'seadsynccompanytown' -Name 'Offboarding-Office365-user' -ResourceGroupName 'resourcegroupname' -AzureRMContext $AzureContext -Parameters $params -wait -RunOn $hybridworker
        
        #start runbook slack
        $params = @{ }
        $params = @{"upn" = $($user.UserPrincipalName) }
        $timestamp = Get-Date
        Write-Output "$timestamp : Start runbook Disable-slack_users params: $($user.UserPrincipalName)"
        Start-AzureRmAutomationRunbook -AutomationAccountName 'seadsynccompanytown' -Name 'Disable-slack_users' -ResourceGroupName 'resourcegroupname' -AzureRMContext $AzureContext -Parameters $params -wait
        #Start-Sleep 180
        
        # softoffboard AD
        $params = @{ }
        $params = @{"SAMAccountName" = $($user.SAMAccountName) }
        Write-Output "$timestamp : Start runbook Soft-AD-offboarding for: $($user.SAMAccountName) Name: $($user.Name) last_working_date: $last_working_date"
        Start-AzureRmAutomationRunbook -AutomationAccountName 'seadsynccompanytown' -Name 'Offboarding-AD-onprem-softoffboarding' -ResourceGroupName '' -AzureRMContext $AzureContext -Parameters $params -RunOn $hybridworker -wait
        Set-ADUser -Identity $($user.SAMAccountName) -manager $null -verbose 
        Set-ADUser -Identity $($user.SAMAccountName) -replace @{msExchHideFromAddressLists = $true }
        Set-ADUser -Identity $($user.SAMAccountName) -replace @{ExtensionAttribute15 = "softoffboarded" }
        $timestamp = (get-date -Format yyyy-MM-dd)
        Set-ADUser -Identity $($user.SAMAccountName) -replace @{ExtensionAttribute14 = $timestamp }



        $timestamp = Get-Date
        $body = ConvertTo-JSON -Depth 2 @{
            title = 'Soft offboarded user'
            text  = "$timestamp : $timestamp : Soft offboarded $($user.UserPrincipalName), $($user.Name) with last working date: $last_working_date"
        }
         
        Invoke-RestMethod -uri $webhookuri -Method Post -body $body -ContentType 'application/json'
        
        $softoffboarded += $($user.UserPrincipalName)
        $j++   
    }  
}  




$timestamp = Get-Date
Write-Output "$timestamp : Starting hard offboarding"

#start looping users
ForEach ($user in $users) {
    $date = Get-Date
    [datetime]$last_working_date = $user.ExtensionAttribute9

    if ($user.enabled -eq $false `
            -and $last_working_date -lt $date.AddDays($hardoffboarding_delay_days) `
            -and $user.title -ne "resource" `
            -and $user.ExtensionAttribute5 -eq 'Terminated' `
            -and $user.ExtensionAttribute15 -eq 'softoffboarded'  
    ) {  


        #salesforce
        $params = @{ }
        $params = @{"upn" = $($user.UserPrincipalName) }
        
        $timestamp = Get-Date
        #remove ad groups
        $params = @{ }
        $params = @{"SAMAccountName" = $($user.SAMAccountName) }
        Write-Output "$timestamp : Start runbook AD-offboarding for: $($user.SAMAccountName) Name: $($user.Name) last_working_date: $last_working_date"
        Start-AzureRmAutomationRunbook -AutomationAccountName 'seadsynccompanytown' -Name 'Offboarding-AD-onprem' -ResourceGroupName 'resourcegroupname' -AzureRMContext $AzureContext -Parameters $params -RunOn $hybridworker -wait
        
        $timestamp = Get-Date
        $body = ConvertTo-JSON -Depth 2 @{
            title = 'Hard offboarded user'
            text  = "$timestamp : $timestamp : Hard offboarded $($user.UserPrincipalName), $($user.Name) with last_working_date: $last_working_date"
        }
         
        Invoke-RestMethod -uri $webhookuri -Method Post -body $body -ContentType 'application/json'
        
        $hardoffboarded += $($user.UserPrincipalName)
        $k++  
    
    }  
}  


#Logging
$timestamp = Get-Date
if ($i -gt 0) {
    Write-Output "$timestamp : Disabled $i users"
    $disabledusers = ($disabledusers -join " ")
    Write-Output "$timestamp : Users disabled: $disabledusers"
}
else {
    Write-Output "$timestamp : No users to disable"
}

if ($j -gt 0) {
    Write-Output "$timestamp : Soft offboarded $j users"
    $softoffboarded = ($softoffboarded -join " ")
    Write-Output "$timestamp : Users soft offboarded: $softoffboarded"
}
else {
    Write-Output "$timestamp : No users to soft offboard"
}

$timestamp = Get-Date
if ($k -gt 0) {
    Write-Output "$timestamp : Hard offboarded $k users"
    $hardoffboarded = ($hardoffboarded -join " ")
    Write-Output "$timestamp : Users hard offboarded: $hardoffboarded"
}
else {
    Write-Output "$timestamp : No users to hard offboard"
}


$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
write-output "$timestamp : Total Runtime: $totalTime"

