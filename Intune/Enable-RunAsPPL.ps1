#https://itm4n.github.io/lsass-runasppl/
#https://github.com/TristanvanOnselen/WorkplaceAsCode/blob/master/ProActive_Remediation/Remediate_WorkplaceHardening.ps1
try {
    #LLSA protection
    $REG_CREDG = "HKLM:SYSTEM\CurrentControlSet\Control\Lsa"
    $REG_CREDG_value = (Get-ItemProperty -Path $REG_CREDG).RunAsPPL

    if ($REG_CREDG_value -ne "1" ) {
        #LSA protection
        write-host "Start remediation for: Forces LSA to run as Protected Process Light (PPL)"
        Remove-ItemProperty -Path $REG_CREDG -Name "RunAsPPL" -Force -ErrorAction SilentlyContinue
        New-ItemProperty -Path $REG_CREDG -Name "RunAsPPL" -Value "1"  -PropertyType Dword
    }
    else {
        #No matching certificates, do not remediate     
        exit 0
    }  
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}