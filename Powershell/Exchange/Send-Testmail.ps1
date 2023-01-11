$secpasswd = ConvertTo-SecureString "xxxxxx" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "username@company.com", $secpasswd
Send-MailMessage -To "firstname.lastname@company.com" -Subject "Subject" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "from@company.com"


