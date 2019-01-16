import-module MSOnline
#Let's get us an admin cred!
$userCredential = Get-Credential
#This connects to Azure Active Directory
Connect-MsolService -Credential $userCredential
$ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $userCredential -Authentication Basic -AllowRedirection 
Import-PSSession $ExoSession


$allUsers = @()

$AllUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | select ObjectID, UserPrincipalName, FirstName, LastName, StrongAuthenticationRequirements, StsRefreshTokensValidFrom, StrongPasswordRequired, LastPasswordChangeTimestamp | 
    Where-Object {($_.UserPrincipalName -notlike "*#EXT#*")}
$UserInboxRules = @()
$UserDelegates = @()

foreach ($User in $allUsers) {
    Write-Host "Checking inbox rules and delegates for user: "
    $User.UserPrincipalName;
    $UserInboxRules += Get-InboxRule -Mailbox $User.UserPrincipalname |
        Select @{name="UserPrincipalname"; Expression={$User.UserPrincipalname}} , Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | 
            Where-Object {($_.ForwardTo -ne $null) -or ($_.ForwardAsAttachmentTo -ne $null) -or ($_.RedirectsTo -ne $null)}  
        $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | 
            Where-Object {($_.IsInherited -ne "True") -and ($_.User -notlike "*SELF*")}
}
$SMTPForwarding = Get-Mailbox -ResultSize Unlimited | 
    select Alias, getDisplayName, ForwardingAddress, ForwardingSMTPAddress, DeliverToMailboxandForward | 
        where {$_.ForwardingSMTPAddress -ne $null}
# Export list of inboxRules, Delegates and SMTP Forwards
$UserInboxRules | Export-Csv MailForwardingRulesToExternalDomains.csv -delimiter ";" -encoding utf8 -NoTypeInformation
$UserDelegates | Export-Csv MailboxDelegatePermissions.csv -delimiter ";" -encoding utf8 -NoTypeInformation
$SMTPForwarding | Export-Csv Mailboxsmtpforwarding.csv -delimiter ";" -encoding utf8 -NoTypeInformation
