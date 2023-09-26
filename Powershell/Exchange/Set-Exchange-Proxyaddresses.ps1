# update proxyaddress based on preferred and legal name from AD attributes
function Remove-StringLatinCharacter {
    <#
.SYNOPSIS
    Function to remove diacritics from a string
.PARAMETER String
	Specifies the String that will be processed
.EXAMPLE
    Remove-StringLatinCharacter -String "L'été de Raphaël"

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
$searchbase = "OU=Locations,DC=local,DC=com"
$users = get-aduser -filter { enabled -eq $true -and extensionAttribute5 -like "*" -and extensionAttribute4 -like "*" -and extensionattribute6 -like "*" } -properties extensionattribute4, extensionAttribute5, extensionattribute6, ProxyAddresses, mail, mailnickname, Givenname, sn -SearchBase $searchbase
#$users = get-aduser te1473 -properties extensionattribute4, extensionAttribute5, extensionattribute6, ProxyAddresses, mail, mailnickname, Givenname, sn  , msDS-cloudExtensionAttribute1, msDS-cloudExtensionAttribute2
Write-output "$timestamp : Found $($user.count) users"
$format = "yyyyMMddHHmmss.0Z"
#20090608010000.0Z
$maildomainlookup = @{
 
    "Company AB"              = "company1.com"
    "Company Ltd."            = "company1.com"
    "Company LLC"             = "company1.com"
    "Company (Suzhou)Co.,Ltd" = "company1.com"
    "Company AS"              = "company1.com"
    "Company Suzhou"          = "company1.com"
    "Company ApS Denmark"     = "company1.com"
    "Company GmbH"            = "company1.com"
    "Company Canada Inc."     = "company1.com"
    "Company2"                = "company2.com"
    "Company3 Belgium"        = "company3.com"
    "Company3 France"         = "company3.com"
    "Company3 Sweden"         = "company3.com"

}
$i = 0
$j = 0
$o = 0
#$maildomain = "company1.com"
$datesearch = (Get-Date).AddDays(-30)
foreach ($user in $users) {
   
    $StatusHireDate_raw = $user.extensionattribute4  #hire date from Wday

    $timestamp = get-date
    #search only for new hires
    $StatusHireDate = [System.DateTime]::ParseExact($StatusHireDate_raw, $format, [System.Globalization.CultureInfo]::InvariantCulture)
    if ($statushiredate -gt $datesearch) {
        Write-Output "$timestamp : Start looping $($user.SamAccountName) with  legal company:$($user.extensionattribute6)."
        $extensionattribute6 = $user.extensionattribute6 # legal company
        $maildomain = $maildomainlookup[$extensionattribute6]
        if ($user.extensionattribute6 -eq "Company GmbH" -and $user.extensionattribute13 -eq "xxx") {
            #acapela in Germany
            $maildomain = "company3.com"
        }
        if ($user.extensionattribute6 -eq "Company3 Belgium" -and $user.extensionattribute13 -eq "xxx") {
            #td in Brussel 
            $maildomain = "company1.com"
        }
        $legalGivenname = $user.'msDS-cloudExtensionAttribute1'  #legal givenname from Wday
        $legalsn = $user.'msDS-cloudExtensionAttribute2'  #legal surname from Wday
        $GivenName = $user.GivenName
        $sn = $user.sn
        $samaccountname = $user.samaccountname
        $EmailGiven = Remove-StringSpecialCharacter(Remove-StringLatinCharacter($user.Givenname).ToLower())
        $Emailsn = Remove-StringSpecialCharacter(Remove-StringLatinCharacter($user.sn).ToLower())
        
        if ($user.'msDS-cloudExtensionAttribute1') {
            $EmailLegalGivenname = Remove-StringSpecialCharacter(Remove-StringLatinCharacter($user.'msDS-cloudExtensionAttribute1').ToLower())
        }
        if ($user.'msDS-cloudExtensionAttribute2') {
            $EmailLegalsn = Remove-StringSpecialCharacter(Remove-StringLatinCharacter($user.'msDS-cloudExtensionAttribute2').ToLower())
        }
        
        $newPrimarySMTP = "SMTP:" + $EmailGiven + "." + $Emailsn + "@" + $maildomain
        $newPrimaryemail = $EmailGiven + "." + $Emailsn + "@" + $maildomain
        $newLegalAliasSMTP = "smtp:" + $EmailLegalGivenname + "." + $EmailLegalsn + "@" + $maildomain
        $newLegalAlias = $EmailLegalGivenname + "." + $EmailLegalsn + "@" + $maildomain
    

        
        $o++
        if ($user.proxyaddresses) {
            #if already have proxyaddresses
            $ADPrimarySMTP = $user.proxyaddresses | where { $_ -clike 'SMTP:*' } 


            if ($ADPrimarySMTP -ne $newPrimarySMTP) {
                $oldADPrimarySMTP = $ADPrimarySMTP.ToLower() #making it an alias
                Write-Output "$timestamp : Need to update primary smtp with $newPrimarySMTP old value: $ADPrimarySMTP, new alias: $oldADPrimarySMTP, belongs to company $extensionattribute6"
                Set-ADUser $SamAccountName -Remove @{ProxyAddresses = $ADPrimarySMTP }   -WhatIf
                Set-ADuser -Identity $SamAccountName  -add @{ProxyAddresses = "$newPrimarySMTP" }  -WhatIf
                Set-ADuser -Identity $SamAccountName  -add @{ProxyAddresses = "$oldADPrimarySMTP" }  -WhatIf
                Set-ADuser -Identity $samaccountname  -replace @{mail = "$newPrimaryemail" }  -WhatIf
                Set-ADuser -Identity $samaccountname  -replace @{mailnickname = "$samaccountname" }  -WhatIf  # needed for msexchange issue: https://social.msdn.microsoft.com/Forums/SqlServer/en-US/081d3259-57b1-44ab-a8d0-5334b83d2938/azure-ad-connect-doesnt-sync-msexchhidefromaddresslists?forum=WindowsAzureAD
                $j++
            }
            else {
                Write-Output "$timestamp : No need to update primary smtp with $newPrimarySMTP old value: $ADPrimarySMTP are equal"

            }
 
        }
        else {
            Write-Output "$timestamp : No proxyaddresses, need to generate new one: $newPrimarySMTP $newLegalAliasSMTP"
            $i++
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "$newPrimarySMTP" }   -WhatIf 
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "smtp:$newLegalAliasSMTP" }  -WhatIf
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "smtp:$samaccountname@tbdvox.com" }    -WhatIf
            Set-ADuser -Identity $samaccountname  -add @{ProxyAddresses = "smtp:$samaccountname@tbdvox.onmicrosoft.com" }   -WhatIf  
            Set-ADuser -Identity $samaccountname  -add @{mail = "$newPrimaryemail" }  -WhatIf
            Set-ADuser -Identity $samaccountname  -add @{mailnickname = "$samaccountname" }    -WhatIf  # needed for msexchange issue: https://social.msdn.microsoft.com/Forums/SqlServer/en-US/081d3259-57b1-44ab-a8d0-5334b83d2938/azure-ad-connect-doesnt-sync-msexchhidefromaddresslists?forum=WindowsAzureAD
            Write-Output "$timestamp : Updated proxyaddresses for $samaccountname"

        }
  
    }

}

Write-Output "$timestamp : $i AD users, Newly hired $o,  $j updated with perferred name"