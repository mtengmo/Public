$File = "c:\script\Disabled_User_Mailboxes.csv"
$LogFile = "c:\script\Disabled_User_Mailboxes.log"
$Mailboxes = Get-Mailbox -ResultSize unlimited | where { $_.RecipientTypeDetails -eq "UserMailbox" }
$Disabled = @()
Remove-Item $logfile -ErrorAction SilentlyContinue
Remove-Item $file -ErrorAction SilentlyContinue

$results = Foreach ($Mailbox in $Mailboxes) {
    Try {
        if (
            (Get-ADUser $Mailbox.Alias).Enabled -eq $false) {
            $size = (Get-MailboxStatistics -identity $Mailbox.SamAccountName).TotalItemSize.Value
            $permissions = @()
            $permissions = (Get-MailboxPermission -identity $Mailbox.SamAccountName | where { ($_.IsInherited -eq $false) -and ($_.User -notlike "NT AUTHORITY\SELF") }).User
            New-Object -TypeName PSObject -Property @{
                # homeMDB        = $Mailbox.homeMDB
                mailNickName                  = $Mailbox.mailNickName
                mail                          = $Mailbox.PrimarySmtpAddress
                ProxyAddresses                = $Mailbox.ProxyAddresses -join '; '
                DisplayName                   = $Mailbox.DisplayName
                SamAccountName                = $Mailbox.SamAccountName
                UserPrincipalName             = $Mailbox.UserPrincipalName
                Givenname                     = $Mailbox.Givenname
                SurName                       = $Mailbox.SurName
                Size                          = $size
                HiddenFromAddressListsEnabled = $Mailbox.HiddenFromAddressListsEnabled
                RecipientType                 = $Mailbox.RecipientType
                RecipientTypeDetails          = $Mailbox.RecipientTypeDetails
                DelegatedPermissions          = $permissions -join '|'
            } 
        }
    }
    Catch {
        $out = $_.Exception.Message + " " + $_.Exception.ItemName
        $out | Out-File $logfile -Append
    }
}  
$results | Export-Csv $File -NoTypeInformation -encoding UTF8 -Delimiter ";"

