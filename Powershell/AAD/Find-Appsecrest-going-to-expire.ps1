#
<# 
    .SYNOPSIS 
        This Azure Automation runbook  
 
    .DESCRIPTION 
       Mail owner of AzureAD Apps that have certs or secrets that will going to expire soon
       Create an Appregistration with mail.send permissions delegated. 
	   Help from: 
	   https://gist.githubusercontent.com/JanVidarElven/32b8f6bb8a422c9cce1816582eef24d8/raw/1148f1a96a351acf1a0fcf282e187ef1d2398fb1/AddManagedIdentityMSGraphAppRoles.md
	   https://gotoguy.blog/2022/03/15/add-graph-application-permissions-to-managed-identity-using-graph-explorer/
	   https://mikecrowley.us/2021/10/27/sending-email-with-send-mgusermail-microsoft-graph-powershell/
	   https://github.com/Mike-Crowley/Public-Scripts/blob/main/MgUserMail.ps1



    .PARAMETER 

    .EXAMPLE 
    Verison 1.0 - Production ready. 
    .Setup permissions
    # Add Microsoft Graph Applications Permissions (Roles Claim) to MSI

    The following commands must be run in Windows PowerShell and with the AzureAD Module. Remember to Connect-AzureAD with Global Administrator Privileges first.

    ## Part 1 - Get Managed Identity Service Principal

    ### Display Name of Managed Identity

    #powershell
    # Get SPN based on MSI Display Name
    $msiSpn = (Get-AzureADServicePrincipal -Filter "displayName eq '$msiDisplayName'")
    #

    ### Get Managed Identity Service Principal Name

    #powershell
    # If System Assigned MSI this is the name of the Function App, if User Assigned MSI use DisplayName
    $msiDisplayName=".."
    #

    ## Part 2 - Get Microsoft Graph API Service Principal

    ### Microsoft Graph App Well Known App Id

    #powershell
    # Set well known Graph Application Id
    $msGraphAppId = "00000003-0000-0000-c000-000000000000"
    #

    ### Get Microsoft Graph Service Principal

    #powershell
    # Get SPN for Microsoft Graph
    $msGraphSpn = Get-AzureADServicePrincipal -Filter "appId eq '$msGraphAppId'"
    #

    ## Part 3 - Get Application Role Permissions

    ### Microsoft Graph Permissions required

    #powershell
    # Type Graph App Permissions needed
    $msGraphPermission = "User.Read.All", "...", "..."
    $msGraphPermission = "Application.Read.All", "Directory.Read.All", "User.Read" ,"Mail.Send", "Mail.Send.Shared"

    #

    ### Get the Application Role or Roles for the Graph Permission

    #powershell
    # Now get all Application Roles matching above Graph Permissions
    $appRoles = $msGraphSpn.AppRoles | Where-Object {$_.Value -in $msGraphPermission -and $_.AllowedMemberTypes -contains "Application"}
    #

    ## Part 4 - Assign the Application Role to the Managed Identity

    #powershell
    # Add Application Roles to MSI SPN
    $appRoles | % { New-AzureAdServiceAppRoleAssignment -ObjectId $msiSpn.ObjectId -PrincipalId $msiSpn.ObjectId -ResourceId $msGraphSpn.ObjectId  -Id $_.Id }
    #

    .OUTPUTS 
#> 

 
param( 
    [parameter(Mandatory = $false)][int] $expiresWithinDays = "28"    
    , [parameter(Mandatory = $false)][String] $MsgFrom = "servicedesk@tobii.com"  
) 
$StartTime = $(get-date)

Function ConvertTo-IMicrosoftGraphRecipient {
    [cmdletbinding()]
    Param(
        [array]$SmtpAddresses        
    )
    foreach ($address in $SmtpAddresses) {
        @{
            emailAddress = @{address = $address }
        }    
    }    
}

Function ConvertTo-IMicrosoftGraphAttachment {
    [cmdletbinding()]
    Param(
        [string]$UploadDirectory        
    )
    $directoryContents = Get-ChildItem $UploadDirectory -Attributes !Directory -Recurse
    foreach ($file in $directoryContents) {
        $encodedAttachment = [convert]::ToBase64String((Get-Content $file.FullName -Encoding byte))
        @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            name          = ($File.FullName -split '\\')[-1]
            contentBytes  = $encodedAttachment
        }   
    }    
}
$timestamp = get-date
# Start
# use this line for system managed identity
Connect-AzAccount -Identity
# use this line for user managed identity, specify its AppID as AccountId
#Connect-AzAccount -Identity -AccountId <ClientID>

