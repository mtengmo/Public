#Write Log Function

function Write-Log2 ($CompDiskName, [int]$number ,$PartitionStyle, $ProvisioningType, $BusType, $BootFromDisk  ) {
    #Get log
    $body=@()
    $Log = "$(Get-Date -UFormat "%T") - $LogMsg"
    # Log analytics 
    # https://wintellisys.com/store-custom-logs-in-azure-log-analytics-workspace-using-powershell/
    $Body = @{
        "Requester"        = "$env:USERNAME"
        "ComputerName"     = "$env:COMPUTERNAME"
        "CompDiskName"    =  "$CompDiskName"
        "Number"           = "$number"
        "PartitionStyle"   = "$PartitionStyle"
        "ProvisioningType" = "$ProvisioningType"
        "BusType"          = "$BusType"
        "BootFromDisk"     = "$BootFromDisk"
        "Version"          = "2"
    } | ConvertTo-Json
 
    $CustomerId = "857d1165-0f61-45b1-83dc-edf0c5128308"
    $SharedKey = "X1wyilNJxL/RukRhyYIK6kZOovUmtuhrEUSUnwyuCbVd0cudMg8Fi0A2EESWaAYA2cuB3ZC893IsAMGjIAdPDA=="
    $StringToSign = "POST" + "`n" + $Body.Length + "`n" + "application/json" + "`n" + $("x-ms-date:" + [DateTime]::UtcNow.ToString("r")) + "`n" + "/api/logs"
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToSign)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $HMACSHA256 = New-Object System.Security.Cryptography.HMACSHA256
    $HMACSHA256.Key = $KeyBytes
    $CalculatedHash = $HMACSHA256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $Authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash

    $Uri = "https://" + $CustomerId + ".ods.opinsights.azure.com" + "/api/logs" + "?api-version=2016-04-01"
    $Headers = @{
        "Authorization"        = $Authorization;
        "Log-Type"             = "Diskinfo";
        "x-ms-date"            = [DateTime]::UtcNow.ToString("r");
        "time-generated-field" = $(Get-Date)
    }
    Write-Output $Headers
    Write-Output $body
    $Response = Invoke-WebRequest -Uri $Uri -Method Post -ContentType "application/json" -Headers $Headers -Body $Body -UseBasicParsing
    if ($Response.StatusCode -eq 200) {
        Write-Information -MessageData "Logs are Successfully Stored in Log Analytics Workspace" -InformationAction Continue
    }

}


$disks = Get-Disk
foreach ($disk in $disks) {
    $CompDiskName = $disk.CimSystemProperties.ServerName
    $PartitionStyle = $disk.PartitionStyle
    $number = $disk.Number
    $ProvisioningType = $disk.ProvisioningType
    $BusType = $disk.BusType
    $BootFromDisk = $disk.BootFromDisk
    Write-Log2 -CompDiskName $CompDiskName -number $number -PartitionStyle $PartitionStyle -ProvisioningType $ProvisioningType -BusType $BusType -BootFromDisk $BootFromDisk
}

