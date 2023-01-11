 
# Draft
# Busines Server
# 1 Update 10
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10\U4ERP7UPDATE10" -Recurse -Include *.msp
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 2 Msi:s
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10" -Recurse -Include *.msi 

foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 3 Msp:s
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10\Alla hotfix update10 för SÖ" -Recurse -Include *.msp  
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}




# Webserver
# 1 Update 10
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10\U4ERP7UPDATE10" -Recurse -Include *.msp | Where-Object {$_.Name -like "*64-bit*"}
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 2 Msi:s
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10" -Recurse -Include *.msi | Where-Object {$_.Name -like "*64-bit*"}

foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}


# 3 Msp:s
$files = Get-ChildItem -Path "E:\InstallFiles\2023-01-11\Update 10\Alla hotfix update10 för SÖ" -Recurse -Include *.msp  | Where-Object {$_.Name -like "*64-bit*"}
foreach ($msifile in $files)
{
    Write-Host " " | Out-Null
    Write-Host "Now applying hotfix: $msifile" | Out-Null
    $arguments= "/qr /norestart"
    Start-Process  -file  $msifile.FullName -arg $arguments -passthru | wait-process
}



 
# Other
# Act:s
dir -Path "E:\InstallUBW\2023-01-11\Update 10\Paketeringar att uppgradera\E-Procurement Sweden\SE-600028_22.4.0_M7" -Recurse | Unblock-File