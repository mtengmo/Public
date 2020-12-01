New-DynamicDistributionGroup -name "Company - All Managers" -RecipientFilter "(RecipientType -eq 'UserMailbox') -and (CustomAttribute8 -eq 'true') -and (CustomAttribute7 -ne 'External Consultant') -and (CustomAttribute5 -ne 'Terminated')"

$members =Get-Recipient -RecipientPreviewFilter (Get-DynamicDistributionGroup $group).RecipientFilter

$members.count