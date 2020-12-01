#this will search all users blocked email lists and remove any that are in the domain
$domain=".+@company.com"
$users= get-mailbox -recipienttypedetails UserMailbox
foreach ($user in $users){
    $Trusted=get-mailboxjunkemailconfiguration -identity $user.UserPrincipalName |Select-Object -exp TrustedSendersAndDomains
    #check to see if the blocked list includes any on the domain
    foreach ($item in $Trusted){
        if((select-string -InputObject $item -pattern $domain) -match $domain){
            $address=(select-string -InputObject $item -pattern $domain)
            #remove the domain address from their blocked list
            #set-MailboxJunkEmailConfiguration -identity $user –BlockedSendersAndDomains @{remove="$address"}
            write-host "Removed $address from $($user.UserPrincipalName) TrustedSendersAndDomains list"
        }
    }
    $blocked=get-mailboxjunkemailconfiguration -identity $user.UserPrincipalName |Select-Object -exp BlockedSendersAndDomains
   # check to see if the blocked list includes any on the domain
    foreach ($item in $blocked){
        if((select-string -InputObject $item -pattern $domain) -match $domain){
            $address=(select-string -InputObject $item -pattern $domain)
            #remove the domain address from their blocked list
            #set-MailboxJunkEmailConfiguration -identity $user –BlockedSendersAndDomains @{remove="$address"}
            write-host "Removed $address from $($user.UserPrincipalName) blockedSendersAndDomains list" -ForegroundColor green
        }
    }
}


