#array to store each employee
#requires -modules ActiveDirectory, Az.Keyvault
<# 
    .SYNOPSIS 
        This Azure Automation runbook update ad users from Sage
 
    .DESCRIPTION 
        This Azure Automation runbook update ad users from Workday with Terminate last working date

    .PARAMETER 

    .EXAMPLE 
    Verison 1.0 - Production ready. Migrated to runbook
 


    .OUTPUTS 
#> 

 
param( 
    [parameter(Mandatory = $false)][String] $logfile_catch = "c:\script\adsync\HRCloud_Logfile_catch_errors.txt"    
    , [parameter(Mandatory = $false)][String] $skippedfile = "c:\script\adsync\HRCloud_adsync_log.csv"
    , [parameter(Mandatory = $false)][String] $scriptpath = "c:\script\adsync"
    , [parameter(Mandatory = $false)][String] $title = "Workday-ADSync"
    #, [parameter(Mandatory = $false)][String] $resourcegroup = "rg-automations-adintegrations-prod01"
    , [parameter(Mandatory = $false)][String] $location = "East US"
    , [parameter(Mandatory = $false)][String] $keyvaultname = "key-usea-workday-adsync"  
    , [parameter(Mandatory = $false)][String] $tenantid = "f253f952-50bd-4884-bd3b-56ba582a9e42" #azuretenantid
    , [parameter(Mandatory = $false)][String] $wday_tenant = "us"  
    , [parameter(Mandatory = $false)][String] $wday_hostname = "https://services1.wd103.myworkday.com"  #https://impl-services1.wd103.myworkday.com

    
    #, [parameter(Mandatory = $false)][String] $Applicationid = "44faed2f-5e9b-40a5-aec8-0d290707bc6e" # $applicationid = (Get-AzureADApplication -Filter "DisplayName eq 'TobiiTown-Onboarding-script'").Appid
    #, [parameter(Mandatory = $false)][String] $thumb = "BD908077B32429444AB4B7B728A2FB078A8FC048" # thumbprint for selfsigned certificate on sedirsync01 used for authenticate
    #, [parameter(Mandatory = $false)][String] $webhookuri = "https://tbdvox.webhook.office.com/webhookb2/dbb99100-b17a-45c1-93c2-12074d5e0b1c@f253f952-50bd-4884-bd3b-56ba582a9e42/IncomingWebhook/037369b7a258432bb2befb691d914df8/949cd318-4419-4a6c-a4d1-a1e64b1d8a43"
    # , $employeeurl = "https://corehr-api.hrcloud.com/v1/cloud/xEmployee?page=1&pageSize=2&filter=xEmploymentStatusLookup.xType neq 'Terminated'"
    # , [parameter(Mandatory = $false)][object] $webhookData
    # , [parameter(Mandatory = $false)][object] $terminated
) 

