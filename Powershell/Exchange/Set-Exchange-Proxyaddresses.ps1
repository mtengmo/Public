# update proxyaddress based on preferred and legal name from AD attributes
# the runbook is schedule to run every 24h and as soon as a new hire is detected in AD. 
param(
    [int]$days = -30 #days back for new hires
) 


       

function Remove-StringLatinCharacter {
    <#
.SYNOPSIS
    Function to remove diacritics from a string
.PARAMETER String
	Specifies the String that will be processed
.EXAMPLE
    Remove-StringLatinCharacter -String "L'�t� de Rapha�l"

    L'ete de Raphael
.EXAMPLE
    Foreach ($file in (Get-ChildItem c:\test\*.txt))
    {
        # Get the content of the current file and remove the diacritics
        $NewContent = Get-content $file | Remove-StringLatinCharacter

        # Overwrite the current file with the new content
        $NewContent | Set-Content $file
    }

    Remove diacritics from multiple files

.NOTES
    Francois-Xavier Cat
    lazywinadmin.com
    @lazywinadm
    github.com/lazywinadmin

    BLOG ARTICLE
        http://www.lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html

    VERSION HISTORY
        1.0.0.0 | Francois-Xavier Cat
            Initial version Based on Marcin Krzanowic code
        1.0.0.1 | Francois-Xavier Cat
            Added support for ValueFromPipeline
        1.0.0.2 | Francois-Xavier Cat
            Add Support for multiple String
            Add Error Handling
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(ValueFromPipeline = $true)]
        [System.String[]]$String
    )
    PROCESS {
        FOREACH ($StringValue in $String) {
            Write-Verbose -Message "$StringValue"

            TRY {
                [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($StringValue))
            }
            CATCH {
                Write-Error -Message $Error[0].exception.message
            }
        }
    }
}

function Remove-StringSpecialCharacter {
    <#
.SYNOPSIS
	This function will remove the special character from a string.

.DESCRIPTION
	This function will remove the special character from a string.
	I'm using Unicode Regular Expressions with the following categories
	\p{L} : any kind of letter from any language.
	\p{Nd} : a digit zero through nine in any script except ideographic 

	http://www.regular-expressions.info/unicode.html
	http://unicode.org/reports/tr18/

.PARAMETER String
	Specifies the String on which the special character will be removed

.SpecialCharacterToKeep
	Specifies the special character to keep in the output

.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "^&*@wow*(&(*&@"
	wow
.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*"

	wow
.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*" -SpecialCharacterToKeep "*","_","-"
	wow-_*

.NOTES
	Francois-Xavier Cat
	@lazywinadm
	www.lazywinadmin.com
	github.com/lazywinadmin
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Text')]
        [System.String[]]$String,

        [Alias("Keep")]
        #[ValidateNotNullOrEmpty()]
        [String[]]$SpecialCharacterToKeep
    )
    PROCESS {
        IF ($PSBoundParameters["SpecialCharacterToKeep"]) {
            $Regex = "[^\p{L}\p{Nd}"
            Foreach ($Character in $SpecialCharacterToKeep) {
                IF ($Character -eq "-") {
                    $Regex += "-"
                }
                else {
                    $Regex += [Regex]::Escape($Character)
                }
                #$Regex += "/$character"
            }

            $Regex += "]+"
        } #IF($PSBoundParameters["SpecialCharacterToKeep"])
        ELSE { $Regex = "[^\p{L}\p{Nd}]+" }

        FOREACH ($Str in $string) {
            Write-Verbose -Message "Original String: $Str"
            $Str -replace $regex, ""
        }
    } #PROCESS
}

 

$timestamp = Get-date
$searchbase = "OU=Locations,DC=domain,DC=com"
$users = get-aduser -filter { enabled -eq $true -and  company -like "*" -and  extensionattribute4 -like "*" } -properties company, extensionattribute4, extensionAttribute5, extensionattribute6, extensionattribute10, extensionattribute11, ProxyAddresses, mail, mailnickname, Givenname, sn, displayname,whenCreated -SearchBase $searchbase

#$users = get-aduser mros -properties extensionattribute4, extensionAttribute5, extensionattribute6, ProxyAddresses, mail, mailnickname, Givenname, sn  , msDS-cloudExtensionAttribute1, msDS-cloudExtensionAttribute2

Write-output "$timestamp : Found $($users.count) users"
$format = "yyyyMMddHHmmss.0Z"
#20090608010000.0Z
$maildomainlookup = @{
 
    "4620"           = "company1.com"
    "4421"           = "company1.com"
    "1021"           = "company1.com"
    "8620"           = "company1.com"
    "NORWAY"         = "company1.com"
    "Trading Suzhou" = "company1.com"
    "4520"           = "company1.com"
    "4920"           = "company1.com"
    "1025"           = "company1.com"
    "3530"           = "company1.com"
    "3240"           = "teams.company2.com"
    "3340"           = "teams.company2.com"
    "4640"           = "teams.company2.com"
    "1027"           = "company4.com"
    "4940"           = "company4.com"
    "6120"           = "company3.com"
    "6420"           = "company3.co.nz"

}
$i = 0
$j = 0
$o = 0


#[datetime]$datesearch = "2023-11-15" #30 days before Workday went live
$datesearch = (Get-Date).AddDays($days)