$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
    
Write-Output "$timestamp : Hi I'm $($context.Account.Id)"
    
# Connect to AAD to use Azure AD Graph
# Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id

# To use MS Graph use the below line
Connect-MgGraph -AccessToken $graphToken


# Get Apps
Select-MgProfile -Name "beta"
$apps = Get-MgApplication   -all
#Get-MgApplication -Filter "AppId eq 'b4dc559a-a865-4a50-ae78-cb24d8709423'" | select  -ExpandProperty PasswordCredentials

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

foreach ($app in $apps) {
    $timestamp = Get-date
    $appid = $app.id
    if ($app.PasswordCredentials.EndDateTime -lt (Get-Date).AddDays($expiresWithinDays) -and $app.PasswordCredentials.EndDateTime -gt (Get-date)) {
        Write-Output "$timestamp : Found app: $($app.displayname) $appid $($app.DisplayName) $($app.PasswordCredentials.EndDateTime)"
        $owners = Get-MgApplicationOwner -ApplicationId $appid
        # Loop out owners
        foreach ($owner in $owners) {

            $ReportLine = [PSCustomObject] @{
                Ownermail     = (get-mguser -userid $($owner.id)).Mail
                App           = $app.displayname
                ObjectID      = $app.ObjectId
                AppId         = $app.AppId
                Type          = $app.type
                KeyIdentifier = $id
                EndDate       = $app.PasswordCredentials.EndDateTime
                EndDateDesc   = $app.PasswordCredentials.EndDateTime -join "; "
            }
            $Report.Add($ReportLine)
            # Owners        = (Get-AzureADApplicationOwner -ObjectId $($app.ObjectId)).UserPrincipalName -join ";"
        }
     
    }
    
}

# Email owners 
foreach ($line in $report) {
    $emailRecipients = @(
        $($line.Ownermail)
    )
    $emailSender = $MsgFrom

    [array]$toRecipients = ConvertTo-IMicrosoftGraphRecipient -SmtpAddresses $emailRecipients 
    #    $attachments = ConvertTo-IMicrosoftGraphAttachment -UploadDirectory C:\tmp

    $MsgSubject = "Notifcation to $($line.Ownermail) - AzureAD apps will soon expire $($line.app) !"
    $htmlHeaderUser = "<h2>Notifcation to $($line.Ownermail) - AzureAD apps will soon expire $($line.app)</h2>"
    $htmlline2 = "IT have identfied apps that you are owner of that have secrets or certificates that will soon expire"
    $htmlline3 = "<p>The app with name: $($line.app), ObjectID $($line.Objectid) and AppId $($line.appid) have secrets or certificates that will expire: $($line.EnddateDesc)</p>"
    $htmlline4 = "A remender will come once per week until expired or renewed."
    $htmlline5 = "<p>If the app have both expired and active secrets, please remove the expired secrets.</p>"
    $htmlline6 = "<p>Regards, Helpdesk</p>"
    $htmlbody = $htmlheaderUser + $htmlline2 + $htmlline3 + $htmlline4 + $htmlline5 + $htmlline6 + "<p>"
    $HtmlMsg = "</body></html>" + $HtmlHead + $HtmlBody

    $emailSubject = $MsgSubject
    $emailBody = @{
        ContentType = 'html'
        Content     = $HtmlMsg   
    }

    $body += @{subject = $emailSubject }
    $body += @{toRecipients = $toRecipients }    
    #$body += @{attachments  = $attachments}
    $body += @{body = $emailBody }

    $bodyParameter += @{'message' = $body }
    $bodyParameter += @{'saveToSentItems' = $false }

    Send-MgUserMail -UserId $emailSender -BodyParameter $bodyParameter
    $timestamp = get-date
    Write-Output "$timestamp : Emailed $($line.Ownermail) with information that app $($line.app) will soon expire, $($line.EnddateDesc)"
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
write-output "$timestamp : Total Runtime: $totalTime"
