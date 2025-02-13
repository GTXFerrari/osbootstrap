# +-----------------------------------------------------------------------------------------------+
# |     ██╗    ██╗██╗███╗   ██╗        ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗          |
# |     ██║    ██║██║████╗  ██║        ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║          |
# |     ██║ █╗ ██║██║██╔██╗ ██║        ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║          |
# |     ██║███╗██║██║██║╚██╗██║        ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║          |
# |     ╚███╔███╔╝██║██║ ╚████║███████╗██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗     |
# |      ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝     |
# +-----------------------------------------------------------------------------------------------+

function logging
{
  $dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
  $logdir = "$Env:LOCALAPPDATA\win-setup\logs"
  [System.IO.Directory]::CreateDirectory("$logdir") | Out-Null
  Start-Transcript -Path "$logdir\win_setup_$dateTime.log" -Append -NoClobber | Out-Null
}

function check_psversion
{
  if ($PSVersionTable.PSVersion.Major -lt 7)
  {
    Write-Host "Powershell 7+ is required" -ForegroundColor Red
    Break
  }
}

function check_priv
{
  if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
  {
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
    Break
  }
}

function choco_install
{
  if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$Env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion))
  {
    Write-Output "Chocolatey Version $chocoVersion is already installed"
  } else
  {
    Write-Output "Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
    choco install amd-ryzen-chipset -y
    choco install nerd-fonts-jetbrainsmono -y
    choco install nerd-fonts-sourcecodepro -y
    choco install nerd-fonts-meslo -y
    choco install nerd-fonts-cascadiacode -y
  }
}

function wsl_setup
{
  $wsl_install = Read-Host "Would you like to install Windows Subsystem for Linux (WSL)? (Y/N)"
  if ($wsl_install -eq "Y" -or $wsl_install -eq "y")
  {
    Write-Host "Setting up WSL" -ForegroundColor Green
    wsl --install -d debian
    New-Item -Path $Env:USERPROFILE\.wslconfig
    #NOTE: Here-Strings dont work here since code formatting can add white spaces
    Add-Content -Path $Env:USERPROFILE\.wslconfig -Value "[wsl2]"
    Add-Content -Path $Env:USERPROFILE\.wslconfig -Value "networkingMode=mirrored"
    wsl --setdefault Debian
  }
}

function hyperv_setup
{
  $hyprv = Read-Host "Would you like to setup HyperV? (Y/N)"
  if ($hyprv -eq "Y" -or $hyprv -eq "y")
  {
    Write-Host "Setting up Hyper-V" -ForegroundColor Green
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  }
}

function vbs_setup
{
  $core_iso = Read-Host "Would you like to use VBS {Virtualization Based Security} (Y/N)"
  if ($core_iso -eq "Y" -or $core_iso -eq "y")
  {
    Write-Host "Setting up VBS" -ForegroundColor Green
    reg import .\Reg-Files\Enable_Mem_CoreISO.reg
  }
}


function system_tweaks
{
  # Disable UAC
  Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
  # Enable LongPaths
  Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Value 1
}

function power_options
{
  $power_settings = Read-Host "Would you like to set power options to high performance? (Y/N)"
  if ($power_settings -eq "Y" -or $power_settings -eq "y")
  {
    powercfg /S 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /x -hibernate-timeout-ac 0
    powercfg /x -hibernate-timeout-dc 0
    powercfg /x -disk-timeout-ac 0
    powercfg /x -disk-timeout-dc 0
    powercfg /x -monitor-timeout-ac 0
    powercfg /x -monitor-timeout-dc 0
    Powercfg /x -standby-timeout-ac 0
    powercfg /x -standby-timeout-dc 0
  }
}

function sshd_setup
{
  $ssh_setup = Read-Host "Would you like to setup ssh on the host? (Y/N)"
  if ($ssh_setup -eq "Y" -or $ssh_setup -eq "y")
  {
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    New-Item -ItemType Directory $Env:USERPROFILE\.ssh\
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
    # Put pub key in this file
    New-Item -ItemType "file" -Name "administrators_authorized_keys" -Path $Env:PROGRAMDATA\ssh
    icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
  }
}

function rename_pc
{
  $currentName = (Get-ComputerInfo).CsName
  Write-Host "The current computer name is: $currentName"
  $changeName = Read-Host "Would you like to change the name of the computer? (Y/N)"
  if ($changeName -eq "Y" -or $changeName -eq "y")
  {
    $newname = Read Host "Enter the new computer name"
    Rename-Computer -NewName $newname -Confirm -Restart
  } else
  {
    Write-Host "The system requires a reboot to continue setting up" -ForegroundColor Green
    Restart-Computer -Confirm
  }
}

