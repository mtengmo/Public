Get-RemoteMailbox -ResultSize unlimited | Where-Object { $_.primarysmtpaddress -like "*'*" } | Select-Object primarysmtpaddress

