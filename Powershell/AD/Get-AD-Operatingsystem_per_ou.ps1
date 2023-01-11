Import-Module ActiveDirectory

$BaseOU = "OU=Locations,DC=domain,DC=intra"

$SearchOUs = (Get-ADOrganizationalUnit -filter * -SearchBase $BaseOU)

$Results = foreach ($SearchOU in $SearchOUs) {
    $Computers = (Get-ADComputer -SearchBase $SearchOU.DistinguishedName -Filter {Enabled -eq $true} -Properties OperatingSystem, OperatingSystemVersion, lastlogondate)
    foreach ($Computer in $Computers) {
        Write-Output ([PSCustomObject]@{
                ComputerName           = $Computer.Name;
                OU                     = $SearchOU.DistinguishedName;
                OperatingSystem        = $Computer.OperatingSystem;
                OperatingSystemVersion = $Computer.operatingSystemVersion -replace "(10240)", ":1507" -replace "(10586)", ":1511" -replace "(14393)", ":1607" -replace "(15063)", ":1703" -replace "(16299)", ":1709" -replace "(17134)", ":1803" -replace "(17763)", ":1809" ;
                lastlogondate          = $computer.lastlogondate
            })
    }
}
$Results | Export-CSV "c:\temp\AD_Objects_Per_OU.csv" -NoTypeInformation -delimiter ";" -encoding "UTF8"



$BaseOU = "OU=Locations,DC=domain,DC=intra"

Get-ADComputer -Filter * -SearchBase $BaseOU -Properties  OperatingSystem, OperatingSystemVersion, lastlogondate | 
    Select-Object Name, @{Name = "OrganizationalUnit"; Expression = {$_.DistinguishedName.Split(',', 2)[1]}}, OperatingSystem, @{Name = "OSversion"; Expression = {$_.OperatingSystemVersion -replace "(10240)", ":1507" -replace "(10586)", ":1511" -replace "(14393)", ":1607" -replace "(15063)", ":1703" -replace "(16299)", ":1709" -replace "(17134)", ":1803" -replace "(17763)", ":1809"}}, lastlogondate | 
    Export-CSV "c:\temp\AD_Objects_Per_OU.csv" -NoTypeInformation -delimiter ";" -encoding "UTF8"
