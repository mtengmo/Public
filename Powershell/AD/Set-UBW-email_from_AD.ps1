#Requires -Modules SqlServer, ActiveDirectory
#requires -version 2
<#
.SYNOPSIS
  Update ad with email from UBW
.DESCRIPTION
1.0 Update AD from UBW with email address
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory = $false)][string]$ServerInstance = "",
    [Parameter(Mandatory = $false)][string]$database = "",
    [Parameter(Mandatory = $false)][string]$searchbase = "OU=Users,OU=Location,DC=domain,DC=se", #restrict to customer OU, not base OU because of security risks
    [Parameter(Mandatory = $false)][string]$query = "select  replace(a.domain_info,'domainname\','') as samaccountname, RTRIM(LTRIM(b.e_mail)) as e_mail, c.user_id as user_id 
    from aagusersec a, agladdress b , aaguser c 
    where a.user_id = b.dim_value 
    and a.user_id = c.user_id 
    and b.attribute_id = 'GN' 
    and c.status = 'N'
    "
)



$result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $database -Query $query -ErrorAction Stop | where { $_.e_mail -ne "" }

foreach ($user in $result) {
    Try {
        Write-Host "Looping through users:"$user.samaccountname":and email: $($user.e_mail)"
        $samaccountname = ""
        $email = ""
        $samaccountname = $user.samaccountname
        $email = $user.e_mail
        Get-ADUser -Filter { (SAMAccountName -eq $samaccountname) -and (emailaddress -ne $email) } -SearchBase $searchbase -Properties emailaddress | 
            Set-ADuser -emailaddress "$($user.e_mail)" -verbose 

    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output "$ErrorMessage for $FailedItem "
    }
}
