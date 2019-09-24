#requires -version 2
<#
.SYNOPSIS
Count filetype per folder, start from input folder
.DESCRIPTION
.Example

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [Parameter(Mandatory = $true)][string]$path = ""
)

$timestamp = Get-Date
Write-Output "Start counting filetypes on $path at : $timestamp"
$pathfilename = $path.replace('\','-')

Get-ChildItem -path $path -Recurse -File | Group-Object DirectoryName |
ForEach-Object { 
    "{0}{1}" -f ($_.Name+";"),
     (($_.Group | Group-Object Extension | sort count -desc |
        ForEach-Object { ("{0}{1}" -f $_.Count, $_.Name) }) -join ";")
}  | Out-file "c:\temp\$pathfilename.txt"

[TimeSpan]$Duration = (Get-Date)-$timestamp
$durationdesc = "{0:hh\:mm\:ss\.fff}" -f ([TimeSpan] $duration)
Write-Output "Saved file c:\temp\$pathfilename.txt, Duration: $durationdesc"
