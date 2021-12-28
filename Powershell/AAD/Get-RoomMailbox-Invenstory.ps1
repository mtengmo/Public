# Modules, MSAL, ExchangeOnline, AzureAD, JWTDetails
# Thanks to Morgan:https://morgantechspace.com/2021/09/export-teams-and-outlook-calendar-events-using-powershell.html
# Darren: https://blog.darrenjrobinson.com/microsoft-graph-using-msal-with-powershell/
# 
#Provide your Office 365 Tenant Id or Tenant Domain Name
$tenantID = "xxxx"
$clientID = "8a8cda4c-97c1-40d9-9615-e9018f76e035"

$clientsecretplain = "xxxx" 
$clientSecret = (ConvertTo-SecureString $clientsecretplain -AsPlainText -Force )

$daysafter = 90
$daysbefore = -90

Import-Module MSAL.PS
#$myAccessToken = Get-MsalToken -DeviceCode -ClientId $clientID -TenantId $tenantID -RedirectUri "https://localhost"
$myAccessToken = Get-MsalToken -ClientId $clientID -TenantId $tenantID -ClientSecret $clientSecret  
$myAccessToken.AccessToken | Get-JWTDetails

#AzureAD
try {
    $tenant_details = Get-AzureADTenantDetail
}
catch {
    throw "You must call Connect-AzureAD before running this script."
}
Write-Host ("TenantId: {0}, InitialDomain: {1}" -f `
        $tenant_details.ObjectId, `
    ($tenant_details.VerifiedDomains | Where-Object { $_.Initial }).Name)
                
