#https://techcommunity.microsoft.com/blog/exchange/public-preview-high-volume-email-for-microsoft-365/4102271
#
New-MailUser -HVEAccount -Name "HVE-Workday-Sandbox" -PrimarySmtpAddress "HVE-Workday-Sandbox@tobiidynavox.com"

New-MailUser -HVEAccount -Name "HVE-Workday-Prod" -PrimarySmtpAddress "HVE-Workday-Prod@tobiidynavox.com"

set-user -AuthenticationPolicy "Allow only BasicAuth SMTP" -Identity "hve-workday-sandbox@tobiidynavox.com"


#test mail
$secpasswd = ConvertTo-SecureString "Ql26BjiCv73itCFvYLZC" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "HVE-Workday-Prod@tobiidynavox.com", $secpasswd
Send-MailMessage -To "magnus.tengmo@tobiidynavox.com" -Subject "Subject" -SmtpServer "smtp-hve.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "HVE-Workday-Prod@tobiidynavox.com"


$secpasswd = ConvertTo-SecureString "Ql26BjiCv73itCFvYLZC" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential "HVE-Workday-Prod@tobiidynavox.com", $secpasswd
Send-MailMessage -To "magnus.tengmo@tobiidynavox.com" -Subject "Subject" -SmtpServer "smtp-hve.office365.com" -Credential $mycreds -UseSsl -Port "587" -From "workday@tobiidynavox.com" -replyto "workday@tobiidynavox.com"

