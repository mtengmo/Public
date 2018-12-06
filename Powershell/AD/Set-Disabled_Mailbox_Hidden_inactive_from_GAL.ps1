$mailboxes = get-user -resultsize unlimited | where {$_.UserAccountControl -like '*AccountDisabled*' -and $_.RecipientType -eq 'UserMailbox' -and $_.RecipientTypeDetails -eq 'UserMailbox'} | get-mailbox  | where {$_.HiddenFromAddressListsEnabled -eq $false}
$mailboxes | sort name | select name, alias



foreach ($mailbox in $mailboxes) { Set-Mailbox -HiddenFromAddressListsEnabled $true -Identity $mailbox }