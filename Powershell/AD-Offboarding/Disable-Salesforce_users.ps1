#
<# 
    .SYNOPSIS 
        This Azure Automation runbook removes license for salesforce users
 
    .DESCRIPTION 
       

    .PARAMETER 

    .EXAMPLE 
    Verison 1.0 - Production ready. 
  

    .OUTPUTS 
#> 

 
param( 
    [parameter(Mandatory = $false)][String] $upn = "",
    [parameter(Mandatory = $false)][String] $urltoken = "https://login.salesforce.com/services/oauth2/token",   #"https://test.salesforce.com/services/oauth2/token",
    [parameter(Mandatory = $false)][String] $resourcegroup = "GlobalIT-companyTown",
    [parameter(Mandatory = $false)][String] $location = "North Europe",
    [parameter(Mandatory = $false)][String] $keyvaultname = "SF-companyAB",  #SalesforceStaging
    [parameter(Mandatory = $false)][String] $secretname_user = "liveuser",
    [parameter(Mandatory = $false)][String] $secretname_pass = "livepass",
    [parameter(Mandatory = $false)][String] $secretname_client = "liveclient",
    [parameter(Mandatory = $false)][String] $secretname_secret = "livesecret",
    [parameter(Mandatory = $false)][String] $tenantid = "xxxxx", #azuretenantid
    [parameter(Mandatory = $false)][String] $Applicationid = "xxxxxxx", # $applicationid = (Get-AzureADApplication -Filter "DisplayName eq 'companyTown-Onboarding-script'").Appid
    [parameter(Mandatory = $false)][String] $thumb = "xxxxxxxx", # thumbprint for selfsigned certificate on sedirsync01 used for authenticate
    [parameter(Mandatory = $false)][String] $urlposterror = "https://prod-74.westeurope.logic.azure.com:443/workflows/xxxxxxxx/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=xxxxx"

) 

