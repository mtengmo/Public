
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

try {
    Get-MsolDomain -ErrorAction Stop > $null
}
catch {
    if ($cred -eq $null) { $cred = Get-Credential $O365Adminuser }
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}

$users = Get-MsolUser -all -EnabledFilter EnabledOnly | Where-Object { ($_.isLicensed -eq $true) } 

foreach ($user in $users) {
    $UserPrincipalName = $user.UserPrincipalName
    $DisplayName = $user.DisplayName
    $department = $user.department
    $title = $user.title
    $extensionattribute5 = (Get-ADUser -Filter { UserPrincipalName -eq $user.UserPrincipalName } -Properties Extensionattribute5).Extensionattribute5
    $extensionattribute7 = (Get-ADUser -Filter { UserPrincipalName -eq $user.UserPrincipalName } -Properties Extensionattribute7).Extensionattribute7
    $WhenCreated = $user.WhenCreated
    $LastPasswordChangeTimestamp = $user.LastPasswordChangeTimestamp
    $StsRefreshTokensValidFrom = $user.StsRefreshTokensValidFrom
    Write-Output $UserPrincipalName
    $MFA_default = ($user.StrongAuthenticationMethods | where { $_.isdefault -eq $true }).MethodType
    $Methods = $user.StrongAuthenticationMethods.methodtype -join "|"
    $Method_status = if ($user.StrongAuthenticationMethods.MethodType -ne $null) { "Enabled" } else { "Dislabed" }
    $mfa_number = $user.StrongAuthenticationUserDetails.Phonenumber
    $MobilePhone = if ($user.MobilePhone) {$user.MobilePhone} else { "Empty"}
    #$Mobile = if ($user.Mobilephone -like "") { "empty" } else { "true" } 
    $ReportLine = [PSCustomObject] @{
        UserPrincipalName           = $UserPrincipalName
        DisplayName                 = $DisplayName
        Department                  = $department
        Title                       = $title
        Methods                     = $Methods
        Method_status               = $Method_status
        MFA_default                 = $MFA_default
        extensionattribute5         = $extensionattribute5
        extensionattribute7         = $extensionattribute7
        WhenCreated                 = $WhenCreated
        LastPasswordChangeTimestamp = $LastPasswordChangeTimestamp
        StsRefreshTokensValidFrom   = $StsRefreshTokensValidFrom
        mfa_number                  = $mfa_number
        $MobilePhone                = $MobilePhone
    }
    
    $Report.Add($ReportLine)
} 
$report  | Export-Csv c:\temp\mfa_details.csv -Delimiter ";" -Encoding utf8 -NoTypeInformation

