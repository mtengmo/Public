Get-MsolUser -all -Synchronized -EnabledFilter EnabledOnly| where {($_.isLicensed -eq $true) -and ($_.office -notlike "")}  | 
    sort-Object -property UserPrincipalName | 
    Select UserPrincipalName, Office, `
    @{n = "MFA"; e = {$_.StrongAuthenticationRequirements.State}}, `
    @{n = "Methods"; e = {($_.StrongAuthenticationMethods).MethodType}}, `
    @{n = "Mobile"; e =  {(if ($_.Mobilephone) {"true"} else {"blank"})}}   | 
    export-csv c:\temp\mfa_status_office2.csv -Delimiter ";" -Encoding utf8 -NoTypeInformation

