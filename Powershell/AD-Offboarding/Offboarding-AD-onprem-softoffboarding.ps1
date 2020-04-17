#requires -modules ActiveDirectory
<# 
    Softoffboarding in AD
    This script removes user from all AD groups except domain users.
        
#> 
 
param( 
    [parameter(Mandatory = $false)] 
    [String] $samaccountname = "",
    [parameter(Mandatory = $false)][String] $webhookuri = "https://outlook.office.com/webhook/xxxxxIncomingWebhook/xxxxxxx"

) 

$exist = (get-Aduser $samaccountname).Enabled

if ($exist -eq $false) {

    $dc = (Get-ADDomain).PDCEmulator
    $timestamp = Get-Date
    $ADgroups = Get-ADPrincipalGroupMembership -Identity $samaccountname -server $dc | where { $_.Name -ne "Domain Users" }
    if ($ADgroups -ne $null) {
        Remove-ADPrincipalGroupMembership -Identity $samaccountname -MemberOf $ADgroups -Confirm:$false
        $ADgroups | ForEach-Object {
            $Name = $_.Name
            Write-Output "$timestamp : Removed $samaccountname from $Name"
        }
    }

    $groupsconcat = $ADgroups.name -join ";"
    $timestamp = Get-Date
    $body = ConvertTo-JSON -Depth 2 @{
        title = 'Soft offboarded user'
        text  = "$timestam : User: $samaccountname Removed Groups: $groupsconcat"
    }
     
    Invoke-RestMethod -uri $webhookuri -Method Post -body $body -ContentType 'application/json'


    $timestamp = Get-Date
    Write-Output "$timestamp : Finished runbook Offboarding-AD-onprem-softoffboarding.ps1 for $samaccountname"

}