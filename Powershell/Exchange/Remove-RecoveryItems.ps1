#https://learn.microsoft.com/en-us/microsoft-365/compliance/delete-items-in-the-recoverable-items-folder-of-mailboxes-on-hold?source=recommendations&view=o365-worldwide#step-5-delete-items-in-the-recoverable-items-folder


For ($i = 1; $i -lt 10000; $i++) { 
    do { 
        New-ComplianceSearchAction -SearchName bdan -Purge -PurgeType HardDelete -Confirm:$false -Force
        Sleep 2 
        While ($status -ne "Completed" ) {
            Sleep 2 
            $status = (Get-ComplianceSearchAction -Identity bdan_purge).status
            $timestamp = get-date
            Write-Output "$timestamp : $status"
            
        } 
        $status = $null
    }
    
    While ($i -ge 10000)
} 


 