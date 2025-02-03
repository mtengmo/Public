<#
.SYNOPSIS
    This script sets the timezone for a user's mailbox in Exchange Online based on their location.

.DESCRIPTION
    The script connects to Exchange Online using a managed identity and sets the timezone for a user's mailbox.
    It uses a predefined hashtable to map states in the United States to their respective timezones.
    The script requires the user's principal name (UPN) and optionally the organization name.

.PARAMETER organization
    The organization name in Exchange Online. Defaults to "tbdvox.onmicrosoft.com".

.EXAMPLE
    .\Onboard-Exchange-SetTimezone.ps1

    This example connects to Exchange Online and sets the timezone for the user with the UPN "user@example.com".

.NOTES
    Author: Magnus Tengmo
    Date: 2024-12-10
    Version 1.0
    Version 1.1 - added days parameter.
    Version 1.2 - added timezone for calendar
    
#>

param (
    [parameter(Mandatory = $false)][String] $organization = "tbdvox.onmicrosoft.com",
    [int]$days = -1
)

$starttimestamp = get-date

Write-output "$starttimestamp : Connecting ExchangeOnline"
try {
    Import-Module exchangeonlinemanagement
    Connect-ExchangeOnline -ManagedIdentity -Organization $organization -ErrorAction Stop
}
catch {
    Write-Output $error
}
#bug get mailbox: https://support.microsoft.com/en-us/help/4493553/could-not-find-database-error-for-multi-region-cmdlets

# Define a hashtable for timezones based on country and state
$timezones = @{
    "United States"  = @{
        "Wisconsin"      = "Central Standard Time"
        "Pennsylvania"   = "Eastern Standard Time"
        "Georgia"        = "Eastern Standard Time"
        "New York"       = "Eastern Standard Time"
        "Texas"          = "Central Standard Time"
        "Illinois"       = "Central Standard Time"
        "Idaho"          = "Mountain Standard Time"
        "Kentucky"       = "Eastern Standard Time"
        "Florida"        = "Eastern Standard Time"
        "Tennessee"      = "Central Standard Time"
        "Washington"     = "Pacific Standard Time"
        "Michigan"       = "Eastern Standard Time"
        "New Jersey"     = "Eastern Standard Time"
        "California"     = "Pacific Standard Time"
        "Colorado"       = "Mountain Standard Time"
        "Minnesota"      = "Central Standard Time"
        "North Carolina" = "Eastern Standard Time"
        "Ohio"           = "Eastern Standard Time"
        "Oklahoma"       = "Central Standard Time"
        "Massachusetts"  = "Eastern Standard Time"
        "Connecticut"    = "Eastern Standard Time"
        "Utah"           = "Mountain Standard Time"
        "Nebraska"       = "Central Standard Time"
        "Maryland"       = "Eastern Standard Time"
        "Virginia"       = "Eastern Standard Time"
        "Arkansas"       = "Central Standard Time"
        "Oregon"         = "Pacific Standard Time"
        "Kansas"         = "Central Standard Time"
        "Arizona"        = "Mountain Standard Time"
        "Indiana"        = "Eastern Standard Time"
        "Missouri"       = "Central Standard Time"
        "Louisiana"      = "Central Standard Time"
        "North Dakota"   = "Central Standard Time"
        "Nevada"         = "Pacific Standard Time"
        "Alabama"        = "Central Standard Time"
        "South Carolina" = "Eastern Standard Time"
        "New Hampshire"  = "Eastern Standard Time"
        "West Virginia"  = "Eastern Standard Time"
        "Mississippi"    = "Central Standard Time"
        "Montana"        = "Mountain Standard Time"
        "Iowa"           = "Central Standard Time"
        "Hawaii"         = "Hawaiian Standard Time"
        "Rhode Island"   = "Eastern Standard Time"
    }
    "Canada"         = @{
        "Ontario" = "Eastern Standard Time"
    }
 
    "China"          = @{
        "Jiangsu"  = "China Standard Time"
        "Shanghai" = "China Standard Time"
    }
    
    
    "Japan"          = @{
        "Kyoto" = "Tokyo Standard Time"
    }
    "Australia"      = @{
        "South Australia" = "AUS Central Standard Time"
    }
    "New Zealand"    = @{
        "Auckland" = "New Zealand Standard Time"
    }
    "United Kingdom" = "GMT Standard Time"
    "France"         = "W. Europe standard Time"
    "Chile"          = "Chile Standard Time"
    "Denmark"        = "W. Europe standard Time"
    "Spain"          = "W. Europe standard Time"
    "Romania"        = "E. Europe standard Time"
    "Ireland"        = "GMT Standard Time"
    "Norway"         = "W. Europe standard Time"
    "Germany"        = "W. Europe standard Time"
    "Belgium"        = "W. Europe standard Time"
    "Italy"          = "W. Europe standard Time"
    "Sweden"         = "W. Europe standard Time"
    "Finland"        = "E. Europe standard Time"
    "Switzerland"    = "W. Europe standard Time"
    "Portugal"       = "GMT Standard Time"
    "Poland"         = "W. Europe standard Time"
    "Netherlands"    = "W. Europe standard Time"
 
}

