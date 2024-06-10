<#
  .SYNOPSIS
  Writes the specified text to a file.

  .DESCRIPTION
  This script writes a given text to a specified file, creating the directory if it doesn't exist.

  .PARAMETER TextToWriteToFile
  The text to write to the file.

  .PARAMETER FilePath
  The file path to write the text to, overwriting the file if it already exists.

  .EXAMPLE
  .\Script.ps1 -TextToWriteToFile "Sample Text" -FilePath "C:\Temp\Test.txt"

  .NOTES
  Ensure that you have the necessary permissions to write to the specified file path.
#>
[CmdletBinding()]
param (
  [Parameter(Mandatory = $false, HelpMessage = 'The text to write to the file.')]
  [string] $TextToWriteToFile = 'Hello, World!',

  [Parameter(Mandatory = $false, HelpMessage = 'The file path to write the text to.')]
  [string] $FilePath = "$PSScriptRoot\Test.txt"
)

process {
  Ensure-DirectoryExists -directoryPath (Split-Path -Path $FilePath -Parent)

  Write-Information "Writing the text '$TextToWriteToFile' to the file '$FilePath'."
  Write-TextToFile -text $TextToWriteToFile -filePath $FilePath
}

begin {
  function Ensure-DirectoryExists ([string] $directoryPath) {
    if (-not (Test-Path -Path $directoryPath -PathType Container))
    {
      Write-Information "Creating directory '$directoryPath'."
      New-Item -Path $directoryPath -ItemType Directory -Force > $null
    }
  }

  function Write-TextToFile ([string] $text, [string] $filePath) {
    if (Test-Path -Path $filePath -PathType Leaf) {
      Write-Warning "File '$filePath' already exists. Overwriting it."
    }

    Set-Content -Path $filePath -Value $text -Force
  }

  $InformationPreference = 'Continue'
  # $VerbosePreference = 'Continue' # Uncomment this line if you want to see verbose messages.

  # Log all script output to a file for easy reference later if needed.
  [string] $lastRunLogFilePath = "$PSCommandPath.LastRun.log"
  Start-Transcript -Path $lastRunLogFilePath

  # Display the time that this script started running.
  [DateTime] $startTime = Get-Date
  Write-Information "Starting script at '$($startTime.ToString('u'))'."
}

end {
  # Display the time that this script finished running, and how long it took to run.
  [DateTime] $finishTime = Get-Date
  [TimeSpan] $elapsedTime = $finishTime - $startTime
  Write-Information "Finished script at '$($finishTime.ToString('u'))'. Took '$elapsedTime' to run."

  Stop-Transcript
}