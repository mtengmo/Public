param( 
    [parameter(Mandatory = $true)][String] $upn = "",
    [parameter(Mandatory = $true)][String] $sn = "",
    [parameter(Mandatory = $true)][String] $GivenName = "",
    [parameter(Mandatory = $false)][String] $portalurl = "https://<company>.learnupon.com",
    [parameter(Mandatory = $false)][String] $credentialname = "<azure runbook credentials>"
)
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


$myCredential = Get-AutomationPSCredential -Name $credentialname
$apiusername = $myCredential.UserName
#$securePassword = $myCredential.Password
$apipassword = $myCredential.GetNetworkCredential().Password

#randomized password, using sso
$password = -join (33..126 | ForEach-Object { [char]$_ } | Get-Random -Count 30)

$body = @{"User" =
    @{
        "last_name"       = "$sn"
        "first_name"      = "$givenname"
        "email"           = $upn
        "password"        = $password
        "language"        = "en"
        "membership_type" = "Member"
    }
}

$body = $body | ConvertTo-Json
$contentType = "application/json; charset=utf-8"
#Write-Host "body: $body"
$apiurl = "$portalurl/api/v1/users"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiusername, $apipassword)))
$timestamp = Get-Date
try {
    $apiresult = Invoke-RestMethod -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } `
        -Uri $apiurl `
        -Method POST `
        -ContentType $contentType `
        -body $body
        
    Write-Output "$timestamp : $upn updated success! ID: $apiresult"
}
catch {
    $response = ParseErrorForResponseBody($_) 
    Write-Output "$timestamp : $upn $response to $apiurl"
}
Remove-Variable -name apiresult -ErrorAction SilentlyContinue
Remove-Variable -name response -ErrorAction SilentlyContinue
Remove-Variable -name password -ErrorAction SilentlyContinue
