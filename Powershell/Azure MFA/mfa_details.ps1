try {
    Get-MsolDomain -ErrorAction Stop > $null
}
catch {
    if ($cred -eq $null) { $cred = Get-Credential $O365Adminuser }
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}

Get-MsolUser -all -Synchronized -EnabledFilter EnabledOnly | Where-Object { ($_.isLicensed -eq $true) } | 
Sort-Object -property UserPrincipalName | 
Select-Object UserPrincipalName, DisplayName, Department, Title, Office, 
@{N = 'Manager'; E = { (Get-ADUser (Get-ADUser -Filter { UserPrincipalName -eq $_.UserPrincipalName } -properties *).manager).UserPrincipalName } },
@{N = "MFA Status"; E = { if ( $_.StrongAuthenticationRequirements.State -ne $null) { $_.StrongAuthenticationRequirements.State } else { "Disabled" } } }, 
@{n = "Methods"; e = { ($_.StrongAuthenticationMethods).MethodType } }, 
@{n = "Method status"; e = { if ($_.StrongAuthenticationMethods.MethodType -ne $null) { "Enabled" } else { "Dislabed" } } }, 
@{n = "Mobile"; e = { if ($_.Mobilephone -like "") { "empty" } else { "true" } } } | 
Export-Csv c:\temp\mfa_details_not_enabled.csv -Delimiter ";" -Encoding utf8 -NoTypeInformation
