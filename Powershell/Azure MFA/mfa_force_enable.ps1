#https://blogs.technet.microsoft.com/office365/2015/08/25/powershell-enableenforce-multifactor-authentication-for-all-bulk-users-in-office-365/
#https://justidm.wordpress.com/2018/09/14/bulk-pre-register-mfa-for-users-without-enable-mfa-on-the-account/comment-page-1/
#$upn = "mteo5@tobii.com"
	
$method1 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$method1.IsDefault = $true
$method1.MethodType = "OneWaySMS"
	
$method2 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$method2.IsDefault = $false
$method2.MethodType = "TwoWayVoiceMobile"
$methods = @($method1, $method2)
    
$auth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$auth.RelyingParty = "*"
$auth.State = "Enabled"
#$auth.RememberDevicesNotIssuedBefore = (Get-Date)

#Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationMethods $methods -StrongAuthenticationRequirements $auth

#Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationMethods $methods 
$users = import-csv C:\temp\Registerd_user_MFA.csv -Delimiter ","

foreach ($user in $users) {
    set-MsolUser -UserPrincipalName $user.Username -StrongAuthenticationRequirements $auth
    
    get-msoluser -UserPrincipalName $user.Username | 
        Select UserPrincipalName, Office, `
    @{n = "MFA"; e = {$_.StrongAuthenticationRequirements.State}}, `
    @{n = "Methods"; e = {($_.StrongAuthenticationMethods).MethodType}}
   
}


