try {
    Get-MsolDomain -ErrorAction Stop > $null
}
catch {
    if ($cred -eq $null) {$cred = Get-Credential $O365Adminuser}
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}


$phoneappnotificationcount = 0
# Setting the counters
$PhoneAppOTPcount = 0
$OneWaySMScount = 0
$TwoWayVoiceMobilecount = 0
$nomfamethod = 0
$MFAEnforced = 0
$MFAEnabled = 0
$MFADisabled = 0
$MFApossible = 0
$ADMobile_Without_MFA = 0

# Getting all users
$allusers = Get-MsolUser -all  | where {$_.isLicensed -eq $true}
# Going through every user
foreach ($induser in $allusers) {
    # Resetting the variables
    $methodtype = ""
    $strongauthmethods = ""
    $StrongAuthenticationRequirements = ""
    $upn = ""
    $strongauthmethods = $induser | select -ExpandProperty strongauthenticationmethods
    $StrongAuthenticationRequirements = $induser | select -ExpandProperty StrongAuthenticationRequirements
    $upn = $induser.userprincipalname
    # This check is if the user has even enrolled with MFA yet, otherwise we +1 to that counter.
    if (!$strongauthmethods) { $nomfamethod++ }
    # Going through all methods ...
    foreach ($method in $strongauthmethods) {
        # ... to find which is the default method.
        if ($method.IsDefault) {
            $methodtype = $method.MethodType
            if ($methodtype -eq "PhoneAppNotification") { $phoneappnotificationcount++ }
            elseif ($methodtype -eq "PhoneAppOTP") { $PhoneAppOTPcount++ }
            elseif ($methodtype -eq "OneWaySMS") { $OneWaySMScount++ }
            elseif ($methodtype -eq "TwoWayVoiceMobile") { $TwoWayVoiceMobilecount++ }
            # If you want to get a complete list of what MFA method every user got, remove the hashtag below
            # write-host "User $upn uses $methodtype as MFA method"
        }
    }

    #MFA Status
    if (!$StrongAuthenticationRequirements) { $MFADisabled++ }
    if ($StrongAuthenticationRequirements.state -eq 'Enforced') {$MFAEnforced++}
    elseif ($StrongAuthenticationRequirements.state -eq 'Enabled') {$MFAEnabled++ }
    
    #mobile
    if (($induser.mobilephone) -and (!$strongauthmethods)) {$ADMobile_Without_MFA++}


}

$MFApossible = $MFADisabled - $nomfamethod
$Hitrate = [math]::Round((($MFAEnforced + $MFAEnabled) / $allusers.count * 100))

# Now printing out the result
write-host "Amount of users using MFA App Notification: $phoneappnotificationcount" 
write-host "Amount of users using MFA App OTP Generator: $PhoneAppOTPcount"
write-host "Amount of users using SMS codes: $OneWaySMScount"
write-host "Amount of users using Phone call: $TwoWayVoiceMobilecount"
#write-host "Amount of users with no MFA method: $nomfamethod"

write-host "Amount of users using MFA Disabled: $MFADisabled" -ForegroundColor Red
write-host "Amount of users using MFA Enabled (Admin enabled MFA but enduser have not enrolled MFA): $MFAEnabled" -ForegroundColor Yellow
write-host "Amount of users with MFA Enforced (Enabled and enrolled): $MFAEnforced" -ForegroundColor Green
write-host "Amount of users with MFA method enrolled but not enabled by admin: $MFApossible" -ForegroundColor Green
write-host "Amount of users with AD Mobile Without MFA: $ADMobile_Without_MFA" -ForegroundColor Yellow
Write-Host "Hitrate: $Hitrate%" 

