$Report = [System.Collections.Generic.List[Object]]::new() # Create output file list object

foreach ($user in $users) {
    $mail = $user.mail
    $filter = "EmailAddress -eq '$Mail'"
    $timestamp = get-date
   
    $aduser = get-aduser -Filter $filter -Properties UserPrincipalName, Extensionattribute5, Extensionattribute7, title, department, WhenCreated
    if (!$aduser) {
        Write-output "empty $mail filter on upn"
        $filter = "UserPrincipalName -eq '$Mail'"
        $aduser = get-aduser -Filter $filter -Properties UserPrincipalName, Extensionattribute5, Extensionattribute7, title, department, WhenCreated

    }
    $UserPrincipalName = $aduser.UserPrincipalName
    Write-Output "$timestamp : $UserPrincipalName"
    $DisplayName = $aduser.name
    $department = $aduser.department
    $title = $aduser.title
    $extensionattribute5 = $aduser.extensionattribute5
    $extensionattribute7 = $aduser.extensionattribute7

 
    $ReportLine = [PSCustomObject] @{
        Listmail                    = $mail
        UserPrincipalName           = $UserPrincipalName
        DisplayName                 = $DisplayName
        Department                  = $department
        Title                       = $title
        extensionattribute5         = $extensionattribute5
        extensionattribute7         = $extensionattribute7
  
  
    }
    
    $Report.Add($ReportLine)
} 
$report  | Export-Csv c:\temp\list.csv -Delimiter ";" -Encoding utf8 -NoTypeInformation

