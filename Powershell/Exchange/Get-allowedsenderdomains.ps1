$policies = Get-HostedContentFilterPolicy
foreach ($policy in $policies){
    Get-HostedContentFilterPolicy
}


Get-HostedContentFilterPolicy -Identity "General spam filter" |select -ExpandProperty AllowedSenderDomains

