## Remove adminsholder from account
## https://specopssoft.com/blog/troubleshooting-user-account-permissions-adminsdholder/
$samaccountname = "am1791"

set-aduser $samaccountname -remove @{adminCount = 1 }

$user = get-aduser $samaccountname -properties ntsecuritydescriptor

$user.ntsecuritydescriptor.SetAccessRuleProtection($false, $true)

set-aduser $samaccountname -replace @{ntsecuritydescriptor = $user.ntsecuritydescriptor }
