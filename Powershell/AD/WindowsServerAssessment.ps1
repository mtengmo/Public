$servers =Get-ADComputer -SearchBase "OU=US,OU=Domain Servers,DC=domain,DC=local" -Filter {Enabled -eq $true -and OperatingSystem -like 'Windows Server 2012*' } -Properties OperatingSystem
$serverlist = $servers.name -join ";"

Add-WindowsServerAssessmentTask -ServerName $serverlist -WorkingDirectory C:\oms\WindowsServer\ -RunWithManagedServiceAccount $true -ScheduledTaskUsername svc-omsas-01$


