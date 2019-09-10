$users = get-aduser -searchbase "OU=Disabled Objects,DC=tobii,DC=intra" -filter { enabled -eq $false } -Properties * | where { $_.msExchRecipientTypeDetails -eq "2147483648" -and $_.msExchHideFromAddressLists -ne $true -and $_.title -ne "resource" }
ForEach ($user in $users) {
    Get-ADuser $user.Samaccountname -Properties * 
    $user.msExchHideFromAddressLists = "True"
    Set-ADUser –instance $user
}