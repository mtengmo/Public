if (test-path "C:\ProgramData\Lenovo\ImController\Plugins\LenovoFirstRunExperiencePackage\x86\uninstall.ps1") {
    write-Host Lenovo Welcome found
    exit 1
}
Else {
    Write-Host No Lenovo welcome found
    exit 0
}
    