<#     
.SYNOPSIS     
     
  Get all computer objects from Active Directory with "Windows" in the OS name, sort by version and email HTML-formatted results 
         
.COMPATABILITY      
      
  Tested on PS v4.  
       
.EXAMPLE   
  PS C:\> Get-OSCount.ps1   
  All options are set as variables in the GLOBALS section so you simply run the script.   
   
.NOTES     
         
  NAME:       Get-OSCount.ps1     
     
  AUTHOR:     Brian D. Arnold     
     
  CREATED:    8/28/14   
     
  LASTEDIT:   9/3/14    
#> 
 
# Import AD module 
Import-Module ActiveDirectory 
 
################### 
##### GLOBALS ##### 
################### 
 
# Get domain 
$DomainName = (Get-ADDomain).NetBIOSName  
 
# How many days ago was the lastLogon attribute updated? 
$days = 90 
$lastLogonDate = (Get-Date).AddDays(-$days).ToFileTime() 
 
# SMTP settings 
$smtpServer = "mail.domain.com" 
$smtpFrom = "report@domain.com" 
$smtpTo = "ma@domain.com" 
$messageSubject = "$DomainName Windows OS Counts - lastLogon within $days days" 
 
# HTML settings 
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}" 
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}" 
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }" 
$style = $style + "TD{border: 1px solid black; padding: 5px; }" 
$style = $style + "< /style>" 
 
################ 
##### MAIN ##### 
################ 

@()
# Query AD 
$Computers = @(Get-ADComputer -Properties Name, operatingSystem, operatingSystemVersion, lastLogontimeStamp -Filter {(OperatingSystem -like "*") -AND (lastLogontimeStamp -ge $lastLogonDate)}) 
foreach ($Computer in $Computers) { 
    $Computer.OperatingSystem = $Computer.OperatingSystem -replace '®' -replace '™' -replace '专业版', 'Professional (Ch)' -replace 'Professionnel', 'Professional (Fr)' -replace '专业版', "Professional (Ch)"
    $Computer.operatingSystemVersion = $Computer.operatingSystemVersion -replace "(10240)", ":1507" -replace "(10586)", ":1511" -replace "(14393)", ":1607" -replace "(15063)", ":1703" -replace "(16299)", ":1709" -replace "(17134)", ":1803" -replace "(17763)", ":1809" 

} 


# Send output as email 
$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto 
$message.Subject = $messageSubject 
$message.IsBodyHTML = $true 
$message.Body = $Computers | Group-Object operatingSystem, operatingSystemVersion | Select Count, Name | Sort Name | ConvertTo-Html -Head $style 
 
$smtp = New-Object Net.Mail.SmtpClient($smtpServer) 
$smtp.Send($message)   
