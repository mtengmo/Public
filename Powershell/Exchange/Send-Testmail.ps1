$secpasswd = ConvertTo-SecureString "xxxxxx" -AsPlainText -Force



$mycreds = New-Object System.Management.Automation.PSCredential "username@contoso.com", $secpasswd



Send-MailMessage -To "recipient@company.com" -Subject "Subject" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "timereport-noreply@tobiidynavox.com"


