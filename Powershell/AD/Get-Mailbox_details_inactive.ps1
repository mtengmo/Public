
$Allusers = (get-user -ResultSize unlimited |
        ForEach-Object {
        #$size = (Get-MailboxStatistics $_.UserPrincipalName).TotalItemSize.Value.ToMB()
        if ($_.RecipientType -eq "UserMailbox") {
            $HiddenFromAddressListsEnabled = (get-mailbox -identity $_.UserPrincipalName).HiddenFromAddressListsEnabled
            $IsInactiveMailbox = (get-mailbox -identity $_.UserPrincipalName).IsInactiveMailbox
            $JunkmailEnabled = (Get-MailboxJunkEmailConfiguration -Identity $_.UserPrincipalName).Enabled
            $JunkmailTrustedListsOnly = (Get-MailboxJunkEmailConfiguration -Identity $_.UserPrincipalName).TrustedListsOnly
            #$size = (Get-MailboxStatistics -Identity $_.UserPrincipalName).TotalItemSize.Value
            $LastLogonTime = (Get-MailboxStatistics -Identity $_.UserPrincipalName).LastLogonTime
        }
        New-Object -TypeName PSObject -Property @{
            #homeMDB        = $_.homeMDB
            #mailNickName   = $_.mailNickName
            #mail           = $_.mail
            #ProxyAddresses = $_.ProxyAddresses -join '; '
            #DisplayName    = $_.DisplayName
            UserPrincipalName             = $_.UserPrincipalName
            FirstName                     = $_.FirstName
            LastName                      = $_.LastName
            UserAccountControl            = $_.UserAccountControl
            RecipientType                 = $_.RecipientType
            RecipientTypeDetails          = $_.RecipientTypeDetails
            PreviousRecipientTypeDetails  = $_.PreviousRecipientTypeDetails
            IsDirSynced                   = $_.IsDirSynced
            AccountDisabled               = $_.AccountDisabled
            SKUAssigned                   = $_.SKUAssigned
            IsSecurityPrincipal           = $_.IsSecurityPrincipal
            HiddenFromAddressListsEnabled = $HiddenFromAddressListsEnabled
            IsInactiveMailbox             = $IsInactiveMailbox
            LastLogonTime                 = $LastLogonTime
            JunkmailEnabled               = $JunkmailEnabled
            JunkmailTrustedListsOnly      = $JunkmailTrustedListsOnly


        }
    }) | Sort-Object UserPrincipalName -Descending | Export-Csv "C:\temp\DisableduserMBX.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8
 