foreach ($user in $users) {
   
    $StatusHireDate_raw = $user.extensionattribute4  #hire date from Wday

    $timestamp = get-date
    #search only for new hires
    #$StatusHireDate = [System.DateTime]::ParseExact($StatusHireDate_raw, $format, [System.Globalization.CultureInfo]::InvariantCulture)
    $StatusHireDate = $user.whenCreated #changed to ad user creating because of different position in Wday


    if ($statushiredate -gt $datesearch) {
    #    Write-Output "$timestamp : Start looping $($user.SamAccountName) with  legal company:$($user.extensionattribute10)."
        $extensionattribute6 = $user.extensionattribute6 
        $extensionattribute10 = $user.extensionattribute10 # legal company
        try {
            $maildomain = $maildomainlookup[$extensionattribute10]
        }
        catch {
            $maildomain = "company1.com"
            Write-Output "$timestamp : Didn´t find maildomain based in legal company $extensionattribute10"
        }
  
        if ($user.extensionattribute11 -eq "1274_Board Member" ) {
            $maildomain = "company5.com"

        }
        $samaccountname = $user.samaccountname
 
        $displayname = $user.displayname
        $maildisplayname = Remove-StringLatinCharacter($displayname).ToLower()  #remove åäö and to lower
        $maildisplayname = $maildisplayname -replace '[^a-zA-Z0-9\s]', ''  #remove special characters except space
        $maildisplayname = $maildisplayname.Replace(" ", ".")  #change space to dot
     

        $newPrimarySMTP = "SMTP:" + $maildisplayname + "@" + $maildomain
        $newPrimaryemail = $maildisplayname + "@" + $maildomain
   
        
        $o++
        if ($user.proxyaddresses) {
            #if already have proxyaddresses
            $ADPrimarySMTP = $user.proxyaddresses | where { $_ -clike 'SMTP:*' } 


            if ($ADPrimarySMTP -ne $newPrimarySMTP) {
                $oldADPrimarySMTP = $ADPrimarySMTP.ToLower() #making it an alias
                Write-Output "$timestamp : **** Need to update ****  samaccountname $samaccountname  primary smtp with $newPrimarySMTP old value: $ADPrimarySMTP, new alias: $oldADPrimarySMTP, belongs to company $extensionattribute10 $($user.company)"
                Set-ADUser -Identity $SamAccountName -remove @{ProxyAddresses = $ADPrimarySMTP }   
                Set-ADuser -Identity $SamAccountName  -add @{ProxyAddresses = "$newPrimarySMTP" }  
                Set-ADuser -Identity $SamAccountName  -add @{ProxyAddresses = "$oldADPrimarySMTP" }  
                Set-ADuser -Identity $samaccountname  -replace @{mail = "$newPrimaryemail" }  
                Set-ADuser -Identity $samaccountname  -replace @{mailnickname = "$samaccountname" }    # needed for msexchange issue: https://social.msdn.microsoft.com/Forums/SqlServer/en-US/081d3259-57b1-44ab-a8d0-5334b83d2938/azure-ad-connect-doesnt-sync-msexchhidefromaddresslists?forum=WindowsAzureAD
                $j++
            }
            else {
                Write-Output "$timestamp : No need to update $samaccountname primary smtp with $newPrimarySMTP old value: $ADPrimarySMTP are equal"

            }
 
        }
        else {
            Write-Output "$timestamp : **** No proxyaddresses ****, need to generate new one for samaccountname $samaccountname newPrimarySmtp $newPrimarySMTP  "# $newLegalAliasSMTP"
            $i++
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "$newPrimarySMTP" }   -Verbose  
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "smtp:$samaccountname@domain.com" }    
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "smtp:$samaccountname@domain.onmicrosoft.com" }     
            Set-ADuser -Identity $samaccountname  -add @{mail = "$newPrimaryemail" }  
            Set-ADuser -Identity $samaccountname  -replace @{mailnickname = "$samaccountname" }      # needed for msexchange issue: https://social.msdn.microsoft.com/Forums/SqlServer/en-US/081d3259-57b1-44ab-a8d0-5334b83d2938/azure-ad-connect-doesnt-sync-msexchhidefromaddresslists?forum=WindowsAzureAD
            Write-Output "$timestamp : **** Updated proxyaddresses ****** for $samaccountname"

        }
  
    }
    Remove-Variable -name mailnickname -ErrorAction SilentlyContinue
    Remove-Variable -name newPrimarySMTP -ErrorAction SilentlyContinue
    Remove-Variable -name newLegalAliasSMTP -ErrorAction SilentlyContinue
    Remove-Variable -name oldADPrimarySMTP -ErrorAction SilentlyContinue
    Remove-Variable -name extensionattribute6 -ErrorAction SilentlyContinue
    Remove-Variable -name extensionattribute10 -ErrorAction SilentlyContinue
    Remove-Variable -name maildisplayname -ErrorAction SilentlyContinue
    Remove-Variable -name displayname -ErrorAction SilentlyContinue
    Remove-Variable -name maildomain -ErrorAction SilentlyContinue
    

    
    
    
}

#start AAD sync
if (($i -gt 0) -or ($j -gt 0)) {
    Start-ADSyncSyncCycle -PolicyType delta
}
Write-Output "$timestamp : $i new AD user(s) updated, Newly hired $o,  $j updated with perferred name"