#
<# 
    .SYNOPSIS 
        This Azure Automation runbook disable slack users over scim api
 
    .DESCRIPTION 
       

    .PARAMETER 

    .EXAMPLE 
    Verison 1.0 - Production ready. 
  

    .OUTPUTS 
#> 

 
param( 
    [parameter(Mandatory = $false)][String] $upn = "",
    [parameter(Mandatory = $false)][String] $credentialname = "Slack_scim_api_token"
) 

$myCredential = Get-AutomationPSCredential -Name $credentialname
#$apiusername = $myCredential.UserName
#$securePassword = $myCredential.Password
$apipassword = $myCredential.GetNetworkCredential().Password
$token = $apipassword
$hostname = "https://api.slack.com"
$urlpath = "/scim/v1/Users?filter=email Eq '$upn'"
$contentType = "application/json"
$url = "$hostname$urlpath"
$tokenmask = $token.Substring($token.get_length() - 5)
$timestamp = Get-Date
Write-Output "$timestamp : $url token: xxxxxxxxxxxxxxxxxxxxxxxx$tokenmask"
try {
    $timestamp = Get-Date
    Write-Output "$timestamp : Starting searching for users $upn on $url"
    $Result = Invoke-RestMethod -uri $url `
        -Method Get `
        -ContentType $contentType `
        -Headers @{Authorization = "Bearer " + $token }
}
Catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output -Message $ErrorMessage
    Throw
}

if ($result.totalResults -eq 1) {
    $userid = $result.resources.id
    $urlpath = "/scim/v1/Users/$userid"
    $contentType = "application/json"
    $url = "$hostname$urlpath"
    $timestamp = Get-date
    Write-Output "$timestamp : Match - deactivate $($result.resources.username); (HTTP DELETE) on $url"
    try {
        Invoke-RestMethod -uri $url `
            -Method Delete `
            -ContentType $contentType `
            -Headers @{Authorization = "Bearer " + $token }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output -Message $ErrorMessage
    }

}
ElseIf ($result.totalResults -eq 0) {
    $timestamp = Get-Date
    Write-Output "$timestamp : No users matching"
}
else {
    $timestamp = Get-Date
    Write-Output "$timestamp : multiple records matches"
    Throw
}

Remove-Variable -name $token -ErrorAction SilentlyContinue
Remove-Variable -name $apipassword -ErrorAction SilentlyContinue
Remove-Variable -name $myCredential -ErrorAction SilentlyContinue
Remove-Variable -name $tokenmask -ErrorAction SilentlyContinue

$timestamp = Get-Date
Write-Output "$timestamp : Finish"

