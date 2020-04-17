#requires -modules ActiveDirectory
<# 
    Hardoffboarding in AD
    This script removes user from all AD groups except domain users.
        
#> 
 
param( 
    [parameter(Mandatory = $false)] 
    [String] $samaccountname = ""
) 

$exist = (get-Aduser $samaccountname).Enabled

if ($exist -eq $false) {

    $dc = (Get-ADDomain).PDCEmulator
    $timestamp = Get-Date
    #$ADgroups = Get-ADPrincipalGroupMembership -Identity $samaccountname -server $dc | where { $_.Name -ne "Domain Users" }
    #if ($ADgroups -ne $null) {
    #    Remove-ADPrincipalGroupMembership -Identity $samaccountname -MemberOf $ADgroups -Confirm:$false
    #    $ADgroups | ForEach-Object {
    #        $Name = $_.Name
    #        Write-Output "$timestamp : Removed $samaccountname from $Name"
    #    }
    #}

    # moved to disabled ou
    $domaindn = (Get-ADDomain).DistinguishedName
    $disabledou = "OU=Users Disabled,OU=Disabled Objects"
    Get-ADUser $samaccountname | Move-ADObject -TargetPath "$disabledou,$domaindn"

    Set-ADUser -Identity $samaccountname -replace @{ExtensionAttribute15 = "hardoffboarded" }

    $timestamp = Get-Date
    Write-Output "$timestamp : Finished runbook Remove-All_ADGroup_On_user for $samaccountname"

}