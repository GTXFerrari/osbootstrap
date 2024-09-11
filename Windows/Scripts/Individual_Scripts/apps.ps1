# Logging
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logdir = "$env:LOCALAPPDATA\win-setup\logs"
[System.IO.Directory]::CreateDirectory("$logdir") | Out-Null
Start-Transcript -Path "$logdir\win_setup_$dateTime.log" -Append -NoClobber | Out-Null

# Check powershell version
if ($PSVersionTable.PSVersion.Major -lt 7)
{
    Write-Host "Powershell 7+ is required" -ForegroundColor Red
}

# Check if running as ADMIN
Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
    Break
}

# Install applications using winget
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
    @{name = "Python.Python.3.12" },
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
    @{name = "Dell.DisplayManager" }
    @{name = "LGUG2Z.komorebi" }
    @{name = "glzr-io.glazewm" }
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
    @{name = "Google.PlatformTools" }, # ADB Installer for shield
    @{name = "gokcehan.lf" }, # ADB Installer for shield
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

# Download applications using choco
choco install openrgb -y
choco install equalizerapo -y
choco install samsung-magician -y
choco install madvr -y
choco install bind-toolsonly -y
choco install mingw -y # C compiler for windows (required for nvim-treesitter)
choco install lua
choco install luarocks

# Non-PkgMgr Apps
wget -O $env:USERPROFILE\Downloads\PeaceSetup.exe https://sourceforge.net/projects/peace-equalizer-apo-extension/files/latest/download
Start-Process $env:USERPROFILE\Downloads\PeaceSetup.exe -Wait
wget -O $env:USERPROFILE\Downloads\Battle.net-setup.exe "https://downloader.battle.net//download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live"
Start-Process $env:USERPROFILE\Downloads\Battle.net-setup.exe -Wait
wget -O $env:USERPROFILE\Downloads\NVApp.exe "https://us.download.nvidia.com/nvapp/client/10.0.2.210/NVIDIA_app_beta_v10.0.2.210.exe"
Start-Process $env:USERPROFILE\Downloads\NVApp.exe -Wait
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
