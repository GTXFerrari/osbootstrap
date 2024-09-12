# +-----------------------------------------------------------------------------------------------+
# |     ██╗    ██╗██╗███╗   ██╗        ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗          |
# |     ██║    ██║██║████╗  ██║        ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║          |
# |     ██║ █╗ ██║██║██╔██╗ ██║        ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║          |
# |     ██║███╗██║██║██║╚██╗██║        ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║          |
# |     ╚███╔███╔╝██║██║ ╚████║███████╗██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗     |
# |      ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝     |
# +-----------------------------------------------------------------------------------------------+

function logging {
  $dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logdir = "$env:LOCALAPPDATA\win-setup\logs"
    [System.IO.Directory]::CreateDirectory("$logdir") | Out-Null
    Start-Transcript -Path "$logdir\win_setup_$dateTime.log" -Append -NoClobber | Out-Null
  }

function check_psversion {
  if ($PSVersionTable.PSVersion.Major -lt 7)
  {
    Write-Host "Powershell 7+ is required" -ForegroundColor Red
      Break
  }
}

function check_priv {
  if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
  {
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
      Break # TODO: Find a way to elevate the script using Start-Process
  }
  }

function smb_setup {
}

function check_choco {
  if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion))
  {
    Write-Output "Chocolatey Version $chocoVersion is already installed"
  } else
  {
    Write-Output "Chocolatey is not installed, installing now"
      Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
      powershell choco feature enable -n allowGlobalConfirmation
      choco install amd-ryzen-chipset -y
      choco install amd-ryzen-master -y
      choco install nerd-fonts-jetbrainsmono -y
      choco install nerd-fonts-sourcecodepro -y
      choco install nerd-fonts-meslo -y
      choco install nerd-fonts-cascadiacode -y
  }
}

function wsl_setup {
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
}