#Connect & Login to ExchangeOnline (MFA)
$getsessions = Get-PSSession | Select-Object -Property State, Name
$isconnected = (@($getsessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
If ($isconnected -ne "True") {
    Connect-ExchangeOnline
}

function Get-LastCalendarEvent {
    param(
        [Parameter(Mandatory = $true)]
        [String] $myAccessToken,
        [Parameter(Mandatory = $true)]
        [String] $tenantID,
        [Parameter(Mandatory = $true)]
        [String] $userId,
        [Parameter(Mandatory = $true)]
        [int] $daysbefore,
        [Parameter(Mandatory = $true)]
        [int] $daysafter
    )

    #Form request headers with the acquired $accessToken
    $headers = @{'Content-Type' = "application\json"; 'Authorization' = "Bearer $myAccessToken" }
 
    #Set a time zone in header to get date time values returned in the specific time zone
    #$TimeZone=(Get-TimeZone).Id #Get current time zone
    $TimeZone = "Europe/Berlin"
    $headers.Add('Prefer', 'outlook.timezone="' + $TimeZone + '"')
 
    #This request get all future, current and old events
    #$apiUrl = "https://graph.microsoft.com/v1.0/users/$userId/calendar/events"
 
    #We need to apply filter with meeting start time to get only upcoming events.
    #Filter - the below query returns events for next 90 days
    #$startDate = (Get-Date (Get-Date).Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z')
    $startDate = (Get-Date (Get-Date).AddDays($daysbefore).Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z')
    $endDate = (Get-Date (Get-Date).AddDays($daysafter).Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z')
    $apiUrl = "https://graph.microsoft.com/v1.0/users/$userId/calendar/events?`$filter=start/dateTime ge '$($startDate)' and start/dateTime lt '$($endDate)'"
    #$apiUrl = "https://graph.microsoft.com/v1.0/users/$userId/calendar/events?`$filter=start/dateTime ge '$($startDate)'"
    #$apiUrl = "https://graph.microsoft.com/v1.0/users/$userId/calendar/events?`$filter=start/dateTime ge '$($startDate)' and start/dateTime lt '$($endDate)'&`$top=1&`$orderby=lastModifiedDateTime desc"

    $Result = @()
    While ($apiUrl -ne $Null) {
    
        #write-output $apiurl
 
        $Response = Invoke-WebRequest -Method GET -Uri $apiUrl -ContentType "application\json" -Headers $headers | ConvertFrom-Json
        if ($Response.value) {
            ForEach ($event in  $Response.Value) {
                $Result += New-Object PSObject -property $([ordered]@{ 
                        Subject        = $event.subject
                        Organizer      = $event.organizer.emailAddress.name
                        Attendees      = (($event.attendees | select -expand emailAddress) | Select -expand name) -join ','
                        StartTime      = [DateTime]$event.start.dateTime
                        EndTime        = [DateTime]$event.end.dateTime
                        IsTeamsMeeting = ($event.onlineMeetingProvider -eq 'teamsForBusiness')
                        Location       = $event.location.displayName
                        IsCancelled    = $event.isCancelled
                    })
            }
        }
        $apiUrl = $Response.'@Odata.NextLink'
    }
    #Write-output $result
    $returnresult = $result.starttime  | sort $_.starttime | select  -last 1
    Return $returnresult
}

#Get-LastCalendarEvent -tenantID $tenantID -myAccessToken $($myAccessToken.AccessToken) -userId $userId -daysbefore $daysbefore -daysafter $daysafter




 
#clear-host
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

$rooms = get-user -ResultSize unlimited | where { $_.RecipientTypeDetails -eq "RoomMailbox" } 
$i = 0

foreach ($room in $rooms) {
    $i = $i + 1

    Write-Progress -Activity "Searching Mailbox rooms details" -Status "Progress:" -PercentComplete ($i / $rooms.count * 100)
    
    $timestamp = get-date
    $place = get-place -identity $room.name 
    $mailbox = get-mailbox -identity $room.name
    $calendarprocessing = Get-CalendarProcessing -Identity $room.userprincipalname
    $azureaduser = get-azureaduser -ObjectId $room.userprincipalname
    $ReportLine = [PSCustomObject] @{
        TimeStamp                     = $TimeStamp
        Identity                      = $place.Identity
        RecipientTypeDetails          = $_.RecipientTypeDetails
        DisplayName                   = $_.DisplayName
        Street                        = $place.Street
        City                          = $place.city
        State                         = $place.state
        Postalcode                    = $place.postalcode
        CountryOrRegion               = $place.CountryOrRegion
        GeoCoordinates                = $place.GeoCoordinates
        BookingType                   = $place.BookingType 
        Capacity                      = $place.Capacity
        Building                      = $place.Building
        Label                         = $place.Label
        AudioDeviceName               = $place.AudioDeviceName
        VideoDeviceName               = $place.VideoDeviceName
        Floor                         = $place.Floor
        FloorLabel                    = $place.FloorLabel
        Office                        = $mailbox.Office
        HiddenFromAddressListsEnabled = $mailbox.HiddenFromAddressListsEnabled
        StsRefreshTokensValidFrom     = $mailbox.StsRefreshTokensValidFrom
        AccountDisabled               = $mailbox.AccountDisabled
        WhenMailboxCreated            = $mailbox.WhenMailboxCreated
        LastLogonTime                 = ($mailbox | Get-MailboxStatistics).LastLogonTime
        DirSyncEnabled                = $azureaduser.DirSyncEnabled
        PasswordPolicies              = $azureaduser.PasswordPolicies
        LastCalendarEvent             = Get-LastCalendarEvent -tenantID $tenantID -myAccessToken $($myAccessToken.AccessToken) -userId $place.Identity  -daysbefore $daysbefore -daysafter $daysafter
        AutomateProcessing            = $calendarprocessing.AutomateProcessing
        AddOrganizerToSubject         = $calendarprocessing.AddOrganizerToSubject
        DeleteComments                = $calendarprocessing.DeleteComments
        DeleteSubject                 = $calendarprocessing.DeleteSubject
        RemovePrivateProperty         = $calendarprocessing.RemovePrivateProperty
        AddAdditionalResponse         = $calendarprocessing.AddAdditionalResponse
        ResourceDelegates             = $calendarprocessing.ResourceDelegates
        BookInPolicy                  = $calendarprocessing.BookInPolicy
        MailTip                       = $mailbox.MailTip
        RoomMailboxAccountEnabled     = $mailbox.RoomMailboxAccountEnabled
 
 
    }        
    $Report.Add($ReportLine)
}


$report | Out-GridView

 