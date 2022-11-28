
#https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-ps-examples#check-if-user-license-is-assigned-directly-or-inherited-from-a-group#Returns TRUE if the user has the license assigned directly
function UserHasLicenseAssignedDirectly {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)

    foreach ($license in $user.Licenses) {
        #we look for the specific license SKU in all licenses assigned to the user
        if ($license.AccountSkuId -ieq $skuId) {
            #GroupsAssigningLicense contains a collection of IDs of objects assigning the license
            #This could be a group object or a user object (contrary to what the name suggests)
            #If the collection is empty, this means the license is assigned directly - this is the case for users who have never been licensed via groups in the past
            if ($license.GroupsAssigningLicense.Count -eq 0) {
                return $true
            }

            #If the collection contains the ID of the user object, this means the license is assigned directly
            #Note: the license may also be assigned through one or more groups in addition to being assigned directly
            foreach ($assignmentSource in $license.GroupsAssigningLicense) {
                if ($assignmentSource -ieq $user.ObjectId) {
                    return $true
                }
            }
            return $false
        }
    }
    return $false
}
#Returns TRUE if the user is inheriting the license from a group
function UserHasLicenseAssignedFromGroup {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)

    foreach ($license in $user.Licenses) {
        #we look for the specific license SKU in all licenses assigned to the user
        if ($license.AccountSkuId -ieq $skuId) {
            #GroupsAssigningLicense contains a collection of IDs of objects assigning the license
            #This could be a group object or a user object (contrary to what the name suggests)
            foreach ($assignmentSource in $license.GroupsAssigningLicense) {
                #If the collection contains at least one ID not matching the user ID this means that the license is inherited from a group.
                #Note: the license may also be assigned directly in addition to being inherited
                if ($assignmentSource -ine $user.ObjectId) {
                    return $true
                }
            }
            return $false
        }
    }
    return $false
}


Get-MsolAccountSku
$skuId = "tobii:ENTERPRISEPREMIUM"
$users = Get-MsolUser -All
$users = $users  | where { $_.isLicensed -eq $true -and $_.Licenses.AccountSKUID -eq $skuId }
$adusers = get-aduser -filter * -properties extensionattribute7, cn, l, description, title, sn, givenname, extensionattribute5, company




$i = 0
$id = @{}
$adusers.ForEach( {
        $id["$($psitem.UserPrincipalName)"] = $i #Create $var[name]=index
        $i++
    })
$result = $users.ForEach( {
        $this = $psitem
        $r = New-Object System.Object
        $temp = $null
        try {
            $temp = $adusers[($id[$psitem.UserPrincipalName])]
        }
        catch {}
        finally {
            $r | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $temp.UserPrincipalName
            $r | Add-Member -MemberType NoteProperty -Name skuId -Value $skuId
            $r | Add-Member -MemberType NoteProperty -Name enabled -Value $temp.enabled
            $r | Add-Member -MemberType NoteProperty -Name UserHasLicenseAssignedDirectly -Value (UserHasLicenseAssignedDirectly $_ $skuId)
            $r | Add-Member -MemberType NoteProperty -Name AssignedFromGroup -Value (UserHasLicenseAssignedFromGroup $_ $skuId)
            $r | Add-Member -MemberType NoteProperty -Name Name -Value $this.isLicensed
            $r | Add-Member -MemberType NoteProperty -Name cn -Value $temp.cn
            $r | Add-Member -MemberType NoteProperty -Name givenname -Value $temp.givenname
            $r | Add-Member -MemberType NoteProperty -Name sn -Value $temp.sn
            $r | Add-Member -MemberType NoteProperty -Name ExtensionAttribute7 -Value $temp.ExtensionAttribute7
            $r | Add-Member -MemberType NoteProperty -Name ExtensionAttribute5 -Value $temp.ExtensionAttribute5
            $r | Add-Member -MemberType NoteProperty -Name title -Value $temp.title
            $r | Add-Member -MemberType NoteProperty -Name company -Value $temp.company


            # $r | Add-Member -MemberType NoteProperty -Name Handles -Value $this.Handles
        }
        return $r
    }) #| sort status | select -Last 300
$result | Export-Csv C:\temp\o365license_"$(Get-Date -UFormat '%Y%m%d_%H%M%S')".csv -Delimiter ";" -NoTypeInformation -Encoding UTF8











