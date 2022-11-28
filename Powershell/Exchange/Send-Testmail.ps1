$secpasswd = ConvertTo-SecureString "xxxxxx" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "reporting_sql@tbdvox.com", $secpasswd
Send-MailMessage -To "neil.vidt@tobiidynavox.com" -Subject "Subject" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "sql.reporting@tobiidynavox.com"


