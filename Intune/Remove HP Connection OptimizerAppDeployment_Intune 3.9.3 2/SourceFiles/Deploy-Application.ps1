<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = 'MHP'
    [String]$appName = 'HP Bloatware remover'
    [String]$appVersion = '1.1'
    [String]$appArch = 'x64'
    [String]$appLang = 'MUI'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '01/11/2023'
    [String]$appScriptAuthor = 'Vasile Banc  - MHP'
    ##*===============================================
    ## Variables: Registry-Environment MHP Streams
    [string]$appFullName = "$appVendor" + " " + "$appName" + " " +"$appVersion" + " " + "$appArch" + " " + "$appLang"
    [string]$RegkeyINTUNE = "HKLM:\Software\MHP-Software"
    [string]$RegkeyApplication = "$RegkeyINTUNE"
    [string]$RegkeyApplicationFullName = "$RegkeyApplication" + "\" + "$appFullName"
    $Regkeys = $RegkeyINTUNE,$RegkeyApplication,$RegkeyApplicationFullName
    
    ## Variables:  Log-Environment MHP
    [string]$appMHPlog = "$appFullName"
    [string]$appMHPlogpatch = "$appFullName" + "_patch"

    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.2'
    [String]$deployAppScriptDate = '02/02/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        ##Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Installation tasks here>

       
        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        ## Handle Zero-Config MSI Installations
        ##If ($useDefaultMsi) {
            ##[Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                ##$ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            ##}
            ##Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) {
                ##$defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ }
           ##}
        ##}

        ## <Perform Installation tasks here>

        #   Remove HP bloatware / crapware - BETA version

        function Write-LogEntry {
        param (
            [parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,
    
            [parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
            [string]$Severity,
    
            [parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")]
            [ValidateNotNullOrEmpty()]
            [string]$FileName = "Remove-HP-Bloatware.log"
        )
        # Determine log file location
        $LogFilePath = Join-Path -Path (Join-Path -Path $env:windir -ChildPath "Install2") -ChildPath $FileName
        
        # Construct time stamp for log entry
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
        
        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")
        
        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        
        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""RemoveHPBloatware"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
        
        # Add value to log file
        try {
            Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to Remove-HP-Bloatware.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        }
    }



#Remove HP Documentation
if (Test-Path "C:\Program Files\HP\Documentation\Doc_uninstall.cmd" -PathType Leaf){
Try {
    Invoke-Item "C:\Program Files\HP\Documentation\Doc_uninstall.cmd"
    Write-LogEntry -Value "Successfully removed provisioned package: HP Documentation" -Severity 1
    }
Catch {
        Write-LogEntry -Value  "Error Remvoving HP Documentation $($_.Exception.Message)" -Severity 3
        }
}
Else {
        Write-LogEntry -Value  "HP Documentation is not installed" -Severity 1
}

#Remove HP Support Assistant silently

$HPSAuninstall = "C:\Program Files (x86)\HP\HP Support Framework\UninstallHPSA.exe"

if (Test-Path -Path "HKLM:\Software\WOW6432Node\Hewlett-Packard\HPActiveSupport") {
Try {
        Remove-Item -Path "HKLM:\Software\WOW6432Node\Hewlett-Packard\HPActiveSupport"
        Write-LogEntry -Value  "HP Support Assistant regkey deleted $($_.Exception.Message)" -Severity 1
    }
Catch {
        Write-LogEntry -Value  "Error retreiving registry key for HP Support Assistant: $($_.Exception.Message)" -Severity 3
        }
}
Else {
        Write-LogEntry -Value  "HP Support Assistant regkey not found" -Severity 1
}

if (Test-Path $HPSAuninstall -PathType Leaf) {
    Try {
        & $HPSAuninstall /s /v/qn UninstallKeepPreferences=FALSE
        Write-LogEntry -Value "Successfully removed provisioned package: HP Support Assistant silently" -Severity 1
    }
        Catch {
        Write-LogEntry -Value  "Error uninstalling HP Support Assistant: $($_.Exception.Message)" -Severity 3
        }
}
Else {
        Write-LogEntry -Value  "HP Support Assistant Uninstaller not found" -Severity 1
}


#Remove HP Connection Optimizer

$HPCOuninstall = "C:\Program Files (x86)\InstallShield Installation Information\{6468C4A5-E47E-405F-B675-A70A70983EA6}\setup.exe"

#copy uninstall file
	
New-Item -Path "C:\Windows" -Name "install2" -ItemType Directory
Copy-Item -Path "$dirFiles\uninstallHPCO.iss" -Destination "C:\Windows\install2"
Write-LogEntry -Value  "Succesfully copied file uninstallHPCO.iss to C:\Windows\install2 " -Severity 1

if (Test-Path $HPCOuninstall -PathType Leaf){
Try {   
        
        MsiExec.exe /X "{6468C4A5-E47E-405F-B675-A70A70983EA6}" /qn /norestart
        #& $HPCOuninstall -runfromtemp -l0x0413  -removeonly -s -f1 "C:\Windows\install2\uninstallHPCO.iss"
        Write-LogEntry -Value "Successfully removed HP Connection Optimizer" -Severity 1
        }
Catch {
        Write-LogEntry -Value  "Error uninstalling HP Connection Optimizer: $($_.Exception.Message)" -Severity 3
        }
}
Else {
        Write-LogEntry -Value  "HP Connection Optimizer not found" -Severity 1
}


#List of packages to install
$UninstallPackages = @(
    "AD2F1837.HPJumpStarts"
    "AD2F1837.HPPCHardwareDiagnosticsWindows"
    "AD2F1837.HPPowerManager"
    "AD2F1837.HPPrivacySettings"
    "AD2F1837.HPSupportAssistant"
    "AD2F1837.HPSureShieldAI"
    "AD2F1837.HPSystemInformation"
    "AD2F1837.HPQuickDrop"
    "AD2F1837.HPWorkWell"
    "AD2F1837.myHP"
    "AD2F1837.HPDesktopSupportUtilities"
    "AD2F1837.HPEasyClean"
    "AD2F1837.HPSystemInformation"
)

# List of programs to uninstall
$UninstallPrograms = @(
    "ICS"
    "HP Connection Optimizer"
    "HP Documentation"
    "HP MAC Address Manager"
    "HP Notifications"
    "HP Security Update Service"
    "HP System Default Settings"
    "HP Sure Click"
    "HP Sure Run"
    "HP Sure Run Module"
    "HP Sure Recover"
    "HP Sure Sense"
    "HP Sure Sense Installer"
    "HP Wolf Security Application Support for Sure Sense"
    "HP Wolf Security Application Support for Windows"
    "HP Client Security Manager"
    "HP Wolf Security"
)

#Get a list of installed packages matching our list
$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {($UninstallPackages -contains $_.Name)}

#Get a list of Provisioned packages matching our list
$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object  {($UninstallPackages -contains $_.DisplayName)}

#Get a list of installed programs matching our list
$InstalledPrograms = Get-Package | Where-Object  {$UninstallPrograms -contains $_.Name}


# Remove provisioned packages first
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-LogEntry -Value "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]" -Severity 1

    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-LogEntry -Value "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]" -Severity 1
    }
    Catch {
        Write-LogEntry -Value  "Failed to remove provisioned package: [$($ProvPackage.DisplayName)] Error message: $($_.Exception.Message)" -Severity 3
    }
}

# Remove appx packages
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-LogEntry -Value "Attempting to remove Appx package: [$($AppxPackage.Name)] " -Severity 1

    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-LogEntry -Value "Successfully removed Appx package: [$($AppxPackage.Name)]" -Severity 1
    }
    Catch {
        Write-LogEntry -Value  "Failed to remove Appx package: [$($AppxPackage.Name)] Error message: $($_.Exception.Message)" -Severity 3
    }
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-LogEntry -Value "Attempting to uninstall: [$($_.Name)]"  -Severity 1

    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-LogEntry -Value "Successfully uninstalled: [$($_.Name)]" -Severity 1
    }
    Catch {
        Write-LogEntry -Value  "Failed to uninstall: [$($_.Name)] Error message: $($_.Exception.Message)" -Severity 3
    }
}

