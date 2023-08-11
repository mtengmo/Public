#Paolo Frigo, https://www.scriptinglibrary.com
#Magnus Tengmo - modified with company and exists logic - 2023-05-09
function Create-NewLocalAdmin {
    [CmdletBinding()]
    param (
        [string] $NewLocalAdmin,
        [securestring] $Password
    )   

    
    begin {
    }    
    process {
        $UserExists = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$NewLocalAdmin'"
        if ($UserExists) {
            Write-Output "The user '$NewLocalAdmin' exists."
            Return
        }
        else {
            New-LocalUser "$NewLocalAdmin" -Password $Password -FullName "$NewLocalAdmin" -Description "Temporary local admin"
            Write-Verbose "$NewLocalAdmin local user crated"
            Add-LocalGroupMember -Group "Administrators" -Member "$NewLocalAdmin"
            Write-Verbose "$NewLocalAdmin added to the local administrator group"
        }
   
    }    
    end {
    }
}
$NewLocalAdmin = "localadmin"
$Password = $password = -join (33..126 | ForEach-Object { [char]$_ } | Get-Random -Count 30)
# pw will be reset by Windows LAPS policy

Create-NewLocalAdmin -NewLocalAdmin $NewLocalAdmin -Password (ConvertTo-SecureString -AsPlainText $password -Force) -Verbose

