h#requires -modules AzureAD
<# 
    .SYNOPSIS 
        This Azure Automation runbook create new users from Sage
 
    .DESCRIPTION 

    
    .EXAMPLE 

    .OUTPUTS 
#> 

 
param( 
    [parameter(Mandatory = $false)][String] $credentialname = "svc-acct@company.com",
    #    [parameter(Mandatory = $false)][String] $OutOfOfficeBody = "I have left the company please contact my manager: $manager_name $manager_mail ",
    [parameter(Mandatory = $false)][String]  $userPrincipalName = "",
    [parameter(Mandatory = $false)][String] $mailserver = "mailrelay.company.local",
    [parameter(Mandatory = $false)][String] $mailfrom = "helpdesk@company.com",
    #[parameter(Mandatory = $false)][String] $mailsubject = "Your user are offboarded!",
    [parameter(Mandatory = $false)][String] $tenantid = "xxxxx", #azuretenantid
    [parameter(Mandatory = $false)][String] $Applicationid = "xxxxx", # $applicationid = (Get-AzureADApplication -Filter "DisplayName eq 'companyTown-Onboarding-script'").Appid
    [parameter(Mandatory = $false)][String] $thumb = "xxxx # thumbprint for selfsigned certificate on sedirsync01 used for authenticate
) 

function Remove-UserFromAzureADGroups {
    <# 
    .SYNOPSIS 
        This remove users from all AzureAD groups with direct membership
    .DESCRIPTION 
    .EXAMPLE 
    .OUTPUTS 
#> 
    param( 
        [parameter(Mandatory = $false)][String]  $userPrincipalName = ""
    ) 

    $timestamp = Get-Date
    Write-Output "$timestamp : Checking connectivity to Azure AD..."
    if (!(Get-Module AzureAD -ListAvailable -Verbose:$false | ? { ($_.Version.Major -eq 2 -and $_.Version.Build -eq 0 -and $_.Version.Revision -gt 55) -or ($_.Version.Major -eq 2 -and $_.Version.Build -eq 1) })) { Write-Host -BackgroundColor Red "This script requires a recent version of the AzureAD PowerShell module. Download it here: https://www.powershellgallery.com/packages/AzureAD/"; return }
    try { Get-AzureADCurrentSessionInfo -ErrorAction Stop -WhatIf:$false -Verbose:$false | Out-Null }
    catch { try { Connect-AzureAD -WhatIf:$false -Verbose:$false -ErrorAction Stop | Out-Null } catch { return $false } }

    $IncludeAADSecurityGroups = "$true"

    if ($userprincipalname) {
        Try { $ExternalDirectoryObjectId = Get-AzureADUser -ObjectId $userprincipalname -erroraction stop }
        catch [Microsoft.Open.AzureAD16.Client.ApiException] {
            Write-Error "$timestamp : $_.Exception.Message"
        }
    }
    $timestamp = Get-Date
    if ($IncludeAADSecurityGroups) {
        #Write-Verbose "$timestamp : Obtaining security group list for user $userprincipalname..."
        $GroupsAD = Get-AzureADUserMembership -ObjectId $userprincipalname -All $true | ? { $_.ObjectType -eq "Group" -and $_.SecurityEnabled -eq $true -and $_.MailEnabled -eq $false }
        $timestamp = Get-Date           
        if (!$GroupsAD) { Write-Output "$timestamp : No matching security groups found for $userprincipalname, skipping..." }
        else { Write-Verbose "$timestamp : User $userprincipalname is a member of $(($GroupsAD | measure).count) security group(s)." }
    
        #cycle over each Group
        foreach ($groupAD in $GroupsAD) {
            Write-Output "$timestamp : Removing user $userprincipalname from group ""$($GroupAD.DisplayName)"""
            if (!$WhatIfPreference) {
                try { Remove-AzureADGroupMember -ObjectId $GroupAD.ObjectId -MemberId $ExternalDirectoryObjectId.objectid  -ErrorAction Stop }
                catch [Microsoft.Open.AzureAD16.Client.ApiException] {
                    if ($_.Exception.Message -match ".*Insufficient privileges to complete the operation") { Write-Output "$timestamp : Warning: You cannot remove members of the ""$($groupAD.DisplayName)"" Dynamic group, adjust the membership filter instead..." }
                    elseif ($_.Exception.Message -match ".*Invalid object identifier") { Write-Error "$timestamp : ERROR: Group ""$($groupAD.DisplayName)"" not found, this should not happen..." }
                    elseif ($_.Exception.Message -match ".*Unsupported referenced-object resource identifier") { Write-Error "$timestamp : ERROR: User $userprincipalname not found, this should not happen..." }
                    elseif ($_.Exception.Message -match ".*does not exist or one of its queried reference-property") { Write-Error "$timestamp : ERROR: User $userprincipalnameis not a member of the ""$($groupAD.DisplayName)"" group..." }
                    else { $_ | fl * -Force; continue } #catch-all for any unhandled errors
                }
                catch { $_ | fl * -Force; continue } #catch-all for any unhandled errors
            }
            else { Write-Output "$timestamp : WARNING: The Azure AD module cmdlets do not support the use of -WhatIf parameter, action was skipped..." }
        }
    }
    if ($ExternalDirectoryObjectId) { try { Remove-Variable -Name ExternalDirectoryObjectId -Scope Global -Force -erroraction SilentlyContinue} catch { } }
    if ($userprincipalname) { try { Remove-Variable -Name userprincipalname -Scope Global -Force -erroraction SilentlyContinue} catch { } }
}


