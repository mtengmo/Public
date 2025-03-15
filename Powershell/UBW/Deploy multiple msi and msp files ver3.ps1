 
# Draft
# Busines Server
# 1 Update 14
$rootfolder = "c:\install\2025-02"
$files = Get-ChildItem -Path "$rootfolder\U4ERP7UPDATE14" -Recurse -Include *.msp
foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 1 Msi:s  # req
$files = Get-ChildItem -Path "$rootfolder\U4ERP7UPDATE14" -Recurse -Include *.msi 

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}



# helpfiles
$files = Get-ChildItem -Path "$rootfolder\UNIT4 ERP Desktop HelpUPD14" -Recurse -Include *.msi 

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

$files = Get-ChildItem -Path "$rootfolder\UNIT4 ERP Web HelpUPD14" -Recurse -Include *.msi 
$files.count

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# Hotfixes
# verify number in files, 32 files 
$files = Get-ChildItem -Path "$rootfolder\Hotfix 241108" -Recurse  -Include *.msp  
foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

# ASQs
#update manager - update + requistions
# asq´s



# WinSCP
#act
# asqipamipam

 
# Other
# Act:s
dir -Path "E:\InstallUBW\2023-01-11\Update 10\Paketeringar att uppgradera\E-Procurement Sweden\SE-600028_22.4.0_M7" -Recurse | Unblock-File