Function Get-SalesforceAuthToken {
    [CmdletBinding()]
    param($ClientID, $urltoken, $clientSecret, $username, $password)     
    Write-Output "function Get-SalesforceAuthToken with urltoken $urltoken"
    try {
        $body = @{
            grant_type    = "password"
            client_id     = "$ClientID"
            client_secret = "$clientSecret"
            username      = "$username"
            password      = "$password"
        }
        $bodyjson = $body | ConvertTo-Json
        Write-Output "sending $bodyjson to $urltoken"
        $result = Invoke-RestMethod -uri $urltoken `
            -Method Post `
            -Body $body `
            # -ContentType $contentType
         
        Write-Output "Authcode: $result.auth_code"  
        Return $result
    }
    Catch {
        $body = @{
            grant_type    = "password"
            client_id     = "$ClientID"
            client_secret = "$clientSecret"
            username      = "$username"
            password      = "$password"
        }
        $bodyjson = $body | ConvertTo-Json
        Write-Error "error sent $bodyjson to $urltoken"
        $ErrorMessage = $_.Exception.Message
        Write-Output -Message $ErrorMessage
        $response = ParseErrorForResponseBody($_) 
        $timestamp = Get-Date
        Write-Error "$timestamp : $response to $urltoken"
        #Throw "Error $ErrorMessage"
    }
}
    
function ParseErrorForResponseBody($Error) {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        if ($Error.Exception.Response) {  
            $Reader = New-Object System.IO.StreamReader($Error.Exception.Response.GetResponseStream())
            $Reader.BaseStream.Position = 0
            $Reader.DiscardBufferedData()
            $ResponseBody = $Reader.ReadToEnd()
            if ($ResponseBody.StartsWith('{')) {
                $ResponseBody = $ResponseBody | ConvertFrom-Json
            }
            return $ResponseBody
        }
    }
    else {
        return $Error.ErrorDetails.Message
    }
}

#Start
$timestamp = Get-Date
Write-Output "$timestamp : Starting runbook Disable-Salesforce_users for $upn"
Write-Output "$timestamp : Connecting AzureAD"
#Connect-AzAccount -TenantId $tenantid  -ApplicationId  $Applicationid -CertificateThumbprint $thumb
#Install-Module AzureAD 
#Install-Module Az 
#Connect-AzureAD -TenantId $tenantid  -ApplicationId  $Applicationid -CertificateThumbprint $thumb

$connectionName = "AzureRunAsConnection"
#try
#{
# Get the connection "AzureRunAsConnection "
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName 
#-ResourceGroupName "Global_IT-Automation" -AutomationAccountName "seadsynccompanytown"
Write-Output "servicePrincipalConnection : $servicePrincipalConnection"
try { Get-AzureADCurrentSessionInfo -ErrorAction Stop -WhatIf:$false -Verbose:$false | Out-Null }
catch {
    try { 
        #Connect-AzureAD -WhatIf:$false -Verbose:$false -ErrorAction Stop | Out-Null 
        Add-AzureRmAccount -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    }
    catch {
        Write-Output "Login in to AzureAD before running this command, Connect-AzureAD"
        return $false 
    } 
}

#}
#catch {
#    if (!$servicePrincipalConnection)
#    {
#        $ErrorMessage = "Connection $connectionName not found."
#        throw $ErrorMessage
#    } else{
#        Write-Error -Message $_.Exception
#        throw $_.Exception
#    }
#}

#Get-AzureKeyVaultKey -VaultName YoutubeVault



$timestamp = Get-Date
Write-Output "$timestamp : Geting secrets from $keyvaultname in resourcegroup $resourcegroup and user $secretname_user"
#Import-Module Az.Keyvault -Verbose

$user = (Get-AzureKeyVaultSecret -vaultName $keyvaultname -name $secretname_user).SecretValueText
$pass = (Get-AzureKeyVaultSecret -vaultName $keyvaultname -name $secretname_pass).SecretValueText
$client = (Get-AzureKeyVaultSecret -vaultName $keyvaultname -name $secretname_client).SecretValueText
$secret = (Get-AzureKeyVaultSecret -vaultName $keyvaultname -name $secretname_secret).SecretValueText
$timestamp = Get-Date

if ($user -eq $null) {
    Write-Error "$timestamp :No user from $keyvaultname"
    Throw
}
$timestamp = Get-Date
Write-Output "$timestamp : Got login: $user , Pw: $pass and other secrets from keyvault: $keyvaultname"


$timestamp = Get-Date
Write-Output "$timestamp : Getting auth token from Salesforce $urltoken and user: $user"
$Authcode = (Get-SalesforceAuthToken -ClientID $client -clientSecret $secret -username $user -password $pass -urltoken $urltoken)

if ($Authcode -eq $null) {
    $timestamp = Get-Date
    Write-Error "$timestamp : No token from salesforce "
    Throw
}
$timestamp = Get-Date
Write-Output "$timestamp : Authcode: $($Authcode.Access_Token)"
#query
$query = "SELECT+id,name,IsActive+from+user+where+FederationIdentifier='$upn'" -replace " ", "+"

$timestamp = Get-Date
Write-Output "$timestamp : Getting data from Salesforce for $upn with query: $query"

$APIresult = Invoke-RestMethod "$($Authcode.instance_url)/services/data/v20.0/query?q=$query" `
    -ErrorVariable $RestError  `
    -Method Get `
    -Headers @{
    Authorization = "Bearer $($Authcode.Access_Token)"
    Accept        = "application/xml"   
}
if ($RestError) {
    $HttpStatusCode = $RestError.ErrorRecord.Exception.Response.StatusCode.value__
    $HttpStatusDescription = $RestError.ErrorRecord.Exception.Response.StatusDescription
    
    Throw "Http Status Code: $($HttpStatusCode) `nHttp Status Description: $($HttpStatusDescription)"
    Throw
}


#removing license from user
#number of results
[int]$totalsize = $APIresult.QueryResult.totalsize
#parse path
[string]$urlpath = $APIresult.QueryResult.Records.Url
[string]$url = "$($Authcode.instance_url)$urlpath"


if ($totalsize -eq 1) {
    $timestamp = Get-Date
    Write-Output "$timestamp : Removing license for $upn on $url"

    $body = @{
        IsActive = "false"
    }
    $body = $body | ConvertTo-Json
    $contentType = "application/json"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        #Post to salesforce
        $result = Invoke-RestMethod -Method Patch -Uri $url -Body $body -contenttype $contentType  `
            -ErrorVariable $RestError `
            -ErrorAction SilentlyContinue `
            -Headers @{ `
                Authorization = "Bearer $($Authcode.Access_Token)"
        }
    }
    catch { 
        $timestamp = Get-Date
        Write-Output "$timestamp : Failing removing license for $upn"
        $response = ParseErrorForResponseBody($_) 
        $responseobj = $response | convertfrom-json
        $responseobj | Add-Member -MemberType NoteProperty "upn" -Value  $upn
        $response = $responseobj | ConvertTo-json
        $timestamp = Get-Date
        Write-Output "$timestamp : $response to $urlposterror"
        Invoke-RestMethod -uri $urlposterror -body $response -Method Post -ContentType $contentType
    }
}
ElseIf ($totalsize -eq 0) {
    $timestamp = Get-Date
    Write-Output "$timestamp : No users matching"
}
else {
    $timestamp = Get-Date
    Write-Output "$timestamp : multiple records matches"
    Throw
}

$timestamp = Get-Date
Write-Output "$timestamp : Stopping runbook Disable-Salesforce_users"


    
