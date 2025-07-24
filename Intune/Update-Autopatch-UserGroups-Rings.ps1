# Improved logging for Azure Automation Account - Multi-Group Support
# Clear any existing variables at script start (Azure Automation best practice)
Remove-Variable -Name primaryUserIds -ErrorAction SilentlyContinue
Remove-Variable -Name uniqueUserIds -ErrorAction SilentlyContinue

# Connect to Microsoft Graph using Managed Identity (recommended for Azure Automation)
Connect-MgGraph -Identity

# === PARAMETERS ===
$deviceGroupConfigs = @(
    @{
        DeviceGroupName      = "Autopatch - Parent Group"
        UserGroupName        = "Primary Users of Autopatch Parent Group"
        UserGroupDescription = "Auto-managed group of primary users for Autopatch Parent Group devices"
    },
    @{
        DeviceGroupName      = "Autopatch - Ring1"
        UserGroupName        = "Primary Users of Autopatch Ring1 Group"
        UserGroupDescription = "Auto-managed group of primary users for Autopatch Ring1 Group devices"
    },
    @{
        DeviceGroupName      = "Autopatch - Ring2"
        UserGroupName        = "Primary Users of Autopatch Ring2 Group"
        UserGroupDescription = "Auto-managed group of primary users for Autopatch Ring2 Group devices"
    },
    @{
        DeviceGroupName      = "Autopatch - Ring3"
        UserGroupName        = "Primary Users of Autopatch Ring3 Group"
        UserGroupDescription = "Auto-managed group of primary users for Autopatch Ring3 Group devices"
    },
    @{
        DeviceGroupName      = "Autopatch - Test"
        UserGroupName        = "Primary Users of Autopatch Test Group"
        UserGroupDescription = "Auto-managed group of primary users for Autopatch Test Group devices"
    }
)

# === LOGGING SETUP ===
$logPath = "C:\ProgramData\Autopatch-UserMembershipGroup.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $Message"
    Write-Host $entry
    try {
        Add-Content -Path $logPath -Value $entry
    }
    catch {
        # If unable to write to file, just continue
    }
}

function Get-AllDevicesFromGroup {
    param([string]$GroupId)
    $members = Get-MgGroupTransitiveMember -GroupId $GroupId -All
    $devices = $members | Where-Object { $_.AdditionalProperties['@odata.type'] -eq "#microsoft.graph.device" }
    return $devices
}

