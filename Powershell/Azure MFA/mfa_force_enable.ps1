#requires -version 2
<#
.SYNOPSIS
  Enable MFA from CSV file
.DESCRIPTION
#https://blogs.technet.microsoft.com/office365/2015/08/25/powershell-enableenforce-multifactor-authentication-for-all-bulk-users-in-office-365/
#https://justidm.wordpress.com/2018/09/14/bulk-pre-register-mfa-for-users-without-enable-mfa-on-the-account/comment-page-1/
  
.PARAMETER file
 CSV file with userprinipalname as header
.INPUTS
  None.
.OUTPUTS
  MFA status
.NOTES
  Version:        1.0
  Creation Date:  2019-03-13
  Purpose/Change: Initial script development
.EXAMPLE
  Execution of script using default parameters. Default execution performs reporting of inactive AD computers only, not disabling or deleting any objects.
  By default the report is saved in C:\.
  .\Find-ADInactiveComputers.ps1
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory = $true)][string]$file
   
)

try {
    Get-MsolDomain -ErrorAction Stop > $null
}
catch {
    if ($cred -eq $null) {$cred = Get-Credential $O365Adminuser}
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}


$users = import-csv $file -Encoding utf8

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
$auth.RememberDevicesNotIssuedBefore = (Get-Date)

foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements $auth
    #Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationMethods $methods -StrongAuthenticationRequirements $auth
    #Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationMethods $methods 
        
    get-msoluser -UserPrincipalName $upn | 
        Select UserPrincipalName, Office, MobilePhone, `
    @{n = "MFA"; e = {$_.StrongAuthenticationRequirements.State}}, `
    @{n = "Methods"; e = {($_.StrongAuthenticationMethods).MethodType}}
   
}


