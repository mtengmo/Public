$SharedKey = "X1wyilNxxxx"
$CustomerId = "xxxx" #workspaceid

#region Functions
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
 
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
 
    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}
 
# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
 
    $headers = @{
        "Authorization"        = $signature;
        "Log-Type"             = $logType;
        "x-ms-date"            = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }
 
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
 
}


#Endregion
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($manufacturer -eq "Lenovo") {
  
    if (Get-Module -ListAvailable -Name LSUClient) {
        Write-Host "Module exists, updating"
        Update-Module LSUClient
    } 
    else {
        Write-Host "Module does not exist"
        Install-Module -Name 'LSUClient' -force
    }

 
    # Specify a field with the created time for the records
    $TimeStampField = get-date
    $TimeStampField = $TimeStampField.GetDateTimeFormats(115)
    
    #start
    #Find Updates
    $updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended }
    [array]$updates = Get-LSUpdate
    # Log Updates
    $updates  | Add-Member -MemberType NoteProperty "ComputerName" -Value $env:COMPUTERNAME
    $updatesjson = $updates | ConvertTo-Json  -Depth 1
    $LogType = "LSupdate" #name of logtable in Log Analytics
    Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body $updatesjson -logType $logType
    $LogType = "lsuclient_log" 
    foreach ($update in $updates) { 
        if ($update.Type -contains ('BIOS')) {
            Suspend-BitLocker -MountPoint "C:" -RebootCount 0 
            Write-Output "Suspend bitlocker"
        }
        #Save Updates
        Write-Host "Save - $($update.name)"
        Remove-item -path $env:temp\lsuclient-logging.log -ErrorAction SilentlyContinue
        Save-LSUpdate -package $update  -Verbose  *> $env:temp\lsuclient-logging.log
        [string]$imp = get-content  $env:temp\lsuclient-logging.log
        $Body = @{
            LogType      = "Save"
            ComputerName = $env:COMPUTERNAME
            UpdateID     = $($Update.id)
            UpdateName     = $($Update.name)
            LogMessage     = $imp
        }

        $bodyjson = $body | convertto-json
        Write-Host "Save - $($update.name)"
        Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body $bodyjson -logType $logType

        #Install
        Write-Host "Install - $($update.name)"
        Install-LSUpdate -Package $update -Verbose *> $env:temp\lsuclient-install-logging.log

        [string]$imp = get-content  $env:temp\lsuclient-install-logging.log
        $Body = @{
            LogType      = "Install"
            ComputerName = $env:COMPUTERNAME
            UpdateID     = $($Update.id)
            UpdateName     = $($Update.name)
            LogMessage     = $imp
        }

        $bodyjson = $body | convertto-json -Depth 1
        Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body $bodyjson -logType $logType
    }
}


# toast notifications
 