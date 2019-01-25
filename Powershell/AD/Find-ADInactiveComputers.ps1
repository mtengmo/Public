#requires -version 2
<#
.SYNOPSIS
  Find and manage inactive Active Directory computer objects.
.DESCRIPTION
  This script allows you to specify the criteria required to identify inactive computer objects within your AD environment. This script also allows
  for the management of found computers. Management of computer objects includes one or more of the following options:
    - Reporting
    - Disabling computer objects
    - Deleting computer objects
.PARAMETER SearchScope
  Optional. Determines the search scope of what type of computer object you would like to include in the inactive computers search. Options available are:
   - All                        : Default option. All computer including never logged on computer objects.
   - OnlyInactiveComputers      : Only inactive computers. These are computers that have logged on in the past but have not logged on since DaysInactive.
   - OnlyNeverLoggedOn          : Only never logged on objects. This option excludes computers that have logged on before.
   Note: If not specified, the default search scope is All (i.e. all inactive and never logged on computer objects).
.PARAMETER DaysInactive
  Optional. The number of days a computer hasn't logged into the domain for in order to classify it as inactive. The default option is 90
  days, which means any computer that hasn't logged into the domain for 90 days or more is considered inactive and therefore managed by this
  script.
.PARAMETER ReportFilePath
  Optional. This is the location where the report of inactive computer objects will be saved to. If this parameter is not specified, the default location
  the report is saved to is C:\InactiveComputers.csv.
  Note: When specifying the file path, you MUST include the file name with the extension of .csv. Example: 'C:\MyReport.csv'.
.PARAMETER DisableObjects
  Optional. If this parameter is specified, this script will disable the inactive computer objects found based on the search scope specified.
  Note: If this parameter is not specified, then by default this script WILL NOT disable any inactive computers found.
.PARAMETER DeleteObjects
  Optional. If this parameter is specified, this script will delete the inactive computer objects found based on the search scope specified.
  Note: If this parameter is not specified, then by default this script WILL NOT delete any inactive computers found.
.INPUTS
  None.
.OUTPUTS
  Report of inactive computer objects found. See ReportFilePath parameter for more information.
.NOTES
  Version:        1.0
  Author:         Luca Sturlese
  Creation Date:  16.07.2016
  Purpose/Change: Initial script development
.EXAMPLE
  Execution of script using default parameters. Default execution performs reporting of inactive AD computers only, not disabling or deleting any objects.
  By default the report is saved in C:\.
  .\Find-ADInactiveComputers.ps1
.EXAMPLE
  Reporting and disabling all inactive computer objects, except never logged on objects. Storing the report in C:\Reports.
  .\Find-ADInactiveComputers.ps1 -SeachScope OnlyInactiveComputers -ReportFilePath 'C:\Reports\DisabledComputers.csv' -DisableObjects
.EXAMPLE
  Find & delete all inactive computer objects that haven't logged in for the last 30 days. Include never logged on objects in this search.
  .\Find-ADInactiveComputers.ps1 -SeachScope All -DaysInactive 30 -DeleteObjects
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory = $false)][string][ValidateSet('All', 'OnlyInactiveComputers', 'OnlyNeverLoggedOn')]$SearchScope = 'All',
    [Parameter(Mandatory = $false)][int]$DaysInactive = 180,
    [Parameter(Mandatory = $false)][string]$ReportFilePath = 'C:\Script\Data\Inactivecomputers.csv',
    [Parameter(Mandatory = $false)][switch]$DisableObjects = $true,
    [Parameter(Mandatory = $false)][switch]$DeleteObjects = $false
    
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set TargetOU
$TargetOU = "OU=Computers Disabled,DC=Tobii,DC=intra"
$date = get-date -format yyyy-MM-dd
#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins
Import-Module ActiveDirectory

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Set Inactive Date:
$InactiveDate = (Get-Date).Adddays( - ($DaysInactive))

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Find-Objects {
    Param ()

    Begin {
        Write-Output "Finding inactive computer objects based on search scope specified [$SearchScope]..."
    }

    Process {
        Try {
            Switch ($SearchScope) {
                'All' {
                    $global:Results = Get-ADComputer -Filter { (LastLogonDate -lt $InactiveDate -or LastLogonDate -notlike "*") -and (Enabled -eq $true) -and (name -ne 'azureadssoacc') } -Properties LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName
                }

                'OnlyInactiveComputers' {
                    $global:Results = Get-ADComputer -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true -and (name -ne 'azureadssoacc')} -Properties LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName
                }

                'OnlyNeverLoggedOn' {
                    $global:Results = Get-ADComputer -Filter { LastLogonDate -notlike "*" -and Enabled -eq $true -and (name -ne 'azureadssoacc')} -Properties LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName
                }

                Default {
                    Write-Output -BackgroundColor Red "Error: An unknown error occcurred. Can't determine search scope. Exiting."
                    Break
                }
            }
        }

        Catch {
            Write-Output -BackgroundColor Red "Error: $($_.Exception)"
            Break
        }

        End {
            If ($?) {
                Write-Output 'Completed Successfully.'
                Write-Output ' '
            }
        }
    }
}

Function Create-Report {
    Param ()

    Begin {
        Write-Output "Creating report of inactive computers in specified path [$ReportFilePath]..."
    }

    Process {
        Try {
            #Check file path to ensure correct
            If ($ReportFilePath -notlike '*.csv') {
                $ReportFilePath = Join-Path -Path $ReportFilePath -ChildPath '\InactiveComputers.csv'
            }
            Write-Output "Inactive accounts to be disabled: $global:Results"

            # Create CSV report
            $global:Results | Export-Csv $ReportFilePath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        }

        Catch {
            Write-Output -BackgroundColor Red "Error: $($_.Exception)"
            Break
        }
    }

    End {
        If ($?) {
            Write-Output 'Completed Successfully.'
            Write-Output ' '
        }
    }
}

Function Disable-Objects {
    Param ()

    Begin {
        Write-Output 'Disabling inactive computers...'
    }

    Process {
        Try {
            ForEach ($Item in $global:Results) {
                Write-Output "$($Item.Name) - Disabled and moved to $TargetOU"
                $description = ((Get-adcomputer $Item.DistinguishedName -Properties description).description + "|disabled by script:" + $date)
                Set-ADComputer -Identity $Item.DistinguishedName -Enabled $false -Description $description 
                Move-ADObject -Identity $Item.DistinguishedName -TargetPath $TargetOU
         
        
            }
        }

        Catch {
            Write-Output "Error: $($_.Exception)" -BackgroundColor Red
            Break
        }
    }

    End {
        If ($?) {
            Write-Output 'Completed Successfully.'
            Write-Output ' '
        }
    }
}

Function Delete-Objects {
    Param ()

    Begin {
        Write-Output 'Deleting inactive computers...'
    }

    Process {
        Try {
            ForEach ($Item in $global:Results) {
                Remove-ADComputer -Identity $Item.DistinguishedName -Confirm:$false
                Write-Output "$($Item.Name) - Deleted"
            }
        }

        Catch {
            Write-Output -BackgroundColor Red "Error: $($_.Exception)"
            Break
        }
    }

    End {
        If ($?) {
            Write-Output 'Completed Successfully.'
            Write-Output ' '
        }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Output "I´m: $env:UserName" 
Find-Objects
Create-Report

If ($DisableObjects) {
    Write-Output "Running func Disable-Objects"
    #Disable-Objects
}

If ($DeleteObjects) {
    #Delete-Objects
}