#Fallback attempt 1 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{0E2E04B0-9EDD-11EB-B38C-10604B96B11E}" /qn /norestart
    Write-LogEntry -Value "Fallback to MSI uninistall for HP Wolf Security initiated" -Severity 1
}
Catch {
    Write-LogEntry -Value  "Failed to uninstall HP Wolf Security using MSI - Error message: $($_.Exception.Message)" -Severity 3
}

#Fallback attempt 2 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{4DA839F0-72CF-11EC-B247-3863BB3CB5A8}" /qn /norestart
    Write-LogEntry -Value "Fallback to MSI uninistall for HP Wolf 2 Security initiated" -Severity 1
}
Catch {
    Write-LogEntry -Value  "Failed to uninstall HP Wolf Security 2 using MSI - Error message: $($_.Exception.Message)" -Severity 3
}


#Remove shortcuts
$pathTCO = "C:\ProgramData\HP\TCO"
$pathTCOc = "C:\Users\Public\Desktop\TCO Certified.lnk"
$pathOS = "C:\Program Files (x86)\Online Services"
$pathFT = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Free Trials.lnk"

if (Test-Path $pathTCO) {
    Try {
        Remove-Item -LiteralPath $pathTCO -Force -Recurse
        Write-LogEntry -Value "Shortcut for $pathTCO removed" -Severity 1
    }
        Catch {
        Write-LogEntry -Value  "Error deleting $pathTCO $($_.Exception.Message)" -Severity 3
        }
    }
