$xml = @'
<QueryList>
  <Query Id="0" Path="ForwardedEvents">
    <Select Path="ForwardedEvents">*[System[TimeCreated[timediff(@SystemTime) &lt;= 390000000]]]</Select>
  </Query>
</QueryList>
'@


$events = Get-WinEvent -FilterXml $xml |  Select-Object ID, LevelDisplayName, LogName, MachineName, @{Label = 'Messages'; Expression = { $_.properties.Value } }, ProviderName, RecordID, TaskDisplayName, TimeCreated

Write-DbaDataTable -SqlInstance 'instance' -Database 'dbname' -InputObject $events -AutoCreateTable -Table 'Eventlog_ForwardedEvents'