function Sync-GroupMembership {
    param(
        [string]$GroupId,
        [array]$TargetUserIds,
        [string]$GroupName
    )
    
    Write-Log "Starting membership sync for group: $GroupName"
    
    # Validate input parameters
    if ([string]::IsNullOrEmpty($GroupId)) {
        Write-Log "ERROR: GroupId is null or empty for group '$GroupName'"
        return
    }
    
    # Handle potential array nesting from comma operator
    $flattenedUserIds = @()
    if ($TargetUserIds) {
        foreach ($item in $TargetUserIds) {
            if ($item -is [array]) {
                # Handle nested array from comma operator return
                $flattenedUserIds += $item
            }
            else {
                $flattenedUserIds += $item
            }
        }
    }
    
    Write-Log "Received $($flattenedUserIds.Count) target user IDs for validation"
    
    # Strict GUID validation
    $validUserIds = @()
    $invalidCount = 0
    
    foreach ($userId in $flattenedUserIds) {
        if ($userId -and $userId -is [string] -and $userId.Trim() -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
            $validUserIds += $userId.Trim()
        }
        else {
            $invalidCount++
            Write-Log "DEBUG: Invalid user ID filtered: '$userId' (Type: $($userId.GetType().Name))"
        }
    }
    
    if ($invalidCount -gt 0) {
        Write-Log "WARNING: Filtered out $invalidCount invalid user IDs for group '$GroupName'"
    }
    
    Write-Log "Validated $($validUserIds.Count) user IDs for group '$GroupName'"
    
    # Get current group members with retry logic for consistency
    $currentMemberIds = @()
    $maxRetries = 3
    $retryCount = 0
    
    do {
        try {
            # Use a fresh query each time to avoid caching issues
            $currentMembers = Get-MgGroupMember -GroupId $GroupId -All -Property "Id"
            $currentMemberIds = @($currentMembers.Id | Where-Object { $_ } | ForEach-Object { $_.ToString() })
            Write-Log "Group '$GroupName' currently has $($currentMemberIds.Count) members (attempt $($retryCount + 1))"
            break
        }
        catch {
            $retryCount++
            Write-Log "WARNING: Failed to get current group members for '$GroupName' (attempt $retryCount): $_"
            if ($retryCount -ge $maxRetries) {
                Write-Log "ERROR: Failed to get current group members for '$GroupName' after $maxRetries attempts"
                return
            }
            Start-Sleep -Seconds (2 * $retryCount)
        }
    } while ($retryCount -lt $maxRetries)
    
    # Ensure uniqueness and proper comparison
    $validUserIdsUnique = $validUserIds | Sort-Object -Unique
    $currentMemberIdsUnique = $currentMemberIds | Sort-Object -Unique
    
    $usersToAdd = $validUserIdsUnique | Where-Object { $_ -notin $currentMemberIdsUnique }
    $usersToRemove = $currentMemberIdsUnique | Where-Object { $_ -notin $validUserIdsUnique }

    Write-Log "Group '$GroupName' - Target users (unique): $($validUserIdsUnique.Count)"
    Write-Log "Group '$GroupName' - Current members (unique): $($currentMemberIdsUnique.Count)"
    Write-Log "Group '$GroupName' - Users to add: $($usersToAdd.Count)"
    Write-Log "Group '$GroupName' - Users to remove: $($usersToRemove.Count)"
    
    if ($usersToAdd.Count -eq 0 -and $usersToRemove.Count -eq 0) {
        Write-Log "Group '$GroupName' - No changes needed, group is already in sync"
        return
    }

    # Add new users with individual existence check due to consistency issues
    $addedCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    foreach ($userId in $usersToAdd) {
        $maxAttempts = 3
        $currentAttempt = 0
        $success = $false
        
        while (-not $success -and $currentAttempt -lt $maxAttempts) {
            $currentAttempt++
            try {
                # Use direct addition with proper exception handling instead of pre-check
                New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $userId -ErrorAction Stop
                $addedCount++
                $success = $true
                Write-Log "Group '$GroupName' - Successfully added user: $userId (Attempt $currentAttempt)"
                Start-Sleep -Milliseconds 250  # Increased delay for consistency
            }
            catch {
                # Handle specific exceptions for already existing members
                if ($_.Exception.Message -like "*already exist*" -or 
                    $_.Exception.Message -like "*already a member*" -or
                    $_.Exception.Message -like "*DirectoryValueExistsException*" -or
                    $_.Exception.Message -like "*Value for property exists*") {
                    
                    $skippedCount++
                    $success = $true  # Consider this a success since the member exists
                    Write-Log "Group '$GroupName' - User already exists (API response): $userId"
                }
                elseif ($currentAttempt -lt $maxAttempts) {
                    # Potentially transient error, retry with exponential backoff
                    $delay = 500 * [Math]::Pow(2, $currentAttempt - 1)  # 500ms, 1000ms, 2000ms
                    Write-Log "WARNING: Group '$GroupName' - Temporary error adding user $userId (Attempt $currentAttempt/$maxAttempts): $_. Retrying in $delay ms."
                    Start-Sleep -Milliseconds $delay
                }
                else {
                    # All attempts failed
                    $errorCount++
                    Write-Log "ERROR: Group '$GroupName' - Failed to add user $userId after $maxAttempts attempts: $_"
                }
            }
        }
    }

    # Remove users no longer in scope
    $removedCount = 0
    foreach ($userId in $usersToRemove) {
        try {
            Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $userId
            $removedCount++
            Write-Log "Group '$GroupName' - Successfully removed user: $userId"
            Start-Sleep -Milliseconds 200
        }
        catch {
            Write-Log "ERROR: Group '$GroupName' - Failed to remove user $userId : $_"
        }
    }
    
    Write-Log "Group '$GroupName' - Membership sync completed. Added: $addedCount, Skipped: $skippedCount, Removed: $removedCount"
    
    # Final verification with delay to allow for propagation
    Start-Sleep -Seconds 2
    try {
        $finalMembers = Get-MgGroupMember -GroupId $GroupId -All | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.user" }
        Write-Log "Group '$GroupName' - Final member count: $($finalMembers.Count)"
    }
    catch {
        Write-Log "WARNING: Could not verify final member count for group '$GroupName'"
    }
}

