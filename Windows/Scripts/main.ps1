# Logging
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logdir = "$env:LOCALAPPDATA\win-setup\logs"
[System.IO.Directory]::CreateDirectory("$logdir") | Out-Null
Start-Transcript -Path "$logdir\win_setup_$dateTime.log" -Append -NoClobber | Out-Null

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

# Enable Memory Core Isolation (Security)
$core_iso = Read-Host "Would you like to use VBS {Virtualization Based Security} (Y/N)"
if ($core_iso -eq "Y" -or $core_iso -eq "y")
{
    Write-Host "Setting up VBS" -ForegroundColor Green
    reg import .\Reg-Files\Enable_Mem_CoreISO.reg
}

# Disable UAC
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
# Enable LongPaths
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Value 1

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

# SSH
$ssh_setup = Read-Host "Would you like to setup ssh on the host? (Y/N)"
if ($ssh_setup -eq "Y" -or $ssh_setup -eq "y")
{
    New-Item -ItemType Directory $env:USERPROFILE\.ssh\
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    Get-Service ssh-agent
}

# Rename the PC
$currentName = (Get-ComputerInfo).CsName
Write-Host "The current computer name is: $currentName"
$changeName = Read-Host "Would you like to change the name of the computer? (y/n)"
if ($changeName -eq "Y" -or $changeName -eq "y")
{
    $newname = Read Host "Enter the new computer name"
    Rename-Computer -NewName $newname -Confirm -Restart
} else
{
    Write-Host "The system requires a reboot to continue setting up" -ForegroundColor Green
    Restart-Computer -Confirm
}
