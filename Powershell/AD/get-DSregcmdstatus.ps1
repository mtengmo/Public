
function Get-DSregcmdstatus {
    
    $status = dsregcmd /status 
    $status -replace ' : ', ' ' | 
        Select-Object -Index 1, 2, 3, 4, 5, 6, 7, 13, 14, 15, 16, 17, 18, 19, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 51 | 
        ForEach-Object {$_.Trim() }  | 
        ConvertFrom-String -PropertyNames 'State', 'Status'
} 

get-DSregcmdstatus


$status = dsregcmd /status | Select-String -Pattern "NgcSet"
if ($status -match "NgcSet : NO") {    Write-Host "Removing windows hello legacy"; Certutil -deletehellocontainer         }



else { 
    # Windows hello for business enabled
}
