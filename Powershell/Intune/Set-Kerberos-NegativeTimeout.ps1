# https://microsoft.github.io/GlobalSecureAccess/Entra%20Private%20Access/OnPremSSO#kerberos-negative-cache
# Script to fix kerberos for global access client
# Define the registry path and entry
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$entryName = "FarKdcTimeout"
$entryType = "DWORD"
$entryValue = 0

# Check if the Parameters key exists, if not, create it
if (-not (Test-Path $registryPath)) {
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos" -Name "Parameters" -Force
}

# Set the FarKdcTimeout registry entry
Set-ItemProperty -Path $registryPath -Name $entryName -Value $entryValue -Type $entryType

# Verify the change
if ((Get-ItemProperty -Path $registryPath -Name $entryName).$entryName -eq $entryValue) {
    Write-Output "Registry key $entryName set to $entryValue successfully."
} else {
    Write-Output "Failed to set registry key $entryName."
}