Write-Warning "This script will install Chocolatey, Install nvidia & amd drivers, Set the power plan to high performance, disable pointer precision, & rename the PC (Requires Powershell 7+ & Admin) Would you like to proceed?" -WarningAction Inquire
# Check if running as ADMIN
Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
Break
}
else {
Write-Host "Code is running as administrator — go on executing the script..." -ForegroundColor Green
}

# Install Choco if not local
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {
    Write-Output "Chocolatey Version $chocoVersion is already installed"
}else {
    Write-Output "Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
}

# Install nvidia & amd drivers using choco
choco install nvidia-display-driver -y
choco install amd-ryzen-chipset -y

# Enable Memory Core Isolation (Security)
# reg import .\Reg-Files\Enable_Mem_CoreISO.reg

# Enable Dark Mode
#reg import .\Reg-Files\Enable_Dark_Mode.reg

# Disable UAC
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0

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

# Rename the PC
Rename-Computer -Confirm -NewName Jakes-PC -Restart