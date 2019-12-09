#requires -version 2
<#
.SYNOPSIS

.DESCRIPTION
1.0 Enable TDE
#>

Param (
    [Parameter(Mandatory = $false)][string]$customernumber = "",
    [Parameter(Mandatory = $false)][string]$sqlinstance = "",
    [Parameter(Mandatory = $false)][string]$sqlinstancetest = ""


    
)



$database = "p$customernumber"
$KeyVaultKeyName = 'Keyvaultname-SQL-TDE'
#$ErrorActionPreference      = "Stop"
$StartTime = $(get-date)
$sqlinstance_certname = $sqlinstance + "-ServerCert"
$expdate = (get-date).Adddays(+10000)
Get-date
Write-Output "$timestamp : Starting for db $database"
$session = Get-AzContext
if ($session -eq $null) {
    Connect-AzAccount
}

$masterkey = Get-DbaDbMasterKey -SqlInstance $sqlinstance
if ($masterkey -eq $null) {
    
    $timestamp = get-date
    Write-Output "$timestamp : Creating masterkey on $sqlinstance" 
    $asci = [char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126))
    $password = (1..$(Get-Random -Minimum 20 -Maximum 40) | % { $asci | get-random }) -join ""
    $Secure_String_Pwd = ConvertTo-SecureString $password -AsPlainText -Force
    #masterkey master db
    New-DbaDbMasterKey -SqlInstance $sqlinstance -securePassword $Secure_String_Pwd
    Set-AzKeyVaultSecret -VaultName $KeyVaultKeyName -Name $sqlinstance'-masterkey'  -SecretValue $Secure_String_Pwd
    #instance certificate

    New-DbaDbCertificate -SqlInstance $sqlinstance  -Database master -name $sqlinstance_certname -ExpirationDate $expdate

}


$sqlscript = "
select * from sys.databases
        where name = '$database'
        "
        
$timestamp = get-date
Write-Output "$timestamp : Verify if db exists $database"
$result = Invoke-Sqlcmd -ServerInstance $sqlinstance -Database master -Query $sqlscript 
if ($result) {

    $asci = [char[]]([char]40..[char]95) + ([char[]]([char]97..[char]126))
    $password = (1..$(Get-Random -Minimum 20 -Maximum 40) | % { $asci | get-random }) -join ""
    $Secure_String_Pwd = ConvertTo-SecureString $password -AsPlainText -Force

    $timestamp = get-date
    Write-Output "$timestamp : Creating new databasecertificate for $customernumber"
    
    #database certificate
    $password = (1..$(Get-Random -Minimum 20 -Maximum 40) | % { $asci | get-random }) -join ""
    $Secure_String_Pwd = ConvertTo-SecureString $password -AsPlainText -Force
    New-DbaDbCertificate -SqlInstance $sqlinstance  -Database master -name tdecert_$customernumber -ExpirationDate $expdate

    $sqlscriptencrypted = "
    SELECT
        db.name,
        db.is_encrypted,
        dm.encryption_state,
        dm.percent_complete,
        dm.key_algorithm,
        dm.key_length
    FROM
        sys.databases db
        LEFT OUTER JOIN sys.dm_database_encryption_keys dm
            ON db.database_id = dm.database_id;
        
    "
    
    $result = Invoke-Sqlcmd -ServerInstance $sqlinstance -Database master -Query $sqlscriptencrypted 
    #Write-Output $result
    $encrypted = $result | where { $_.name -eq $database } | select encryption_state
    if ($encrypted.encryption_state -eq 3) {
        $timestamp = Get-date
        Write-Output "$timestamp : Database is already encrypted: $database on $sqlinstance"
        Break
    }
    
    $sqlscript = "CREATE DATABASE ENCRYPTION KEY  
    WITH ALGORITHM = AES_256  
    ENCRYPTION BY SERVER CERTIFICATE tdecert_$customernumber; 
    
    ALTER DATABASE $database 
    SET ENCRYPTION ON;"
    
    
    $timestamp = get-date
    Write-Output "$timestamp : Start encrypting database: $database on $sqlinstance"
    Invoke-Sqlcmd -ServerInstance $sqlinstance -Database $database -Query $sqlscript 
    
 
    
    $password = (1..$(Get-Random -Minimum 20 -Maximum 40) | % { $asci | get-random }) -join ""
    $sqlscript = "
    DECLARE @password VARCHAR(40) = '$password'
    select name, 'create certificate ' + QUOTENAME(name) + ' from binary = ' 
        + CONVERT(VARCHAR(MAX), CERTENCODED(CERT_ID(name)), 1)
        + ' with private key ( binary = ' 
        + CONVERT(VARCHAR(MAX), CERTPRIVATEKEY(CERT_ID(name), @password), 1)
        + ', decryption by password = ''' + @password + ''')' as certsql
    FROM sys.[certificates] AS [c]
    WHERE name = 'tdecert_${customernumber}';
    "
    
    #$sqlscript
    
    $timestamp = get-date
    Write-Output "$timestamp : Read cert from source: $sqlinstance"
    $sqlresult = Invoke-Sqlcmd -ServerInstance $sqlinstance -Database master -Query $sqlscript -MaxCharLength 100000 
    $timestamp = get-date
    Write-Output "$timestamp : Create cert: $($sqlresult.name) on target: $sqlinstancetest "
    Invoke-Sqlcmd -ServerInstance $sqlinstancetest -Database master -Query $sqlresult.certsql
    $timestamp = get-date
    Write-Output "$timestamp : #save cert: $($sqlresult.name) as backup on keyvault: $KeyVaultKeyName with secretname: ${customernumber}-tdecert"
    $Secure_cert = ConvertTo-SecureString $sqlresult.certsql -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $KeyVaultKeyName -Name ${customernumber}-tdecert -SecretValue $Secure_cert
    $timestamp = get-date
    $shortcert = ($sqlresult.certsql).Substring(0, 100)
    Write-Output "$timestamp : Saved cert to keyvault: $shortcert.........."
    
    
   
}


if ($sqlscript) { try { Remove-Variable -Name sqlscript -Scope Global -Force } catch { } }
if ($sqlresult) { try { Remove-Variable -Name sqlresult -Scope Global -Force } catch { } }
if ($password) { try { Remove-Variable -Name password -Scope Global -Force } catch { } }
if ($shortcert) { try { Remove-Variable -Name shortcert -Scope Global -Force } catch { } }
if ($result) { try { Remove-Variable -Name result -Scope Global -Force } catch { } }
if ($Secure_cert) { try { Remove-Variable -Name Secure_cert -Scope Global -Force } catch { } }


$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)

Write-Host -f Green "** SCRIPT COMPLETED in $totalTime**"