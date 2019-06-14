            


#####################################################################
#
# Skapat av Conny Z.
# Ändrad av Magnus T
#
##################################################################### 
# Informartionen i CSV-filen importeras till skriptet. 
# Skriptet tittar sedan om gruppen som ska skapas redan existerar.
# Finns inte gruppen så skapads den.
##################################################################### 

################# Ändra endast dessa #############################
#Filnamn för logg-filen. Döp till samma som skript namnet.
$filename = "create_sql_groups"

#OU sökvägen som används för att ta spara ner info till csv-filen.
$BaseOU = "OU=Kunder,DC=domain,DC=local"
##################################################################

#Variabeln nedan gör så att alla sökvägar sätts till samma katalog som där skriptet exekveras ifrån.
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#Variablen pekar ut loggkatalogen som ska finnas i skriptkatalogen. Om loggkatalogen inte finns så skapas den.
$logdir = Join-Path $scriptDir "Logs"
# Skapar loggkatalogen om den inte finns 
if (-not (Test-Path $logdir)) {   
    New-Item $logdir -type directory
}

#Variablen pekar ut csv katalogen där csv-filen finns. Katalogen ska finnas i skriptkatalogen.
$csvdir = Join-Path $scriptDir ""


#Transcript
#Används för loggning av vad som sker efter att skriptet har exekverats.
#Fungerar inte i ISE gränssnittet. Mao fungerar inte loggningen om du testar skriptet i ISE. Transcript fungerar endast från powershell consolen.
#Loggfilen som skapas nedan (temporary.log) är temporär. Den tas bort i slutet av skriptet & ersätts av en annan loggfil (med datum & klockslag) för att radbrytningar ska bli ok.
Start-Transcript -LiteralPath "$logdir\temporary.log"
Write-Host "Transcript-loggen ""$logdir\temporary.log"" är temporär & tas bort i slutet av skriptet."
Write-Host

Import-Module ActiveDirectory


#Importerar info från CSV-fil till skriptet
$csv = @()
$csv = Import-Csv -Path "$csvdir\exportsqlgroups.csv"

#Loopar igenom alla objekt i CSV-filen
ForEach ($item In $csv) {

    #Skapar variabel med OU-sökväg till Groups OU't under respektive Kund OU
    $GroupsOUPath = "OU=Groups - Unused,OU=Groups,OU=$($item.customernumber),$BaseOU"
  
    #Skapar variabel som tittar ifall gruppen redan finns
    $checkGroup = Get-ADGroup -Filter "Name -eq '$($item.groupname)'"

    #Om gruppen finns görs följande.
    if ($checkGroup -ne $null) {            
        #Skriver om beskrivningen för gruppen.
        Set-ADGroup -Identity "$checkGroup.DistinguishedName" -Description $item.description
        Write-Host "Gruppen "$item.groupname" finns redan. Skriptet Går vidare."
    }
    #Om gruppen INTE finns görs följande
    else {
        #Skapar variabel som skapar en ny grupp
        New-ADGroup -Name $($item.groupname) -GroupScope Global -Description $item.description -Path $GroupsOUPath
        Set-ADGroup -identity $item.groupname  -add @{info = 'SQLAutocreated_Do_Not_Remove_text' }      
        Write-Host "Gruppen "$item.groupname" skapades."
    }

}
Write-Host
Stop-Transcript

#Tar upp den temporära loggfilen & sparar om den så att den blir läsbar & får radbrytningar. Sparas om med nytt namn & med datum & klockslag i filnamnet.
$a = Get-Content "$logdir\temporary.log"
$a > "$logdir\$filename-$(Get-Date -format 'dd MMM yyyy, kl.HH.mm.ss').log"

#Tar bort den temporära loggfilen.
Remove-Item "$logdir\temporary.log"
Write-Host
Write-Host """$logdir\temporary.log"" togs bort & ersattes av ny loggfil."