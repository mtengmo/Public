# Replace with your Workspace ID
$CustomerId = "857d1xxxx" 
# Replace with your Primary Key
$SharedKey = "X1wyilNJxL/xxxxxx=="
$version = 3

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


function Get-SystemSpecs {

    Function Get-LenovoFamilyName ($model) {
        #$ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        #if ($ComputerSystem.Manufacturer -eq "LENOVO") {
    
        $URL = "https://download.lenovo.com/bsco/schemas/list.conf.txt" 
        $OutFile = "$env:temp\Models_List.txt" 
        Invoke-WebRequest -Uri $URL -OutFile $OutFile 
        $Get_Models = Get-Content $OutFile | where-object { $_ -like "*$Model*" } 
        $Get_FamilyName = ($Get_Models.split("("))[0]
        Return $Get_FamilyName
    }

    $processorSpecs = gcim win32_processor
    $processorName = $processorSpecs.Name
    $processorSpeed = [string]([math]::round(($processorSpecs.CurrentClockSpeed / 1000), 2)) + 'ghz'
    $processorCores = $processorSpecs.NumberOfCores
    $processorThreads = $processorSpecs.ThreadCount
    $ramTotal = "{0:N0}" -f (((gcim CIM_PhysicalMemory | select -ExpandProperty Capacity) | measure -Sum).sum / 1gb ) 
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($ComputerSystem.Manufacturer -eq "LENOVO") {
        $LenovoFamilyName = Get-LenovoFamilyName $($ComputerSystem.model).substring(0,4)
    }
    function HDD-Details {
        $hdd = gcim Win32_DiskDrive | where { $_.MediaType -like "Fixed*" }
        $hdd | ForEach { $_.caption + ", Capacity: " + [math]::round(($_.Size / 1GB), '2') + "GB" }
    }

    
    $Specs = [pscustomobject]@{
        'Version'                 = $version
        'ComputerName'            = $env:ComputerName
        'Processor'               = $processorName
        'Cores'                   = $processorCores
        'ThreadCount'             = $processorThreads
        'ProcessorClockSpeed'     = $processorSpeed
        'Physical Memory Size'    = $ramTotal + ' GB'
        'System Type'             = gcim win32_operatingsystem | select -ExpandProperty OSArchitecture
        'Hard Drive(s)'           = HDD-Details
        'Serial'                  = gcim win32_bios | select -expandproperty serialnumber
        'OS'                      = gcim win32_operatingsystem | select -expandproperty caption
        'Physical Memory Size GB' = $ramTotal
        'Manufacturer'            = $($ComputerSystem.Manufacturer)
        'Model'                   = $($ComputerSystem.Model)
        'LenovoFamilyName'        = $LenovoFamilyName
    }
    return $Specs
}
 
#endregion

 
# Specify the name of the record type that you'll be creating
$LogType = "system_specs"
 
# Specify a field with the created time for the records
$TimeStampField = get-date
$TimeStampField = $TimeStampField.GetDateTimeFormats(115)
 

#start
$specs = Get-SystemSpecs

$specs = $specs | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body $specs -logType $logType
