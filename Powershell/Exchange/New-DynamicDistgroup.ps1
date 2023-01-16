New-DynamicDistributionGroup -name "Company - All Managers" -RecipientFilter "(RecipientType -eq 'UserMailbox') -and (CustomAttribute8 -eq 'true') -and (CustomAttribute7 -ne 'External Consultant') -and (CustomAttribute5 -ne 'Terminated')"

$members =Get-Recipient -RecipientPreviewFilter (Get-DynamicDistributionGroup $group).RecipientFilter

$members.count


Remove-DynamicDistributionGroup $group

$group = "domain - All Japan Employees and contractors"
New-DynamicDistributionGroup -name "$group" -RecipientFilter "(Office -eq 'Tokyo') -and (RecipientType -eq 'UserMailbox') -and (CustomAttribute7 -ne 'Thesis worker/Internship')  -and (CustomAttribute7 -ne 'External Consultant') -and (CustomAttribute5 -eq 'Active')"

$group = "domain - All Employees and consultants (worldwide)"
New-DynamicDistributionGroup -name "$group" -RecipientFilter "(RecipientType -eq 'UserMailbox') -and (CustomAttribute7 -ne 'External Consultant') -and (CustomAttribute5 -eq 'Active')"


#count 
$users = Get-Recipient -RecipientPreviewFilter (Get-DynamicDistributionGroup $group -ResultSize Unlimited).RecipientFilter -ResultSize Unlimited
$users.count


$group = "domain - All Employees including contractors (worldwide)"
New-DynamicDistributionGroup -name "$group" -RecipientFilter "(RecipientType -eq 'UserMailbox') -and (CustomAttribute7 -ne 'External Consultant') -and (CustomAttribute5 -eq 'Active')"


$missmatch = Compare-Object -ReferenceObject $users.WindowsLiveID -DifferenceObject $allglobal.UserPrincipalName