function WriteXmlToScreen ([xml]$xml) {
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}
Function GetLocalDC {
    # Set $ErrorActionPreference to continue so we don't see errors for the connectivity test
    $ErrorActionPreference = 'SilentlyContinue'
    
    # Get all the local domain controllers
    $LocalDCs = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()).Servers
    
    # Create an array for the potential DCs we could use
    $PotentialDCs = @()
    
    # Check connectivity to each DC
    ForEach ($LocalDC in $LocalDCs) {
        # Create a new TcpClient object
        $TCPClient = New-Object System.Net.Sockets.TCPClient
     
        # Try connecting to port 389 on the DC
        $Connect = $TCPClient.BeginConnect($LocalDC.Name, 389, $null, $null)
     
        # Wait 250ms for the connection
        $Wait = $Connect.AsyncWaitHandle.WaitOne(250, $False)                      
   
        # If the connection was succesful add this DC to the array and close the connection
        If ($TCPClient.Connected) {
            # Add the FQDN of the DC to the array
            $PotentialDCs += $LocalDC.Name
   
            # Close the TcpClient connection
            $Null = $TCPClient.Close()
        }
    }
    
    # Pick a random DC from the list of potentials
    $DC = $PotentialDCs | Get-Random
    
    # Return the DC
    Return $DC
}
function GetWDWorkerData2 {
    <#
        .Synopsis
        A function to construct and send a SOAP request to Workday to retrieve worker data from the Workday API.

        .Description
        A function to construct and send a SOAP request to Workday to retrieve worker data from the Workday API.

        .Parameter Credential
        The credentials required to access the Workday API.

        .Parameter RequestType
        The type of data you would like to retrieve. Defaults to returning all data.

        RequestType can be one of the following:

            Contact
            Employment
            Management
            Organization
            Photo

        .Parameter WorkerID
        Limit your search data to a single worker. If your request encompasses multiple workers, use the pipeline.

        By default all worker information is returned.

        .Parameter Tenant

        The tenant to query for information.

        .Example
        $cred = Get-Credential
        GetWDWorkerData  -Credential $cred -Tenant us2 -RequestType Employment

        Get contact data about all workers from the TENANT environment.

        .Notes
        Author: David Green
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [string]
        $Tenant,

        [Parameter(Mandatory)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Contact',
            'Employment',
            'Management',
            'Organization',
            'Photo'
        )]
        [string[]]
        $RequestType,

        [Parameter()]
        [ValidateScript( {
                $_ -lt 1000 -and $_ -gt 0
            })]
        [int]
        $RecordsPerPage = 750,

        [Parameter(ValueFromPipeline)]
        [string]
        $WorkerID,
        [Parameter(Mandatory)]
        [string]
        $wday_hostname
       
    )

    Process {
        $page = 0
        # Get today's date
        $currentDate = Get-Date
        $formattedcurrentDate = $currentDate.ToString("yyyy-MM-ddTHH:mm:ss.fffzzz")
        # Add two years
        $dateInTwoYears = $currentDate.AddYears(2)
        # Format it as "YYYY-MM-DD"
        $Effective_date = $dateInTwoYears.ToString("yyyy-MM-dd")

        $currentDate = Get-Date
        # Add two years
        $lastweek = $currentDate.AddDays(-7)
        # Format it as "YYYY-MM-DD"
        $Effective_date_from = $lastweek.ToString("yyyy-MM-dd")



        do {
            $page++
            $Query = @{
                Uri             = "$wday_hostname/ccx/service/$Tenant/Human_Resources/v30.2"
                Method          = 'POST'
                UseBasicParsing = $true
                Body            = @"
<?xml version="1.0" encoding="utf-8"?>
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
    <env:Header>
        <wsse:Security env:mustUnderstand="1">
            <wsse:UsernameToken>
                <wsse:Username>$($Credential.UserName)</wsse:Username>
                <wsse:Password
                    Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$($Credential.GetNetworkCredential().Password)</wsse:Password>
            </wsse:UsernameToken>
        </wsse:Security>
    </env:Header>
    <env:Body>
        <wd:Get_Workers_Request xmlns:wd="urn:com.workday/bsvc" wd:version="v30.2">
       $(if ($WorkerID) { @"
    <wd:Request_References wd:Skip_Non_Existing_Instances="true">
                <wd:Worker_Reference>
                    <wd:ID wd:type="Employee_ID">$($WorkerID)</wd:ID>
                </wd:Worker_Reference>
            </wd:Request_References>
"@ })
<wd:Request_Criteria>
<wd:Transaction_Log_Criteria_Data>
<wd:Transaction_Date_Range_Data>        
<wd:Updated_From>$Effective_date_from</wd:Updated_From>        
<wd:Updated_Through>$formattedcurrentDate</wd:Updated_Through>        

</wd:Transaction_Date_Range_Data>
</wd:Transaction_Log_Criteria_Data>
</wd:Request_Criteria>


            <wd:Response_Filter>
                <wd:Page>$($page)</wd:Page>
                <wd:Count>$($RecordsPerPage)</wd:Count>
                <wd:As_Of_Effective_Date>$Effective_date</wd:As_Of_Effective_Date> 
            </wd:Response_Filter>
       

            <wd:Response_Group>
                $(switch ($RequestType) {
                    'Contact' { "<wd:Include_Personal_Information>true</wd:Include_Personal_Information>" }
                    'Employment' { "<wd:Include_Employment_Information>true</wd:Include_Employment_Information>" }
                    'Management' { "<wd:Include_Management_Chain_Data>true</wd:Include_Management_Chain_Data>" }
                    'Organization' { "<wd:Include_Organizations>true</wd:Include_Organizations>" }
                    'Photo' { "<wd:Include_Photo>true</wd:Include_Photo>" }
                })
            </wd:Response_Group>
        </wd:Get_Workers_Request>
    </env:Body>
</env:Envelope>
"@
                ContentType     = 'text/xml; charset=utf-8'
            }
            [xml]$xmlresponse = Invoke-WebRequest @Query
            Write-Verbose -Message $Query.Uri

            if ($xmlresponse) {
                $xmlresponse
                $ResultStatus = $xmlresponse.Envelope.Body.Get_Workers_Response.Response_Results
                [int]$Records += [int]$ResultStatus.Page_Results
                Write-Verbose -Message "$Records/$($ResultStatus.Total_Results) records retrieved."
                Write-Verbose -Message "$($ResultStatus.Page_Results) records this page ($($ResultStatus.Page)/$($ResultStatus.Total_Pages))."
                $TotalPages = $ResultStatus.Total_Pages
            }
        }
        while ($page -lt $TotalPages)
    }
}

#start
$timestamp = Get-Date
$today = Get-date
Write-Output "$timestamp : Connecting and reading secret from keyvault: $keyvaultname"
$User_key = "$wday_tenant-user"
$Password_secret = "$wday_tenant-password"
# Sign in to your Azure subscription

$sub = Get-AzSubscription -ErrorAction SilentlyContinue
if (-not($sub)) {
    Connect-AzAccount
}
# If you have multiple subscriptions, set the one to use
Select-AzSubscription -SubscriptionId "94ae3ba1-0e2e-4996-9aed-cfdb24d992ae"

try {
    $User = Get-AzKeyVaultSecret -vaultName $keyvaultname -name $User_key -ErrorAction Stop -verbose -AsPlainText
    $Password = Get-AzKeyVaultSecret -vaultName $keyvaultname -name $Password_secret -ErrorAction Stop -verbose  
}
catch {
    $errorMessage = $_
    Write-Output $errorMessage

    $ErrorActionPreference = "Stop"
}

Write-Output "$timestamp : Got $user from keyvault"

$cred = New-Object PSCredential -ArgumentList ($User, ($Password.SecretValue ))

#$response =        GetWDWorkerData  -Credential $cred -Tenant us2 -RequestType Employment -WorkerID 1774
Write-Output "$timestamp : Calling tenant $wday_tenant to url $wday_hostname"

[xml]$response = GetWDWorkerData2  -Credential $cred -Tenant $wday_tenant -wday_hostname $wday_hostname -RequestType Employment # -WorkerID 1774

$dc = GetLocalDC
if (!$dc) {
    $dc = "sedc01.tbdvox.com"
}
Write-Output "$timestamp : Found DC: $dc"
$xml = $response
Write-Output "$timestamp : Got xml $xml"
# Create a namespace manager
$nsManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsManager.AddNamespace("wd", "urn:com.workday/bsvc")

# Select all <wd:Worker> elements
$workerNodes = $xml.SelectNodes("//wd:Worker", $nsManager)

# Assuming $workernodes is your XML object
# remove duplicates if two employee records, save the last one (Mikaela and Emma, moved from CWR to Employee)
$modifiedXml = $workernodes.Clone()

foreach ($group in $modifiedXml.worker_data | Group-Object worker_id | Where-Object { $_.Count -gt 1 }) {
    #$Active = $group.SelectSingleNode(".//wd:Active", $nsManager).InnerText
    #$User_ID = $group.SelectSingleNode(".//wd:User_ID", $nsManager).InnerText
    #$workerID = $group.SelectSingleNode(".//wd:Worker_ID", $nsManager).InnerText
    $name = $group.name
    # Sort by Effective_date in ascending order and keep the newest one
    $newestWorker = $group.Group | Sort-Object { [datetime]$_.Employment_data.Worker_job_data.Position_data.Effective_date } -Descending | Select-Object -First 1

    # Remove old Worker_data elements
    foreach ($worker in $group.Group) {
        if ($worker -ne $newestWorker) {
            Write-Output "Deleted $name from duplicates"

        
            $parent = $worker.ParentNode
            [void]$parent.RemoveChild($worker)
        }
    }
}


# Iterate through each <wd:Worker> element
foreach ($workerNode in $modifiedXml) {
    $timestamp = Get-date
 
    $workerID = $workerNode.SelectSingleNode(".//wd:Worker_ID", $nsManager).InnerText
    #$probationStartDate = $workerNode.SelectSingleNode(".//wd:Probation_Start_Date", $nsManager).InnerText
    $Termination_Last_Day_of_Work = $workerNode.SelectSingleNode(".//wd:Termination_Last_Day_of_Work", $nsManager).InnerText
    $Termination_Date = $workerNode.SelectSingleNode(".//wd:Termination_Date", $nsManager).InnerText
    $End_Employment_Date = $workerNode.SelectSingleNode(".//wd:End_Employment_Date", $nsManager).InnerText
    $Contract_End_Date = $workerNode.SelectSingleNode(".//wd:Contract_End_Date", $nsManager).InnerText

    $Termination_Last_Day_of_Work = $workerNode.SelectSingleNode(".//wd:Termination_Last_Day_of_Work", $nsManager).InnerText
    $Effective_date = $workerNode.SelectSingleNode(".//wd:effective_date", $nsManager).InnerText
    #$Effective_date = $workernode.worker_data.employment_data.worker_job_data.position_data.effective_date
    $User_ID = $workerNode.SelectSingleNode(".//wd:User_ID", $nsManager).InnerText
    $Active = $workerNode.SelectSingleNode(".//wd:Active", $nsManager).InnerText

    #Write-Output "$workerid , userid: $user_id effectivedate: $Effective_date : Active: $Active"
    If ($User_ID) {
        $user = get-aduser -server $dc $User_ID.Split("@")[0] -Properties AccountExpirationDate, extensionattribute6
        $adexpiredate = $user.AccountExpirationDate
        $extensionattribute6 = $user.extensionattribute6 #leavedate
        
        if ($Termination_Last_Day_of_Work -or $End_Employment_Date -or $Contract_End_Date) {
            #Write-Output "$timestamp : DEBUG - Step 1 - Looping user $workerID - Termination_Last_Day_of_Work: $Termination_Last_Day_of_Work End_Employment_Date: $End_Employment_Date Contract_End_Date: $Contract_End_Date"
    
            # Create array
            $dateArray = @()
        
            # Add all timestamps to array
            if ($Termination_Last_Day_of_Work -ne $null) {
                $dateArray += [DateTime]$Termination_Last_Day_of_Work 
            }
        
            if ($End_Employment_Date -ne $null) {
                $dateArray += [DateTime]$End_Employment_Date 
            }
        
            if ($Contract_End_Date -ne $null) {
                $dateArray += [DateTime]$Contract_End_Date 
            }
        
            # Find earlist date in array
            $earliestDate = $dateArray | Sort-Object | Select-Object -First 1
            $earliestDateAD = $earliestDate.Adddays(+1) #adding one day because AD blocks 00.00 in the morning.

     
            $earliestDate_formatted = $earliestDate.ToString("yyyyMMddHHmmss.0Z")
           
            Write-Output "Worker ID: $workerID User_ID: $User_ID Termination_Last_Day_of_Work $Termination_Last_Day_of_Work Termination_Date: $Termination_Date - earliestDate $earliestDate adexpiredate: $adexpiredate"
            if ($extensionattribute6 -or ($earliestDate -and $extensionattribute6 -ne $earliestDate_formatted)) {
                #employeeleavedatetime in format 20210901120000.0Z
                if ($earliestDate_formatted -ne $extensionattribute6) {
                    try {
                    
                        set-aduser  -server $dc   -Identity $User_ID.Split("@")[0] -replace @{ExtensionAttribute6 = $earliestDate_formatted } -ErrorAction Continue 
                        Write-output "Setting ext6: $user_id : $earliestDate_formatted"
                    }
                    catch {
                        $catcherrors += "($User_ID;$_.Exception.Message)"
                    }
                }
            
             
            }
          
                    

            #$adexpiredate = (get-aduser $User_ID.Split("@")[0] -Properties AccountExpirationDate).AccountExpirationDate
            if ($adexpiredate) { $adexpiredate_Date = $adexpiredate.ToShortDateString() }  
            $earliestDateAD_Date = $earliestDateAD.ToShortDateString()
            if (($adexpiredate_Date -ne $earliestDateAD_Date) -or ($adexpiredate -eq $null)) {
                Write-Output "$timestamp : Step 2a - Diff AD: $User_ID $adexpiredate_Date : earlstestdate: $earliestDateAD_Date"
                try {
                    write-output "$timestamp : Step 3 - EXPIRE DATE : Setting expiredate on $User_ID to AD: $earliestDateAD  (+1 day because of timezone)"
                    Set-ADAccountExpiration   -Identity $User_ID.Split("@")[0] -DateTime $earliestDateAD -ErrorAction Continue     
                }
                catch {
                    $errStore = $PSItem
                    Write-Output $errStore.Exception.Message
                    Write-Output $errStore.FullyQualifiedErrorID 
                    $catcherrors_expiredate += $User_ID  
                    #   $_.Exception.Message | Out-File $logfile_catch -Append
                    $catcherrors += "($User_ID;$_.Exception.Message)"
                }


            }
            else {
               # Write-Output "$timestamp : DEBUG - Step 2b - Equal AD: $User_ID $adexpiredate : earlstestdate: $earliestDateAD_Date"

            }

  
            # Compare earliestDate with today's date
            if ($earliestDateAD_Date -lt $today) {
                #  Write-Host "$timestamp : Step 4a - DISABLE : earliestDate is before today's date. Disable account $user_id"
     
                try { 
                    Write-Output "$timestamp - Disable account $user_id"
                   # Disable-ADAccount  -Identity $User_ID.Split("@")[0] -Verbose  -WhatIf
                }
                catch {
                    $errStore = $PSItem
                    Write-Output $errStore.Exception.Message
                    Write-Output $errStore.FullyQualifiedErrorID 
                    $catcherrors_expiredate += $User_ID  
                    #   $_.Exception.Message | Out-File $logfile_catch -Append
                    $catcherrors += "($User_ID;$_.Exception.Message)"
                }
            }
            elseif ($earliestDate -eq $today) {
                Write-Host "earliestDate is today's date. $user_id"
            }
            else {
                #    Write-Host "$timestamp : Step 4b - ENABLE : earliestDate is after today's date ($today). Enable account: $user_id"
                try { 
                    # logic not working, need to fix
                    #Write-Output "$timestamp - *** - Enable account $user_id"  
                    #Enable-ADAccount  -Identity $User_ID.Split("@")[0] -Verbose -WhatIf
                }
                catch {
                    $errStore = $PSItem
                    Write-Output $errStore.Exception.Message
                    Write-Output $errStore.FullyQualifiedErrorID 
                    $catcherrors_expiredate += $User_ID  
                    #   $_.Exception.Message | Out-File $logfile_catch -Append
                    $catcherrors += "($User_ID;$_.Exception.Message)"
                }

            }

        }
        Else {
            if ($extensionattribute6 -or $adexpiredate) { 
                set-aduser  -server $dc  -Identity $User_ID.Split("@")[0] -clear ExtensionAttribute6 -ErrorAction Continue  
                Clear-ADAccountExpiration -server $dc -Identity $User_ID.Split("@")[0]

                Write-output "**** Clearing ext6: $user_id : $earliestDate_formatted"  
            }
        }
    }
    # Output the results for each worker
    Remove-Variable -name workerID  -ErrorAction SilentlyContinue
    Remove-Variable -name User_ID  -ErrorAction SilentlyContinue
    Remove-Variable -name Termination_Last_Day_of_Work_AD  -ErrorAction SilentlyContinue
    Remove-Variable -name Termination_Last_Day_of_Work  -ErrorAction SilentlyContinue
    Remove-Variable -name Termination_Date  -ErrorAction SilentlyContinue
    Remove-Variable -name End_Employment_Date  -ErrorAction SilentlyContinue
    Remove-Variable -name Contract_End_Date  -ErrorAction SilentlyContinue
    Remove-Variable -name earliestDate  -ErrorAction SilentlyContinue
    Remove-Variable -name earliestDateAD  -ErrorAction SilentlyContinue
    Remove-Variable -name extensionattribute6  -ErrorAction SilentlyContinue
    Remove-Variable -name earliestDate_formatted  -ErrorAction SilentlyContinue
    Remove-Variable -name adexpiredate  -ErrorAction SilentlyContinue
    
    Remove-Variable -name Effective_date  -ErrorAction SilentlyContinue
    
    
    


    
}

$timestamp = get-date
Write-Output "$timestamp : Ends"
