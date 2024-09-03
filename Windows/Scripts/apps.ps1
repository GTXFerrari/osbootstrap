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
    @{name = "GitHub.GitHubDesktop" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "Python.Python.3.12" },
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
    @{name = "Google.Chrome" },
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
choco install mingw # C compiler for windows (required for nvim-treesitter)

