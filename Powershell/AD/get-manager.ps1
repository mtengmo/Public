$searchbase = "OU=xxxx,OU=xxxx,DC=xxxx,DC=xxxx"

Function Get-Manager($user, $searchbase) {
    $info = @{}
    $userDetails = Get-ADUser -Filter "UserPrincipalName -eq '$user'" -SearchBase $searchbase -properties displayName, Manager
    $info["User"] = $userDetails.Name
    IF ($userDetails.manager) { # if not null
        $managerDetails = Get-ADUser (Get-ADUser -Filter "UserPrincipalName -eq '$user'" -SearchBase $searchbase -properties manager).manager -properties Manager
        $info["Manager"] = $managerDetails
    }
    New-Object -TypeName PSObject -Property $info
} 


Get-manager -user xxx@xxxxx.com -searchbase $searchbase