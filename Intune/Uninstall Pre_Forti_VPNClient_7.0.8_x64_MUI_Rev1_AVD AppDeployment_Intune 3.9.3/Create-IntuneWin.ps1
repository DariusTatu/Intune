<# 
Script Name: Create-IntuneWin32
Script Version: 1.0

Script Author: Alessio Maiorano - Bechtle GmbH It-Systemhaus Stuttgart
#>

## Prepare Environment

# Determine script location for PowerShell
$ScriptRoot = Split-Path $script:MyInvocation.MyCommand.Path

## Global Variables

# Define Path Variables
$IntuneAppUtil = "$ScriptRoot\IntuneWinAppUtil.exe"
$IntuneWinDir = "$ScriptRoot\IntuneWin"
$SourceFilesDir = "$ScriptRoot\SourceFiles"

$SetupFilePath = Get-ChildItem -Path "$SourceFilesDir\*" -Include ("*.exe", "*.msi")

## Create Dircetory Structure

if(!(Test-Path -Path $IntuneWinDir))
{
    New-Item -Path $ScriptRoot -Name "IntuneWinDir" -ItemType Directory
}

## Execute Intune Intune Win App Utility

if($SetupFilePath.Count -eq 1)
{
    try
    {
        Start-Process -FilePath $IntuneAppUtil -ArgumentList "-c $SourceFilesDir -s $($SetupFilePath.FullName) -o $IntuneWinDir -q"
        [System.Windows.Forms.MessageBox]::Show("IntuneWin File successfully created.","Success",0)
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show("Failed to create IntuneWinFile`n`nSource Files Dir: $SourceFilesDir`nSetup File: $($SetupFilePath.FullName)`nIntuneWin Directory: $IntuneWinDir","Error: Failed IntuneWin",0)
    }
}
else
{
    [System.Windows.Forms.MessageBox]::Show("Multiple Executebales were found.`n`nPlease make sure that the SourceFiles Directory contains only one executable.","Error: Multiple Files found",0)
} 

