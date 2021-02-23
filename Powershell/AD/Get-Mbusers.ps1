function Get-MBusers {
    Param (
        $Group,
        $adserver
    )
    
    $users=@()    
    
    $members = Get-Adgroup -Identity $Group -Server $adserver -Properties members | Select-Object -ExpandProperty Members | Where-Object {$_ -notmatch "ForeignSecurityPrincipals"}  | ForEach-Object {Get-ADObject $_ -Server $adserver}
    foreach ($member in $members) {
        Write-Debug "$($member.Name)"
    
        $type = Get-ADObject $member -server $ADServer -Properties samAccountname
    
        if ($type.ObjectClass -eq 'user') {
            $users += Get-Aduser $type.samaccountname -Server $ADServer
        }
    
        # If it's a group
        if ($type.ObjectClass -eq 'group') {
            Write-Debug "Breaking out group $($type.Name)"
            $users += Get-MBUsers $member $adserver
        }
    
    }    
    
    return $users
    }
    
    