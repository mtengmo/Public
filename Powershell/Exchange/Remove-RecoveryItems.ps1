#https://learn.microsoft.com/en-us/microsoft-365/compliance/delete-items-in-the-recoverable-items-folder-of-mailboxes-on-hold?source=recommendations&view=o365-worldwide#step-5-delete-items-in-the-recoverable-items-folder
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowBasic' -Type DWord -Value '1'

$searchname = "bdan6"
Remove-ComplianceSearchAction ($($searchname)+"_purge") -Confirm:$false
For ($i = 1; $i -lt 100000; $i++) { 
    do { 
        try {New-ComplianceSearchAction -SearchName $searchname -Purge -PurgeType HardDelete -Confirm:$false -Force }
        catch {
            Write-Output "$timestamp : Error, removing searchjob"
            Remove-ComplianceSearchAction ($($searchname)+"_purge") -Confirm:$false
        }
        Sleep 4 
        Write-Output "$timestamp : Run $i"
        #if ($timestamp.Minute%10 -eq 0) {
        #    $mails = Get-MailboxFolderStatistics -Identity bdan@tbdvox.com -FolderScope RecoverableItems | select ItemsInFolderAndSubfolders
        ##    $count = ($mails.ItemsInFolderAndSubfolders  | Measure-Object -Sum).sum
        #    Write-ouput "$timestamp : Left mail in mailbox (just to see it´s going down): $count"
        #}
        While ($status -ne "Completed" ) {
            Sleep 4 
            $status = (Get-ComplianceSearchAction -Identity ($($searchname)+"_purge") -ErrorAction SilentlyContinue).status 
            $timestamp = get-date
            Write-Output "$timestamp : $status"
            
        } 
        $status = $null
    }
        While ($i -ge 100000)
} 


#Get-MailboxFolderStatistics -Identity bdan -FolderScope RecoverableItems | Format-Table Name,FolderAndSubfolderSize,ItemsInFolderAndSubfolders -Auto


 