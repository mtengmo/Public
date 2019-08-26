#get all ad-users that are disabled but still in GAL with "usermailboxtype"
get-aduser -filter { enabled -eq $false } -Properties * | where { $_.msExchRecipientTypeDetails -eq "2147483648" -and $_.msExchHideFromAddressLists -ne $true -and $_.title -ne "resource" } | Sort-Object Name | select Name, Samaccountname, msExchHideFromAddressLists | measure
