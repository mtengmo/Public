<# 
.SYNOPSIS
    Lists delegated permission grants (OAuth2PermissionGrants) and application permissions grants (AppRoleAssignments) granted to an app.

.PARAMETER ObjectId
    The ObjectId of the ServicePrincipal object for the app in question.

.PARAMETER AppId
    The AppId of the ServicePrincipal object for the app in question.

.PARAMETER Preload
    Whether to preload user and service principals into cache. Useful for processing many apps in small or medium-sized tenants.

.EXAMPLE
    PS C:\> .\Get-AzureADPSPermissionGrants.ps1 -AppId "ec70084d-9b61-42bc-b29e-51e1ce39eb39"
    Gets all permissions granted to an app, identifying the app by AppId.

.EXAMPLE
    PS C:\> .\Get-AzureADPSPermissionGrants.ps1 -ObjectId "73523d04-f9e8-472c-b724-9cf68dcf81b7"
    Get all permission granted to an app, identifying the app by ObjectId.

.EXAMPLE
    PS C:\> Get-AzureADServicePrincipal -All $true | .\Get-AzureADPSPermissionGrants.ps1 -Preload
    Get all granted permissions for all apps in the organization.
#>

[CmdletBinding(DefaultParameterSetName = 'ByObjectId')]
param(

    [Parameter(ParameterSetName = 'ByObjectId', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    $ObjectId,
    
    [Parameter(ParameterSetName = 'ByAppId', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    $AppId,

    [switch] $Preload
)

begin {

    # Get tenant details to test that Connect-AzureAD has been called
    try {
        $tenant_details = Get-AzureADTenantDetail
    } catch {
        throw "You must call Connect-AzureAD before running this script."
    }
    Write-Verbose ("TenantId: {0}, InitialDomain: {1}" -f `
                    $tenant_details.ObjectId, `
                    ($tenant_details.VerifiedDomains | Where-Object { $_.Initial }).Name)

    # An in-memory cache of objects by {object ID} and by {object class, object ID} 
    $script:ObjectByObjectId = @{}
    $script:ObjectByObjectClassId = @{}

    # Function to add an object to the cache
    function CacheObject($Object) {
        if ($Object) {
            if (-not $script:ObjectByObjectClassId.ContainsKey($Object.ObjectType)) {
                $script:ObjectByObjectClassId[$Object.ObjectType] = @{}
            }
            $script:ObjectByObjectClassId[$Object.ObjectType][$Object.ObjectId] = $Object
            $script:ObjectByObjectId[$Object.ObjectId] = $Object
        }
    }

    # Function to retrieve an object from the cache (if it's there), or from Azure AD (if not).
    function GetObjectByObjectId($ObjectId) {
        Write-Debug ("GetObjectByObjectId: ObjectId: '{0}'" -f $ObjectId)
        if (-not $script:ObjectByObjectId.ContainsKey($ObjectId)) {
            Write-Verbose ("Querying Azure AD for object '{0}'" -f $ObjectId)
            $object = Get-AzureADObjectByObjectId -ObjectId $ObjectId
            if ($object) {
                CacheObject -Object $object
            } else {
                throw ("Object not found for ObjectId: '{0}'" -f $ObjectId)
            }
        }
        return $script:ObjectByObjectId[$ObjectId]
    }

    $cache_preloaded = $false
    $behavior = $null
}

process {

    # Retrieve the client ServicePrincipal object (which also ensure it actually exists)
    if ($PSCmdlet.ParameterSetName -eq "ByObjectId") {
        try {
            $client = GetObjectByObjectId -ObjectId $ObjectId
        } catch {
            Write-Error ("Unable to retrieve client ServicePrincipal object by ObjectId: '{0}'" -f $ObjectId)
            throw $_
        }
    } elseif ($PSCmdlet.ParameterSetName -eq "ByAppId") {
        try {
            $client = Get-AzureADServicePrincipal -Filter ("appId eq '{0}'" -f $AppId)
            CacheObject -Object $client
        } catch {
            Write-Error ("Unable to retrieve client ServicePrincipal object by AppId: '{0}'" -f $AppId)
            throw $_
        }
    }

    Write-Verbose ("Client DisplayName: '{0}', ObjectId: '{1}, AppId: '{2}'" -f $client.DisplayName, $client.ObjectId, $client.AppId)

    # Get one page of User objects and one of ServicePrincipal objects, and add to the cache. For smaller tenants,
    # this avoids a large number of requests to get individual objects. This behavior can be skipped with -NoPreload,
    # in which the first time each object is needed it will be requested and loaded into the cache.
    Write-Verbose ("Retrieving a page of User objects and a page of ServicePrincipal objects...")
    if (($Preload) -and (-not $cache_preloaded)) {
        Get-AzureADServicePrincipal -Top 999 | ForEach-Object { CacheObject -Object $_ }
        Get-AzureADUser -Top 999 | ForEach-Object { CacheObject -Object $_ }
        $cache_preloaded = $true
    }

    # Get all delegated permission grants
    Write-Verbose "Retrieving OAuth2PermissionGrants..."
    Get-AzureADServicePrincipalOAuth2PermissionGrant -ObjectId $client.ObjectId | ForEach-Object {
        $grant = $_
        if ($grant.Scope) {
            $grant.Scope.Split(" ") | Where-Object { $_ } | ForEach-Object {
                
                $scope = $_

                $resource = GetObjectByObjectId -ObjectId $grant.ResourceId
                $permission = $resource.OAuth2Permissions | Where-Object { $_.Value -eq $scope }

                $principalDisplayName = ""
                if ($grant.PrincipalId) {
                    $principal = GetObjectByObjectId -ObjectId $grant.PrincipalId
                    $principalDisplayName = $principal.DisplayName
                }

                return New-Object PSObject -Property ([ordered]@{
                    "PermissionType" = "Delegated"
                                    
                    "ClientObjectId" = $grant.ClientId
                    "ClientDisplayName" = $client.DisplayName
                    
                    "ResourceObjectId" = $grant.ResourceId
                    "ResourceDisplayName" = $resource.DisplayName

                    "Permission" = $scope
                    "PermissionId" = $permission.Id
                    "PermissionDisplayName" = $permission.AdminConsentDisplayName
                    "PermissionDescription" = $permission.AdminConsentDescription
                    
                    "ConsentType" = $grant.ConsentType
                    "PrincipalObjectId" = $grant.PrincipalId
                    "PrincipalDisplayName" = $principalDisplayName

                    "PermissionGrantId" = $grant.ObjectId
                })
            }
        }
    }

    # Get all application permission grants
    Write-Verbose "Retrieving app role assignments..."

    # There's some interesting behavior in Azure AD Graph where appRoleAssignments and appRoleAssignedTo present different
    # behavior based on whether the caller is a Microsoft-published app (e.g. Azure AD PowerShell), or if the caller 
    # is an app registered by any other organization (e.g. when calling Connect-AzureAD with -AadAccessToken).
    # The lines below will take care of detecting and adjusting for this inconsistency.
    switch ($behavior) {
        "1P" {
            $assignments = @(Get-AzureADServiceAppRoleAssignedTo -ObjectId $client.ObjectId -All $true)
        }
        "3P" {
            $assignments = @(Get-AzureADServiceAppRoleAssignment -ObjectId $client.ObjectId -All $true)
        }
        default {
            $assignedTo = @(Get-AzureADServiceAppRoleAssignedTo -ObjectId $client.ObjectId -All $true)
            $assignments = @()
        
            if ($assignedTo.Count -gt 0 -and $assignedTo[0].PrincipalId -eq $client.ObjectId) {
                $assignments = $assignedTo
                $behavior = "1P"
            } else {
                $assignments = @(Get-AzureADServiceAppRoleAssignment -ObjectId $client.ObjectId -All $true)
                if (($assignedTo.Count -gt 0 -and $assignedTo[0].PrincipalId -ne $client.ObjectId) -or
                        ($assignments.Count -gt 0 -and $assignments[0].PrincipalId -eq $client.ObjectId)) {
                    $behavior = "3P" # $assignments is accurate
                } else {
                    if ($assignments.Count -gt 0 -and $assignments[0].PrincipalId -ne $client.ObjectId) {
                        $assignments = $assignedTo # ... which is actually @(), but doing this instead for clarity
                        $behavior = "3P"
                    } else {
                        # $assignments is accurate (empty)
                    }
                }
            }
        }
    } 

    # Now expand and output all the application permission grants
    $assignments | Where-Object { $_.PrincipalType -eq "ServicePrincipal" } | ForEach-Object {
        $assignment = $_

        $resource = GetObjectByObjectId -ObjectId $assignment.ResourceId
        $appRole = $resource.AppRoles | Where-Object { $_.Id -eq $assignment.Id }

        return New-Object PSObject -Property ([ordered]@{
            "PermissionType" = "Application"
            
            "ClientObjectId" = $assignment.PrincipalId
            "ClientDisplayName" = $client.DisplayName
            
            "ResourceObjectId" = $assignment.ResourceId
            "ResourceDisplayName" = $resource.DisplayName

            "Permission" = $appRole.Value
            "PermissionId" = $assignment.Id
            "PermissionDisplayName" = $appRole.DisplayName
            "PermissionDescription" = $appRole.Description

            "PermissionGrantId" = $assignment.ObjectId
        })
    }
}