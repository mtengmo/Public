#https://www.linkedin.com/pulse/restrictuse-ms-graph-send-emails-managed-identity-paul-shortt/

#Step 1 - Give permissions to send mail


# Install and import the required PowerShell Modules
Install-Module -Name AzureAD
Import-Module -Name AzureAD

Connect-AzureAD

# Replace with your managed identity object ID
$miObjectID = "1982b556-e570-4b94-a380-70ccbe81cefd"

# The app IDs of the Microsoft APIs are the same in all tenants:
# Microsoft Graph: 00000003-0000-0000-c000-000000000000
# SharePoint Online: 00000003-0000-0ff1-ce00-000000000000

$graphID = "00000003-0000-0000-c000-000000000000"

$graph = Get-AzureADServicePrincipal -Filter "AppId eq '$graphID'"

$Permission = $graph.AppRoles `
    | where Value -Like "Mail.Send" `
    | Select-Object -First 1

$msi = Get-AzureADServicePrincipal -ObjectId $miObjectID

New-AzureADServiceAppRoleAssignment `
    -Id $Permission.Id `
    -ObjectId $msi.ObjectId `
    -PrincipalId $msi.ObjectId `
    -ResourceId $graph.ObjectId



# Step 2 - Test mail
function Send-GraphEmail {
    param(
        [string]$MsgFrom,
        [string]$EmailTo,
        [string]$MsgSubject,
        [string]$htmlMsg
    )
    
    # Create the email message body
    $messageBody = @{
        ContentType = "HTML"
        Content = $htmlMsg
    } 

    # Define the recipients
    $recipients = @(
        @{
            EmailAddress = @{
                Address = $EmailTo
            }
        }
    ) 

    # Create the common parameters
    $commonParams = @{
        SaveToSentItems = $true
    } 

    # Create the parameter sets
    $params = @{
        Message = @{
            Subject = $MsgSubject
            Body = $messageBody
            ToRecipients = $recipients
        }
        SaveToSentItems = $commonParams.SaveToSentItems
    } 

    # Connect to the Microsoft Graph API
    Connect-MgGraph -Identity 

    # Send the email
    Send-MgUserMail -UserId $MsgFrom -BodyParameter $params
}

# Define the relevant variables
$From = "firstname.lastname@contoso.com"
$To = "firstname.lastname@contoso.com"
$Subject = "Those meddling kids!"
$Msg = @'
   <!DOCTYPE html>
   <html>
   <body>
   <h1>Heading 1</h1>
   <p>My first paragraph.</p>
   </body>
   </html>
'@

# Send the email with the previously defined function
Send-GraphEmail -MsgFrom $From -EmailTo $To -MsgSubject $Subject -htmlMsg $Msg

# step 3 
# restrict so app can only send from specifix 
Connect-AzureAD

# Replace with your managed identity object ID
$miObjectID = "<ObjectID of Managed Identity>"

$ApplicationID = (Get-AzureADServicePrincipal -ObjectId $miObjectID).Appid

# Replace with your managed identity object ID
#$ApplicationID = "<ObjectID of Managed Identity>"
$PolicyScope = "helpdesk@contoso.com"
$Desc = "Restrict the access for the Azure Automation usea-tbdvox-adintegrations ExpireInactiveAdmins to the specified mailbox - helpdesk@contoso.com"

Connect-exchangeonline
New-Application -AccessRight RestrictAccess -AppId $ApplicationID -PolicyScopeGroupId $PolicyScope -Description $Desc

# wait a couple of hours until permissions is synced
