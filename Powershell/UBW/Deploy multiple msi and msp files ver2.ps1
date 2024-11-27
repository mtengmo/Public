 
# Draft
# Busines Server
# 1 Update 10
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msp
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 1 Msi:s  # req
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msi 

foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 3 Msp:s
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\Hotfix 241108" -Recurse -Include *.msp  
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

# ASQs



# Webserver
# 1 Update 10
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msp | Where-Object {$_.Name -like "*64-bit*"}
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\U4ERP7UPDATE14" -Recurse -Include *.msi 
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 2 Msi:s
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\UNIT4 ERP Desktop HelpUPD14" -Recurse -Include *.msi | Where-Object {$_.Name -like "*64-bit*"}

foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}

$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\UNIT4 ERP Web HelpUPD14" -Recurse -Include *.msi | Where-Object {$_.Name -like "*64-bit*"}

foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 3 Msp:s
$files = Get-ChildItem -Path "E:\InstallFiles\2024-11\Hotfix 241108" -Recurse -Include *.msp  | Where-Object {$_.Name -like "*64-bit*"}
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# WinSCP
#act
# asq

 
# Other
# Act:s
dir -Path "E:\InstallUBW\2023-01-11\Update 10\Paketeringar att uppgradera\E-Procurement Sweden\SE-600028_22.4.0_M7" -Recurse | Unblock-File