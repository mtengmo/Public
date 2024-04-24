Function Remove-InvalidFileNameChars {

    param([Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$Name
    )
    
    return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')
}

#install msgraph beta module before running this script
connect-mggraph -Scopes "Mail.Read,Mail.Read.Shared" -DeviceCode

$UserId = "upn@domain.com"


$folderid = 'c:\temp\marks\AllAttachments2022'

#filter out emails with attachments created in 2022
$messages = Get-MgBetaUserMessage -userid $UserId -all -filter "hasAttachments eq true AND createdDateTime le 2023-01-01T00:00:00Z AND createdDateTime ge 2022-01-01T00:00:00Z"   
#backup of export json
$messages | convertto-json -Depth 100 | out-file $folderid\messages.json

# Loop through each message and download attachments
foreach ($message in $messages) {
    $attachments = Get-MgBetaUserMessageAttachment -UserId $UserId -MessageId $message.Id  
    
    foreach ($attachment in $attachments) {
        # Get Attachment as Base64
        $Base64B = ($attachment).AdditionalProperties.contentBytes
        # remove invalid characters from the filename
        $filename = Remove-InvalidFileNameChars $($attachment.Name)
        $path = $folderid + "\" + $filename
        # Check if file already exists
        if (Test-Path $path -PathType leaf) {
            
            # Append a timestamp to make the filename unique
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
          #  $filename = Remove-InvalidFileNameChars $($attachment.Name)
            $path = $folderid + "\Duplicates\" + $filename + "_$timestamp" + "_" + "$filename"
            Write-Output "duplicate $path"
        }
        Write-Output $path
        # Save Base64 to file
        $Bytes = [Convert]::FromBase64String($Base64B)
        [IO.File]::WriteAllBytes($path, $Bytes)

    }
}