$timestamp = get-date
$lastDay = $timestamp.adddays($days)
# Get all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited | where { $_.WhenCreated -ge $lastday } 
Write-output "$timestamp : Found $($mailboxes.Count) mailboxes created in the last $lastday day(s)"

foreach ($mailbox in $mailboxes) {
    $timestamp = get-date
    $user = Get-User -Identity $mailbox
    $country = $user.CountryOrRegion
    $state = $user.StateOrProvince
    $currentTimezone = (Get-MailboxRegionalConfiguration -Identity $mailbox).TimeZone

    if (!$currentTimezone -and $country -and $user.RecipientTypeDetails -eq "UserMailbox") {
        if ($timezones.ContainsKey($country)) {
            if ($timezones[$country] -is [hashtable] -and $timezones[$country].ContainsKey($state)) {
                $timezone = $timezones[$country][$state]
                Set-MailboxRegionalConfiguration -Identity $mailbox.UserPrincipalName -TimeZone $timezone 
                Write-Output "$timestamp : Set timezone for $($mailbox.UserPrincipalName) to $timezone"
            }
            elseif ($timezones[$country] -isnot [hashtable]) {
                $timezone = $timezones[$country]
                Set-MailboxRegionalConfiguration -Identity $mailbox.UserPrincipalName -TimeZone $timezone 
                Write-Output "$timestamp : Set timezone for $($mailbox.UserPrincipalName) to $timezone"
            }
            else {
                Write-Output "$timestamp : No timezone mapping found for $($mailbox.UserPrincipalName) with country $country and state $state"
            }
        }
        else {
            Write-Output "$timestamp : No timezone mapping found for $($mailbox.UserPrincipalName) with country $country"
        }
    }
    else {
        Write-Output "$timestamp : Timezone already set for $($mailbox.UserPrincipalName) : debug $currentTimezone, $country, $state, $($user.RecipientTypeDetails)"
    }
    Remove-Variable -name User -ErrorAction SilentlyContinue
    Remove-Variable -name Country -ErrorAction SilentlyContinue
    Remove-Variable -name State -ErrorAction SilentlyContinue
    Remove-Variable -name currentTimezone -ErrorAction SilentlyContinue
    Remove-Variable -name timezone -ErrorAction SilentlyContinue


}

foreach ($mailbox in $mailboxes) {
    $timestamp = get-date
    $user = Get-User -Identity $mailbox
    $country = $user.CountryOrRegion
    $state = $user.StateOrProvince
    $currentTimezone = (Get-MailboxCalendarConfiguration -Identity $mailbox).WorkingHoursTimeZone

    if (!$currentTimezone -and $country -and $user.RecipientTypeDetails -eq "UserMailbox") {
        if ($timezones.ContainsKey($country)) {
            if ($timezones[$country] -is [hashtable] -and $timezones[$country].ContainsKey($state)) {
                $timezone = $timezones[$country][$state]
                Set-MailboxCalendarConfiguration -Identity $mailbox.UserPrincipalName -WorkingHoursTimeZone $timezone 
                Write-Output "$timestamp : Set timezone for $($mailbox.UserPrincipalName) to $timezone"
            }
            elseif ($timezones[$country] -isnot [hashtable]) {
                $timezone = $timezones[$country]
                Set-MailboxCalendarConfiguration -Identity $mailbox.UserPrincipalName -WorkingHoursTimeZone $timezone 
                Write-Output "$timestamp : Set calendar timezone for $($mailbox.UserPrincipalName) to $timezone"
            }
            else {
                Write-Output "$timestamp : No calendar timezone mapping found for $($mailbox.UserPrincipalName) with country $country and state $state"
            }
        }
        else {
            Write-Output "$timestamp : No calendar timezone mapping found for $($mailbox.UserPrincipalName) with country $country"
        }
    }
    else {
        Write-Output "$timestamp : Calendar Timezone already set for $($mailbox.UserPrincipalName) : debug $currentTimezone, $country, $state, $($user.RecipientTypeDetails)"
    }
    Remove-Variable -name User -ErrorAction SilentlyContinue
    Remove-Variable -name Country -ErrorAction SilentlyContinue
    Remove-Variable -name State -ErrorAction SilentlyContinue
    Remove-Variable -name currentTimezone -ErrorAction SilentlyContinue
    Remove-Variable -name timezone -ErrorAction SilentlyContinue


}



# Disconnect from Exchange Online
Write-Output "$timestamp : Disconnecting ExchangeOnline, Runtime: $((Get-Date) - $starttimestamp)"

Disconnect-ExchangeOnline -Confirm:$false