function install_apps
{
  Write-Output "Installing Applications"
  $apps = @(
    @{name = "Git.Git" },
    @{name = "Neovim.Neovim" },
    @{name = "Starship.Starship" },
    @{name = "Microsoft.VCRedist.2015+.x86" },
    @{name = "Microsoft.VCRedist.2015+.x64" },
    @{name = "M2Team.NanaZip"},
    @{name = "Neovide.Neovide" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "GitHub.GitHubDesktop" },
    @{name = "AutoHotkey.AutoHotkey" },
    @{name = "Python.Python.3.12" },
    @{name = "OpenJS.NodeJS" },
    @{name = "Yarn.Yarn" },
    @{name = "BurntSushi.ripgrep.MSVC" },
    @{name = "sharkdp.fd" },
    @{name = "gsass1.NTop" },
    @{name = "WinSCP.WinSCP" },
    @{name = "Microsoft.PowerToys" },
    @{name = "BleachBit.BleachBit" },
    @{name = "CPUID.CPU-Z" },
    @{name = "TechPowerUp.GPU-Z" },
    @{name = "JAMSoftware.TreeSize.Free" },
    @{name = "Google.Chrome" },
    @{name = "Brave.Brave" },
    @{name = "Mozilla.Firefox" },
    @{name = "Zen-Team.Zen-Browser" },
    @{name = "TorProject.TorBrowser" },
    @{name = "PrivateInternetAccess.PrivateInternetAccess" },
    @{name = "Valve.Steam" },
    @{name = "SteamGridDB.RomManager" },
    @{name = "Playnite.Playnite" },
    @{name = "ElectronicArts.EADesktop" },
    @{name = "Ubisoft.Connect" },
    @{name = "PrismLauncher.PrismLauncher" },
    @{name = "Discord.Discord" },
    @{name = "PeterPawlowski.foobar2000" },
    @{name = "MPC-BE.MPC-BE" },
    @{name = "jurplel.qView" },
    @{name = "7zip.7zip" },
    @{name = "Dell.DisplayManager" },
    @{name = "WiresharkFoundation.Wireshark" },
    @{name = "FinalWire.AIDA64.Engineer" },
    @{name = "Flow-Launcher.Flow-Launcher" },
    @{name = "Insecure.Nmap" },
    @{name = "OBSProject.OBSStudio" },
    @{name = "HandBrake.HandBrake" },
    @{name = "Guru3D.Afterburner" },
    @{name = "Microsoft.DirectX" },
    @{name = "Plex.Plex" },
    @{name = "VirtualDesktop.Streamer" },
    @{name = "LizardByte.Sunshine" },
    @{name = "GeekUninstaller.GeekUninstaller" },
    @{name = "JernejSimoncic.Wget" },
    @{name = "JesseDuffield.lazygit" },
    @{name = "gokcehan.lf" },
    @{name = "9NBLGGH30XJ3" }, # Xbox Accessories
    @{name = "9PFHDD62MXS1" }, # Apple Music Preview
    @{name = "9N7F2SM5D1LR" } # HDR Calibration Tool
  );
  Foreach ($app in $apps)
  {
    $listApp = winget list --exact -q $app.name
    if (![String]::Join("", $listApp).Contains($app.name))
    {
      Write-host "Installing: " $app.name
      winget install -e --id $app.name 
    } else
    {
      Write-host "Skipping: " $app.name " (already installed)"
    }
  }
}

function install_graphics_driver
{
  $gpus = Get-CimInstance Win32_VideoController
  foreach ($gpu in $gpus)
  {
    if ($gpu.AdapterCompatibility -match "NVIDIA")
    {
      wget -O $Env:USERPROFILE\Downloads\NVApp.exe "https://us.download.nvidia.com/nvapp/client/10.0.2.210/NVIDIA_app_beta_v10.0.2.210.exe"
      Start-Process $Env:USERPROFILE\Downloads\NVApp.exe -Wait
    } elseif ($gpu.AdapterCompatibility -match "AMD" -or $gpu.AdapterCompatibility -match "Advanced Micro Devices")
    {
      wget -O $Env:USERPROFILE\Downloads\AMDAdrenaline.exe "https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-24.8.1-win10-win11-aug-rdna.exe"
      Start-Process $Env:USERPROFILE\Downloads\AMDAdrenaline.exe -Wait
      #NOTE: Need an AMD GPU to confirm is this is the correct string
    }
  }
}

function install_choco_apps
{
  choco install openrgb equalizerapo samsung-magician madvr bind-toolsonly mingw make lua luarocks mpvio -y
}



function install_non_pkgmgr_apps
{
  wget -O $Env:USERPROFILE\Downloads\PeaceSetup.exe https://sourceforge.net/projects/peace-equalizer-apo-extension/files/latest/download
  Start-Process $Env:USERPROFILE\Downloads\PeaceSetup.exe -Wait
  wget -O $Env:USERPROFILE\Downloads\Battle.net-setup.exe "https://downloader.battle.net//download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live"
  Start-Process $Env:USERPROFILE\Downloads\Battle.net-setup.exe -Wait
  wget -O $Env:USERPROFILE\Downloads\btop4winLHM.zip "https://github.com/aristocratos/btop4win/releases/download/v1.0.4/btop4win-LHM-x64.zip"
  Expand-Archive -Path $Env:USERPROFILE\Downloads\btop4winLHM.zip -DestinationPath $Env:USERPROFILE\Downloads\btop4win
  Move-Item -Path $Env:USERPROFILE\Downloads\btop4win\btop4win\btop4win.exe -Destination $Env:USERPROFILE\Downloads\btop4win\btop4win\btop.exe
  Move-Item -Path $Env:USERPROFILE\Downloads\btop4win\btop4win -Destination $Env:PROGRAMFILES
  $btop_path = "C:\Program Files\btop4win"
  $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
  if ($currentPath -notlike "*$btop_path*")
  {
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$btop_path", [System.EnvironmentVariableTarget]::User)
    Write-Host "btop added to user PATH."
  } else
  {
    Write-Host "Path already exists in the user PATH."
  }
}

function refreshenv
{
  $Env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Process) + ";"
  $Env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) + ";"
  $Env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
}

function cleanup
{
  Remove-Item -Force -Recurse $Env:USERPROFILE\Downloads\*.*
}

# Call functions
logging
check_psversion
check_priv
choco_install
wsl_setup
hyperv_setup
vbs_setup
system_tweaks
power_options
sshd_setup
install_apps
refreshenv
install_graphics_driver
install_choco_apps
install_non_pkgmgr_apps
rename_pc
cleanup
