$version = 'C1'
if((Get-MpComputerStatus).RealTimeProtectionEnabled  -eq "True") {
    Write-Output "$version COMPLIANT"
    exit 0
} else {
    Write-Output "$version NON-COMPLIANT"
    exit 1
}