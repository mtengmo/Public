 
# Draft
# Busines Server
# 1 Update 14
$files = Get-ChildItem -Path "E:\Installubw\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msp
foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 1 Msi:s  # req
$files = Get-ChildItem -Path "E:\Installubw\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msi 

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
$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\Hotfix 241108" -Recurse  -Include *.msp  
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



# Webserver
# 1 Update 14
$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msp | Where-Object {$_.Name -like "*64-bit*"}
foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

#requisition
$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msi 
foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# helpfiles
$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\UNIT4 ERP Desktop HelpUPD14" -Recurse -Include *.msi 

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\UNIT4 ERP Web HelpUPD14" -Recurse -Include *.msi 
$files.count

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 3 Msp:s
$files = Get-ChildItem -Path "E:\InstallUBW\2024-11\Hotfix 241108" -Recurse -Include *.msp  | Where-Object {$_.Name -like "*64-bit*"}
$files.count

foreach ($msifile in $files)
{
    $timestamp = get-date
    Write-Host " " | Out-Null
    Write-Host "$timestamp : Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# WinSCP
#act
# asqipamipam

 
# Other
# Act:s
dir -Path "E:\InstallUBW\2023-01-11\Update 10\Paketeringar att uppgradera\E-Procurement Sweden\SE-600028_22.4.0_M7" -Recurse | Unblock-File