$users = get-aduser -filter { Company -like "Acapela*" } -Properties proxyaddresses, mail, mailnickname | select Name, DistinguishedName, SamAccountname, @{Name = 'ProxyAddresses'; Expression = { $_.ProxyAddresses -join "," } }, userprincipalname, mail, @{n = "PrimarySMTPAddress"; e = { $_.proxyAddresses | Where { $_ -clike "SMTP:*" } } }


$maildomain = "@teams.newdomain.com" #new mail domain
$oldmaildomain = "@olddomain.com"



foreach ($user in $users) {
    $separator = "@" 
        $timestamp = Get-date
    $samaccountname = $user.samaccountname
    $Givenname = $user.Givenname
    $sn = $user.Surname
    $EmailAddress = $Givenname + "." + $sn + $maildomain
    $PrimarySMTPAddress = $user.PrimarySMTPAddress
    $NewPrimarySMTPAddress = $PrimarySMTPAddress -replace ($oldmaildomain, $maildomain)
    Write-Output "$timestamp : $samaccountname oldsmtp: $PrimarySMTPAddress will be replace with $NewPrimarySMTPAddress"
    $RemoveString = $PrimarySMTPAddress.split($separator)  
    $RemoveString = $RemoveString[0]
    $RemoveStringFqdn = "smtp:" + $RemoveString + "@tobiidynavox.com"
    $PrimarySMTPAddressAlias = $PrimarySMTPAddress -replace ("SMTP:","smtp:")
    $mailnick = $NewPrimarySMTPAddress -replace ("SMTP:","")

    #Set-ADUser -Identity $SamAccountName -Remove @{Proxyaddresses = $PrimarySMTPAddress }  
    #Set-ADUser -Identity $SamAccountName -Add @{Proxyaddresses = $NewPrimarySMTPAddress }  
    #Set-ADUser -Identity $SamAccountName -Add @{Proxyaddresses = $PrimarySMTPAddressAlias } 
    
    Set-ADuser -Identity $samaccountname  -replace @{mail = $mailnick }   

    #Write-Output "$timestamp : $samaccountname :  $PrimarySMTPAddressAlias $NewPrimarySMTPAddress "
    #Set-ADUser -Identity $SamAccountName -Remove @{Proxyaddresses = $RemoveStringFqdn } -server "sedc01.tbdvox.com"
}