function Get-PrimaryUsersForDevices {
    param([array]$Devices)
    
    # Initialize fresh hashtable for this function call
    $primaryUserIds = @{}
    
    if (-not $Devices -or $Devices.Count -eq 0) {
        Write-Log "No devices provided to process"
        return @()
    }
    
    Write-Log "Processing $($Devices.Count) devices for primary users"
    
    foreach ($device in $Devices) {
        $deviceObjectId = $device.Id
        $deviceId = $device.AdditionalProperties['deviceId']
        $displayName = $device.AdditionalProperties['displayName']
        
        Write-Log "Processing device: $displayName (ObjectId: $deviceObjectId, DeviceId: $deviceId)"
        
        try {
            $intuneDevice = Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$deviceId'" -Property id, userId
            if ($intuneDevice -and $intuneDevice.userId) {
                # Validate that userId is a proper GUID before adding
                if ($intuneDevice.userId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
                    # Convert to string to ensure consistency
                    $userIdString = $intuneDevice.userId.ToString()
                    $primaryUserIds[$userIdString] = $true
                    Write-Log "Device $displayName : Found primary user $userIdString"
                }
                else {
                    Write-Log "WARNING: Device $displayName has invalid userId format: $($intuneDevice.userId)"
                }
            }
            else {
                Write-Log "Device $displayName : No primary user set"
            }
        }
        catch {
            Write-Log "WARNING: Device $displayName not found in Intune or error occurred: $_"
        }
    }
    
    # Extract keys and return as proper array (not nested)
    $userIds = [string[]]($primaryUserIds.Keys)
    Write-Log "Found $($userIds.Count) unique primary user IDs"
    
    # Debug: Log sample user IDs to verify format
    if ($userIds.Count -gt 0) {
        $sampleCount = [Math]::Min(3, $userIds.Count)
        $sampleIds = $userIds[0..($sampleCount - 1)]
        Write-Log "Sample user IDs: $($sampleIds -join ', ')"
    }
    
    # Return array without comma operator to avoid nesting
    return $userIds
}

Write-Log "Script started - Processing $($deviceGroupConfigs.Count) device groups"

# === MAIN PROCESSING LOOP ===
foreach ($config in $deviceGroupConfigs) {
    $deviceGroupName = $config.DeviceGroupName
    $userGroupName = $config.UserGroupName
    $userGroupDescription = $config.UserGroupDescription
    $uniqueUserIds = @()
    Write-Log "=== Processing Device Group: $deviceGroupName ==="
    
    # STEP 1: Get device group
    $deviceGroup = Get-MgGroup -Filter "displayName eq '$deviceGroupName'"
    if (-not $deviceGroup) {
        Write-Log "WARNING: Device group '$deviceGroupName' not found - skipping"
        continue
    }
    
    Write-Log "Found device group: $deviceGroupName"
    
    # STEP 2: Get devices in the device group (including nested groups)
    $devices = Get-AllDevicesFromGroup -GroupId $deviceGroup.Id
    if (-not $devices -or $devices.Count -eq 0) {
        Write-Log "No devices found in group: $deviceGroupName (including nested groups)"
        
        # Proceed to clear the user group
        $uniqueUserIds = @()  # Empty list of user IDs
    }
    else {
        Write-Log "Found $($devices.Count) devices in group: $deviceGroupName"
        
        # STEP 3: Get primary users from Intune managedDevices
        $uniqueUserIds = Get-PrimaryUsersForDevices -Devices $devices

        # Important fix: Even if no primary users found, we should proceed with an empty array
        # to properly clear the user group instead of skipping
        if ($null -eq $uniqueUserIds) {
            # Only skip if truly null (function error), not if empty array
            Write-Log "ERROR: Failed to retrieve primary users for devices in group: $deviceGroupName - skipping"
            continue
        }

        # Empty array is valid - will clear the group
        if ($uniqueUserIds.Count -eq 0) {
            Write-Log "No primary users found for devices in group: $deviceGroupName - will clear user group"
            # Continue processing to clear the group (don't skip)
        }
    }
    
    # STEP 4: Create or get the user group
    $userGroup = Get-MgGroup -Filter "displayName eq '$userGroupName'"
    if (-not $userGroup) {
        try {
            $userGroup = New-MgGroup -DisplayName $userGroupName `
                -MailEnabled:$false `
                -MailNickname ("primaryusers" + ([guid]::NewGuid().ToString("N").Substring(0, 6))) `
                -SecurityEnabled:$true `
                -GroupTypes @() `
                -Description $userGroupDescription
            Write-Log "Created user group: $($userGroup.DisplayName)"
        }
        catch {
            Write-Log "ERROR: Failed to create user group '$userGroupName': $_"
            continue
        }
    }
    else {
        Write-Log "Found existing user group: $($userGroup.DisplayName)"
    }
    
    # STEP 5: Sync group membership
    Sync-GroupMembership -GroupId $userGroup.Id -TargetUserIds $uniqueUserIds -GroupName $userGroupName
    
    Write-Log "=== Completed processing for: $deviceGroupName ==="
}

Write-Log "Script finished - Processed $($deviceGroupConfigs.Count) device groups"
