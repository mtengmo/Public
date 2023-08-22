# export all users from a AAD group with their extensionattribute6 
# Connect to Microsoft Graph
Connect-MgGraph

# Retrieve Group Information
# Replace '.service.salesforce' with the actual group name
$group = Get-MgGroup -Filter "displayName eq '.service.salesforce'"

# Retrieve Group Members
# Retrieve all members of the group, including members from nested groups
$groupMembers = Get-MgGroupMember -GroupId $group.Id -All

# Initialize an array to store the results
$results = @()

# Generate a timestamp for the filename
$timestamp = (Get-Date -Format yyyyMMddHHmm)
# Define the CSV file name and path
$filename = 'c:\script\aad\Salesforce_user_with_legal_company_' + $timestamp + '.csv'

# Loop through each user in the group
foreach ($user in $groupMembers) {
    # Retrieve extensionAttribute6 value for the user
    $extensionAttribute6 = Get-MgUser -UserId $user.Id -Property onPremisesExtensionAttributes |
                           Select-Object -ExpandProperty onPremisesExtensionAttributes |
                           Select-Object -ExpandProperty ExtensionAttribute6
    
    # Retrieve UserPrincipalName for the user
    $userPrincipalName = Get-MgUser -UserId $user.Id | Select-Object -ExpandProperty UserPrincipalName

    # Create a new PSObject to store user data
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name "UserPrincipalName" -Value $userPrincipalName
    $object | Add-Member -MemberType NoteProperty -Name "ExtensionAttribute6" -Value $extensionAttribute6
    
    # Add the object to the results array
    $results += $object
}

# Export the results to a CSV file
$results | Export-Csv $filename -Delimiter ";" -NoTypeInformation -Encoding utf8
