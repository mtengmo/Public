
#Add app in Azure with authentication (mobile and desktop apps, redirecturi https://localhost
#API permissions, Delegated, "sign in and read user profile", "send mail as user","send mail on behalf of others"
#install module MSAL.PS

$clientID = "7xxxx"
$tenantID = "xxxxxxa"
$redirectUri = "https://localhost"
$msgFrom = "from@domain.com"
$EmailRecipient = "to@domain.com"
          
$MsgSubject = "Subject"
$htmlHeaderUser = "<h2>Heading!</h2>"
$htmlline2 = "<p>Bla bla bla</p>"
$htmlline3 = ""
$htmlline4 = ""
$htmlline5 = "<p></p>"
$htmlline6 = "<p>Regards, Helpdesk</p>"
    
$htmlbody = $htmlheaderUser + $htmlline2 + $htmlline3 + $htmlline4 + $htmlline5 + $htmlline6 + "<p>"
$HtmlMsg = "</body></html>" + $HtmlHead + $HtmlBody
    
#$AttachmentFile = "C:\temp\WelcomeToOffice365ITPros.docx"
#$ContentBase64 = [convert]::ToBase64String( [system.io.file]::readallbytes($AttachmentFile))
    
$myAccessToken = Get-MsalToken -ClientId $clientID -TenantId $tenantID -RedirectUri $redirectUri -ForceRefresh
$token = $myAccessToken.AccessToken
$Headers = @{
    'Authorization' = "Bearer $Token" 
}
    
$MessageParams = @{
    "URI"         = "https://graph.microsoft.com/v1.0/users/$MsgFrom/sendMail"
    "Headers"     = $Headers
    "Method"      = "POST"
    "ContentType" = 'application/json; charset=utf-8'
    "Body"        = (@{
            "message" = @{
                "subject"      = $MsgSubject
                "body"         = @{
                    "contentType" = 'HTML' 
                    "content"     = $htmlMsg 
                }
                "toRecipients" = @(
                    @{
                        "emailAddress" = @{"address" = $EmailRecipient }
                    } ) 
            }
        }) | ConvertTo-JSON -Depth 6
}
 
Invoke-RestMethod @Messageparams 
 
 
            