function hyperv_setup {
  $hyprv = Read-Host "Would you like to setup HyperV? (Y/N)"
    if ($hyprv -eq "Y" -or $hyprv -eq "y")
    {
      Write-Host "Setting up Hyper-V" -ForegroundColor Green
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
}

function vbs_setup {
  $core_iso = Read-Host "Would you like to use VBS {Virtualization Based Security} (Y/N)"
    if ($core_iso -eq "Y" -or $core_iso -eq "y")
    {
      Write-Host "Setting up VBS" -ForegroundColor Green
        reg import .\Reg-Files\Enable_Mem_CoreISO.reg
    }
  }


function system_tweaks {
# Disable UAC
  Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
# Enable LongPaths
  Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Value 1
}

function power_options {
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

function ssh_setup {
  $ssh_setup = Read-Host "Would you like to setup ssh on the host? (Y/N)"
    if ($ssh_setup -eq "Y" -or $ssh_setup -eq "y")
    {
        New-Item -ItemType Directory $env:USERPROFILE\.ssh\
        Get-Service ssh-agent | Set-Service -StartupType Automatic
        Start-Service ssh-agent
        Get-Service ssh-agent
    }
}

function rename_pc {
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

function datadrive_setup {

  }

function install_apps {
  Write-Output "Installing Applications"
    $apps = @(
        @{name = "Git.Git" },
        @{name = "Neovim.Neovim" },
        @{name = "JanDeDobbeleer.OhMyPosh" },
        @{name = "SomePythonThings.WingetUIStore" },
        @{name = "Microsoft.VCRedist.2015+.x86" },
        @{name = "Microsoft.VCRedist.2015+.x64" },
        @{name = "M2Team.NanaZip"},
        @{name = "Neovide.Neovide" },
        @{name = "Microsoft.VisualStudioCode" },
        @{name = "GitHub.GitHubDesktop" },
        @{name = "AutoHotkey.AutoHotkey" },
        @{name = "Python.Python.3.11" },
        @{name = "OpenJS.NodeJS" },
        @{name = "Yarn.Yarn" },
        @{name = "Oracle.JDK.22" },
        @{name = "BurntSushi.ripgrep.MSVC" },
        @{name = "sharkdp.fd" },
        @{name = "gsass1.NTop" },
        @{name = "WinSCP.WinSCP" },
        @{name = "Microsoft.PowerToys" },
        @{name = "BleachBit.BleachBit" },
        @{name = "CPUID.CPU-Z" },
        @{name = "TechPowerUp.GPU-Z" },
        @{name = "Notepad++.Notepad++" },
        @{name = "JAMSoftware.TreeSize.Free" },
        @{name = "Brave.Brave" },
        @{name = "Mozilla.Firefox" },
        @{name = "Zen-Team.Zen-Browser" },
        @{name = "Google.Chrome" },
        @{name = "TorProject.TorBrowser" },
        @{name = "PrivateInternetAccess.PrivateInternetAccess" },
        @{name = "Valve.Steam" },
        @{name = "ElectronicArts.EADesktop" },
        @{name = "Ubisoft.Connect" },
        @{name = "PrismLauncher.PrismLauncher" },
        @{name = "Playnite.Playnite" },
        @{name = "Discord.Discord" },
        @{name = "PeterPawlowski.foobar2000" },
        @{name = "MPC-BE.MPC-BE" },
        @{name = "DuongDieuPhap.ImageGlass" },
        @{name = "7zip.7zip" },
        @{name = "Dell.DisplayManager" },
        @{name = "LGUG2Z.komorebi" },
        @{name = "glzr-io.glazewm" },
        @{name = "WiresharkFoundation.Wireshark" },
        @{name = "FinalWire.AIDA64.Engineer" },
        @{name = "Flow-Launcher.Flow-Launcher" },
        @{name = "Insecure.Nmap" },
        @{name = "OBSProject.OBSStudio" },
        @{name = "HandBrake.HandBrake" },
        @{name = "AndreWiethoff.ExactAudioCopy" },
        @{name = "lencx.ChatGPT" },
        @{name = "Guru3D.Afterburner" },
        @{name = "Microsoft.DirectX" },
        @{name = "Plex.Plex" },
        @{name = "VirtualDesktop.Streamer" },
        @{name = "LizardByte.Sunshine" },
        @{name = "GeekUninstaller.GeekUninstaller" },
        @{name = "VMware.WorkstationPro" },
        @{name = "rocksdanister.LivelyWallpaper" },
        @{name = "JernejSimoncic.Wget" },
        @{name = "JesseDuffield.lazygit" },
        @{name = "gokcehan.lf" },
        @{name = "Google.PlatformTools" }, # ADB Installer for shield
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

  function graphics_driver {
    $gpus = Get-CimInstance Win32_VideoController
      foreach ($gpu in $gpus) {
        if ($gpu.AdapterCompatibility -match "NVIDIA") {
          wget -O $env:USERPROFILE\Downloads\NVApp.exe "https://us.download.nvidia.com/nvapp/client/10.0.2.210/NVIDIA_app_beta_v10.0.2.210.exe"
            Start-Process $env:USERPROFILE\Downloads\NVApp.exe -Wait
        }
        elseif ($gpu.AdapterCompatibility -match "AMD" -or $gpu.AdapterCompatibility -match "Advanced Micro Devices") {
          wget -O $env:USERPROFILE\Downloads\AMDAdrenaline.exe "https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-24.8.1-win10-win11-aug-rdna.exe"
            Start-Process $env:USERPROFILE\Downloads\AMDAdrenaline.exe -Wait
# NOTE: Need an AMD GPU to confirm is this is the correct string
        }
      }
  }

# Choco Apps
  choco install openrgb equalizerapo samsung-magician madvr bind-toolsonly mingw make lua luarocks -y
# Non-PkgMgr Apps
    wget -O $env:USERPROFILE\Downloads\PeaceSetup.exe https://sourceforge.net/projects/peace-equalizer-apo-extension/files/latest/download
    Start-Process $env:USERPROFILE\Downloads\PeaceSetup.exe -Wait
    wget -O $env:USERPROFILE\Downloads\Battle.net-setup.exe "https://downloader.battle.net//download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live"
    Start-Process $env:USERPROFILE\Downloads\Battle.net-setup.exe -Wait
    wget -O $env:USERPROFILE\Downloads\btop4winLHM.zip "https://github.com/aristocratos/btop4win/releases/download/v1.0.4/btop4win-LHM-x64.zip"
    Expand-Archive -Path $env:USERPROFILE\Downloads\btop4winLHM.zip -DestinationPath $env:USERPROFILE\Downloads\btop4win
    Move-Item -Path $env:USERPROFILE\Downloads\btop4win\btop4win\btop4win.exe -Destination $env:USERPROFILE\Downloads\btop4win\btop4win\btop.exe
    Move-Item -Path $env:USERPROFILE\Downloads\btop4win\btop4win -Destination $env:PROGRAMFILES
# Add btop to PATH
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
# Refresh env
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Process) + ";"
    $env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) + ";"
    $env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
# Clean up
    Remove-Item -Force -Recurse $env:USERPROFILE\Downloads\*.*
}

function enable_bitlocker {
# Enable Bitlocker Advanced Settings
  $fvePath = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft"
    if (-not (Test-Path $fvePath)) {
      New-ItemProperty -Path $fvePath -Name "FVE"
    }

    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name UseAdvancedStartup -Value 1
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name UseTPM -Value 2
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name UseTPMPIN -Value 2
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name EnableBDEWithNoTPM -Value 0
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name UseTPMKey -Value 0
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\FVE -Name UseTPMKeyPIN -Value 0
#TODO: DO NOT USE WIP
}

# Call functions