Else {
        Write-LogEntry -Value  "Folder $pathTCO not found" -Severity 1
}

if (Test-Path $pathTCOc -PathType Leaf) {
    Try {
        Remove-Item -Path $pathTCOc  -Force -Recurse
        Write-LogEntry -Value "Shortcut for $pathTCOc removed" -Severity 1
    }
        Catch {
        Write-LogEntry -Value  "Error deleting $pathTCOc $($_.Exception.Message)" -Severity 3
        }
    }
Else {
        Write-LogEntry -Value  "File $pathTCOc not found" -Severity 1
}

if (Test-Path $pathOS) {
    Try {
        Remove-Item -LiteralPath $pathOS  -Force -Recurse
        Write-LogEntry -Value "Shortcut for $pathOS removed" -Severity 1
    }
        Catch {
        Write-LogEntry -Value  "Error deleting $pathOS $($_.Exception.Message)" -Severity 3
        }
    }
Else {
        Write-LogEntry -Value  "Folder $pathOS not found" -Severity 1
}

    if (Test-Path $pathFT -PathType Leaf) {
    Try {
        Remove-Item -Path $pathFT -Force -Recurse
        Write-LogEntry -Value "Shortcut for $pathFT removed" -Severity 1
    }
        Catch {
        Write-LogEntry -Value  "Error deleting $pathFT $($_.Exception.Message)" -Severity 3
        }
    }
Else {
        Write-LogEntry -Value  "File $pathFT not found" -Severity 1
}

#Clean up uninstall file for HP Connection Optimizer
Remove-Item -Path 'C:\Windows\install2\uninstallHPCO.iss' -Force
Write-LogEntry -Value  "Succesfully deleted file C:\Windows\install2\uninstallHPCO.iss " -Severity 1
    

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>

        ## Display a message at the end of the install
        ##If (-not $useDefaultMsi) {
            ##Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
        ##}


        ##*==============================================================================================
		##* Registry-Environment MHP - INSTALLATION
		##*==============================================================================================

        # Creating Main Regkeys for INTUNE Branding
        Foreach ($i in $Regkeys)
        {
         $RegkeyExists = Test-Path $i
         If ($RegkeyExists -eq $False) {New-Item $i}
        }

        #Installed
        New-ItemProperty -path $RegkeyApplicationFullName -Name Installed -PropertyType DWord -Value "1" -FORCE
        #InstallDate
        $InstallDate = Get-Date -format dd.MM.yyyy
        New-ItemProperty -path $RegkeyApplicationFullName -Name Install_Date -PropertyType String -Value "$InstallDate" -FORCE
        #InstallTime
        $InstallTime = Get-Date -Format HH:mm
        New-ItemProperty -path $RegkeyApplicationFullName -Name Install_Time -PropertyType String -Value "$InstallTime" -FORCE
        #Script Version
        New-ItemProperty -path $RegkeyApplicationFullName -Name Script_Version -PropertyType String -Value "$appScriptVersion" -FORCE
		
		## Display a message at the end of the install
		## If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'llations.' -ButtonRightText 'OK' -Icon Information -NoWai
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        ##Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Uninstallation tasks here>


        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        ##If ($useDefaultMsi) {
            ##[Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                ##$ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            ##}
            ##Execute-MSI @ExecuteDefaultMSISplat
        ##}

        ## Uninstall HP Connection Optimizer

       
        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>

        ##*====================y==========================================================================
		##* Registry-Environment MHP - UNINSTALLATION
		##*==============================================================================================
        ## Remove Registry Key for Application Informations
        Remove-Item $RegkeyApplicationFullName -recurse
    }
    ##ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        ##Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        ##If ($useDefaultMsi) {
            ##[Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) {
                ##$ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            ##}
            ##Execute-MSI @ExecuteDefaultMSISplat
        ##}
        ## <Perform Repair tasks here>

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>


    ##}
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
