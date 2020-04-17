<# 
    .SYNOPSIS 
    .DESCRIPTION 
       Update LearnUpOn users over API from an Azure Runbook
    .PARAMETER 
    .EXAMPLE 
    Verison 0.1 - first release. 
    .OUTPUTS 
#> 

param( 
    [parameter(Mandatory = $false)][String] $portalurl = "https://tenant.learnupon.com",
    [parameter(Mandatory = $false)][String] $credentialname = "LearnUpOn_tenant.learnupon.com"

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
###$securePassword = $myCredential.Password
$apipassword = $myCredential.GetNetworkCredential().Password

$users = get-aduser -filter { Company -eq "company" -and Enabled -eq $true -and title -ne "resource" } -Properties extensionAttribute4, ExtensionAttribute8, Company, Department, Office, Title

$count = $users.count
Write-Output "Number of users: $count"

ForEach ($user in $users) {
    $manager = (Get-ADUser (Get-ADUser -Identity $user.samaccountname -properties manager).manager -properties Manager).Name

    $Body = @{'User' = 
        @{enabled      = $user.enabled
            email      = $user.UserPrincipalName
            last_name  = $user.surname
            first_name = $user.GivenName
            CustomData = 
            @{is_manager      = $user.extensionAttribute8
                global_team   = $user.department
                Work_location = $user.office
                Manager_name  = $manager
                Start_date    = $user.extensionAttribute4
                Business_Unit = $user.company
                job_title     = $user.title
            }
        }
    }

    $json = $body | ConvertTo-Json
    $contentType = "application/json"
    $body = [System.Text.Encoding]::UTF8.GetBytes($json)
    Write-Host "body: $body"
    

    $apiurl = "$portalurl/api/v1/users/0" # 0 is "none" and learnupon will match on email

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiusername, $apipassword)))
    $timestamp = Get-Date
    try {
        $apiresult = Invoke-RestMethod -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } `
            -Uri $apiurl `
            -Method PUT `
            -ContentType $contentType `
            -body $body
        
        Write-Output "$timestamp : $($user.UserPrincipalName) updated success! ID: $apiresult"
    }
    catch {
        $response = ParseErrorForResponseBody($_) 
        #$responseobj = $response | convertfrom-json
        #$response = $responseobj | ConvertTo-json
        #$timestamp = Get-Date
        Write-Output "$timestamp : $($user.UserPrincipalName) $response to $apiurl body: $json"
    }
    Remove-Variable -name apiresult -ErrorAction SilentlyContinue
    Remove-Variable -name response -ErrorAction SilentlyContinue
    Remove-Variable -name manager -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200 #throttle API request, best practice from API manual 5 request/s. 
}

