$secpasswd = ConvertTo-SecureString "xxxxxx" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "mailboxuser@domain.com", $secpasswd
Send-MailMessage -To "firstname.lastname@domain.com" -Subject "Subject" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "from@domain.com"


