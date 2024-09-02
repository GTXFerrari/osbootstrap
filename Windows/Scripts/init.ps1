# Check if running as ADMIN
Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
    Break
} else
{
    Write-Host "Code is running as administrator — go on executing the script..." -ForegroundColor Green
}

# Install Choco
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion))
{
    Write-Output "Chocolatey Version $chocoVersion is already installed"
} else
{
    Write-Output "Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
}

# Install WSL
$wsl_install = Read-Host "Would you like to install Windows Subsystem for Linux (WSL)? (Y/N)"
if ($wsl_install -eq "Y" -or $wsl_install -eq "y")
{
    Write-Host "Setting up WSL" -ForegroundColor Green
    $distro_choice = Read-Host "Choose your linux distro (Ubuntu,Kali,Debian,None)"
    switch ($distro_choice) 
    {
        "Ubuntu"
        {
            "wsl --install -d Ubuntu"
        }
        "Kali"
        {
            "wsl --install -d kali"
        }
        "Debian"
        {
            "wsl --install -d debian"
        }
        "None"
        {
            "wsl --install --no-distribution"
            Write-Host "Import your tar file with wsl --import" -ForegroundColor Green
        }
        default
        {
            Write-Host "Invalid choice, Select a valid distro" -ForegroundColor Red
            return
        }
    }
}

# Install Hyper-V
$hyprv = Read-Host "Would you like to setup HyperV? (Y/N)"
if ($hyprv -eq "Y" -or $hyprv -eq "y")
{
    Write-Host "Setting up Hyper-V" -ForegroundColor Green
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
}

# Install AMD chipset software, ryzen master & some nerd fonts
choco install amd-ryzen-chipset -y
choco install amd-ryzen-master -y
choco install nerd-fonts-jetbrainsmono -y
choco install nerd-fonts-sourcecodepro -y
choco install nerd-fonts-meslo -y
choco install nerd-fonts-cascadiacode -y

# Enable Memory Core Isolation (Security) & Enable Dark Mode (For vm's without key)
#reg import .\Reg-Files\Enable_Mem_CoreISO.reg
#reg import .\Reg-Files\Enable_Dark_Mode.reg

# Disable UAC
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0

# Enable LongPaths
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

# Configure power
powercfg /S 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c # Set power plan to high performance
powercfg /x -hibernate-timeout-ac 0
powercfg /x -hibernate-timeout-dc 0
powercfg /x -disk-timeout-ac 0
powercfg /x -disk-timeout-dc 0
powercfg /x -monitor-timeout-ac 0
powercfg /x -monitor-timeout-dc 0
Powercfg /x -standby-timeout-ac 0
powercfg /x -standby-timeout-dc 0

# Wallpapers
New-Item -ItemType Directory $env:USERPROFILE\Pictures\Wallpapers
robocopy /V /ETA /E \\10.0.40.5\Jake\Assets\Wallpapers\3440x1440 $env:USERPROFILE\Pictures\Wallpapers\

# PWSH
Copy-Item \\10.0.40.5\Jake\Backups\Powershell\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\PowerShell\
Install-Script winfetch
Install-Module -Name Terminal-Icons -Repository PSGallery
Install-Module PSWindowsUpdate
Add-WUServiceManager -MicrosoftUpdate

# SSH
New-Item -ItemType Directory $env:USERPROFILE\.ssh\
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent

# Rename the PC
Rename-Computer -Confirm -NewName Jakes-PC -Restart
