$file = "C:\temp\mfa_no_methods2.csv"

# connect to Azure Active Directory
Connect-MsolService

# obtain users who did not have setup MFA
$allusers = Get-MsolUser -all -Synchronized -EnabledFilter EnabledOnly | 
    where {$_.isLicensed -eq $true} 
    
#| Where-Object {[string]::IsNullOrEmpty($_.StrongAuthenticationMethods)}

# export to csv
$allusers | 
    Select UserPrincipalName, Office, 
@{N = "MFA Status"; E = { if ( $_.StrongAuthenticationRequirements.State -ne $null) { $_.StrongAuthenticationRequirements.State} else { "Disabled"}}}, 
@{n = "Methods"; e = {($_.StrongAuthenticationMethods).MethodType}}, 
@{n = "Mobile"; e = {if ($_.Mobilephone -like "") {"empty"} else {"true"}}} |
    export-csv -Delimiter ";" -Encoding UTF8  -NoTypeInformation -Path $file
