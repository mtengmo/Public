Get-MsolUser -All | 
    where {$_.isLicensed -eq $true -and $_.BlockCredential -eq $true} | 
    Select UserPrincipalName, MSExchRecipientTypeDetails, @{n="lastlogon";e={(Get-MailboxStatistics -identity $_.UserPrincipalName).lastlogontime}}| 
    Export-Csv -Path "C:\temp\O365Licensed_ADDisabledUsers_2.txt" -NoTypeInformation -Delimiter ";"