$connectionName = "svc-companytown-adsync@company.com"

$timestamp = Get-Date
Write-Output "$timestamp : Connecting AzureAD"
Connect-AzureAD -TenantId $tenantid  -ApplicationId  $Applicationid -CertificateThumbprint $thumb -ErrorAction Stop

$credentialname = "svc-companytown-adsync@company.com"
$Credential = Get-AutomationPSCredential -Name $credentialname
    
$so = New-PSSessionOption -OperationTimeout 40000 -OpenTimeout 40000
#connect exchange online
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection -SessionOption $so 
#IMPORT SESSION COMMANDS
#Import-PsSession $Session  -AllowClobber -Verbose
Import-Module (Import-PSSession -Session $Session -AllowClobber -DisableNameChecking) -Verbose:$false 

#bug get mailbox: https://support.microsoft.com/en-us/help/4493553/could-not-find-database-error-for-multi-region-cmdlets

#manager details
$manager_mail = (Get-AzureADUserManager -ObjectId $userPrincipalName).mail
$manager_upn = (Get-AzureADUserManager -ObjectId $userPrincipalName).UserPrincipalName
$manager_name = (Get-AzureADUserManager -ObjectId $userPrincipalName).DisplayName
$displayname = (get-azureaduser -objectid $userPrincipalName).DisplayName

if (!$manager_mail) {
    Write-Warning "$timestamp : No manager found for $userPrincipalName"
}

#Revoke all sessions
$timestamp = Get-Date
Write-Output "$timestamp : Revoke AzureAD refresh tokens for $userPrincipalName"
Get-AzureADUser -ObjectId $userPrincipalName | Revoke-AzureADUserAllRefreshToken

# if mailbox 
$timestamp = Get-Date
Write-Output "$timestamp : Check if mailbox exists: $userPrincipalName"
$exist = [bool](Get-mailbox -identity $userPrincipalName -erroraction SilentlyContinue)

try {
    $verify = Get-mailbox -identity $userPrincipalName
}
catch {
    Write-Output "Can´t find mailbox for $userPrincipalName"
}


Write-Output "$timestamp : Exist mailbox: $exist"

if ($exist -eq $true) {

    $timestamp = Get-Date
    Write-Output "$timestamp : Find manager $manager_name for $displayname"
    #delegate permissions
    Add-MailboxPermission -Identity $userPrincipalName -User $manager_upn -AccessRights FullAccess -InheritanceType All

    #Cancel meetings organized by this user
    $timestamp = Get-Date
    Write-Output "$timestamp : Removing calender invites for $userPrincipalName"
    Remove-CalendarEvents -Identity $userPrincipalName -CancelOrganizedMeetings -confirm:$False  -QueryStartDate $timestamp -QueryWindowInDays 1800

    #Set Out Of Office
    $timestamp = Get-Date
    Write-Output "$timestamp : Set OOF email with info to $manager_name"
    Set-MailboxAutoReplyConfiguration -Identity $userPrincipalName -ExternalMessage "Thank you for contacting us, $displayname is no longer working for company. Please resend your email to $manager_mail."  -InternalMessage "Thank you for contacting us, $displayname is no longer working for company. Please resend your email to $manager_mail." -AutoReplyState Enabled

    #disable forwarders
    $timestamp = Get-Date
    Write-Output "$timestamp : Remove forward on mailbox $userPrincipalName"
    Get-Mailbox -Identity $userPrincipalName | Set-Mailbox -ForwardingSmtpAddress $null

    #disable inbox rules
    $timestamp = Get-Date
    Write-Output "$timestamp : Disable inbox rules on mailbox $userPrincipalName"
    Get-InboxRule -Mailbox $userPrincipalName | Disable-InboxRule -Confirm:$false -Force -AlwaysDeleteOutlookRulesBlob #Remove-InboxRule -Force -Confirm:$false -AlwaysDeleteOutlookRulesBlob


    $timestamp = Get-Date
    Write-Output "$timestamp : Offboarded $userPrincipalName in AzureAD/Office365"

    $mailbody = "Offboarding has started for $displayname $userPrincipalName and you have been given access to the users mailbox for 30 days. It will show up in Outlook on the left-hand side shortly (a restart may be required). Please move any email you need to keep for business purposes within 30 days.

The mailbox will be removed after 30 days and the offboarding will be completed.


Regards, 
Helpdesk 
"
    $mailsubject = "Offboarding has started for $displayname!"

    $timestamp = Get-Date
    Write-Output "$timestamp : Emailing manager: $manager_mail for $userPrincipalName"
    Message `
        -To $manager_mail `
        -Subject $mailsubject `
        -Body $mailbody `
        -Port 25 `
        -SmtpServer $mailserver `
        -From $mailfrom `
        -Encoding 'utf8'
    
}


# remove all groups
Remove-UserFromAzureADGroups -userPrincipalName $userPrincipalName

if ($exist) { try { Remove-Variable -Name exist -Scope Global -Force } catch { } }
if ($userPrincipalName) { try { Remove-Variable -Name userPrincipalName -Scope Global -Force } catch { } }
if ($manager_mail) { try { Remove-Variable -Name manager_mail -Scope Global -Force } catch { } }
if ($manager_upn) { try { Remove-Variable -Name manager_upn -Scope Global -Force } catch { } }
if ($manager_name) { try { Remove-Variable -Name manager_name -Scope Global -Force } catch { } }
if ($mailbody) { try { Remove-Variable -Name mailbody -Scope Global -Force } catch { } }
if ($displayname) { try { Remove-Variable -Name displayname -Scope Global -Force } catch { } }
