 
# Draft
# Busines Server
# 1 Update 14
# stop ubw services and web apps


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
$files.count

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
# stop web application pool

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
#18 files
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


# ehandel
# act installer
# Copy P4600028.E-handel.dll to Centrally Configured Clients
#Copy the P4600028.E-handel.dll file to the Bin directory of Centrally Configured Clients.
#Note:
#If the environment is a Citrix environment or similar, you may have to copy the file into the Bin directories used by this application. If the environment is set up without Centrally Configured Clients, you must copy the file to the root Bin folder of Unit4 ERP on the application server.
#Page 6
#Copy AgressoSE .dll files to Web client Bin directory
#Copy the following .dll files to the Bin directory for the Web client:
#l
#AgressoSE.Interface.ProcurementAndSales.Catalogue.dll
#l
#AgressoSE.Module.ProcurementAndSales.Catalogue.dll
#l
#AgressoSE.UIController.ProcurementAndSales.Catalogue.dll
#The usual path to this folder is similar to this one: C:\Program Files\UNIT4 Business World On! (v7)\Web\bin.