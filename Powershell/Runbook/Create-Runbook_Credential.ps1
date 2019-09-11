Connect-AzureRmAccount

#$cred = Get-Credential


$user = "user"
$pw = ConvertTo-SecureString "secretpassword" -AsPlainText -Force
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pw
$rsg = "rsg"
$accountname = "accountname" 
$credentialname = "cred name"
New-AzureRmAutomationCredential -AutomationAccountName $accountname -Name $credentialname -Value $cred -ResourceGroupName $rsg


$User = "Contoso\DChew"
$Password = ConvertTo-SecureString "Password" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
Set-AzureRmAutomationCredential -AutomationAccountName $accountname -Name $credentialname -ResourceGroupName $rsg -Value $cred