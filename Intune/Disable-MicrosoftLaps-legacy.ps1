#Disable legacy Microsoft Laps emulation mode
# https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-scenarios-legacy#disabling-legacy-microsoft-laps-emulation-mode
New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\ -name Config -force

New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config -Name BackupDirectory  -Value 0  -force