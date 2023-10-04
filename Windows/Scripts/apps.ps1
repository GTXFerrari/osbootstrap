Start-Transcript -Append $env:USERPROFILE\Documents\apps.log
### Variables ###
$DL = "$env:USERPROFILE\Downloads"
$PF = "$env:ProgramFiles\"
$PF86 = "${env:ProgramFiles(x86)}\"

Write-Warning "This script will install applications on your machine (Requires Powershell 7+ & Admin) Would you like to proceed?" -WarningAction Inquire

# Check if running as ADMIN
Write-Output "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
Break
}
else {
Write-Output "Code is running as administrator - go on executing the script..."
}

# Install applications using winget
Write-Output "Installing Applications"
$apps = @(
    @{name = "M2Team.NanaZip"}
    @{name = "Git.Git" },
    @{name = "Neovim.Neovim" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "VMware.WorkstationPro" },
    @{name = "Python.Python.3.11" },
    @{name = "WinSCP.WinSCP" },
    @{name = "JanDeDobbeleer.OhMyPosh" },
    @{name = "Microsoft.PowerToys" },
    @{name = "BleachBit.BleachBit" },
    @{name = "CPUID.CPU-Z" },
    @{name = "TechPowerUp.GPU-Z" },
    @{name = "Notepad++.Notepad++" },
    @{name = "JAMSoftware.TreeSize.Free" },
    @{name = "Brave.Brave" },
    @{name = "PrivateInternetAccess.PrivateInternetAccess" },
    @{name = "Valve.Steam" },
    @{name = "ElectronicArts.EADesktop" },
    @{name = "Ubisoft.Connect" },
    @{name = "GorillaDevs.GDLauncher" },
    @{name = "Playnite.Playnite" },
    @{name = "Libretro.RetroArch" },
    @{name = "Microsoft.VCRedist.2015+.x86" },
    @{name = "Microsoft.VCRedist.2015+.x64" },
    @{name = "Discord.Discord" },
    @{name = "PeterPawlowski.foobar2000" },
    @{name = "MPC-BE.MPC-BE" },
    @{name = "jurplel.qView" },
    @{name = "Nextcloud.NextcloudDesktop" },
    @{name = "7zip.7zip" },
    @{name = "Dell.DisplayManager" }
    @{name = "evernote.evernote" }
    @{name = "WiresharkFoundation.Wireshark" },
    @{name = "FinalWire.AIDA64.Engineer" },
    @{name = "Flow-Launcher.Flow-Launcher" },
    @{name = "Insecure.Nmap" },
    @{name = "OBSProject.OBSStudio" },
    @{name = "9PF4KZ2VN4W9" }, # TranslucentTB
    @{name = "9NBLGGH30XJ3" }, # Xbox Accessories
    @{name = "9PFHDD62MXS1" } # Apple Music Preview
);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing: " $app.name
        winget install -e --id $app.name 
    }
    else {
        Write-host "Skipping: " $app.name " (already installed)"
    }
}

# Refresh PATH (PATH needs to be refreshed to enable Git & 7z)
Write-Output "Refreshing PATH"
$Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")  

# Download applications using choco
choco install openrgb -y
choco install equalizerapo -y
choco install geekuninstaller -y
choco install samsung-magician -y
choco install madvr -y
choco install bind-toolsonly -y
choco install zentimings -y
choco install msiafterburner -y
choco install sysinternals -y 

# Install fonts using choco
choco install cascadia-code-nerd-font -y 
choco install nerd-fonts-jetbrainsmono -y 
choco install nerd-fonts-sourcecodepro -y 

# Download applications that do not support winget or choco (Uses curl & Git)
Set-Location $DL
curl -LOJs --no-clobber 'https://sourceforge.net/projects/peace-equalizer-apo-extension/files/latest/download'
curl -LOJs --no-clobber 'https://www.battle.net/download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live&id=undefined'
curl -LOJs --no-clobber 'https://cemu.info/releases/cemu_1.26.2.zip'
curl -LOJs --no-clobber 'https://github.com/yuzu-emu/liftinstall/releases/download/1.8/yuzu_install.exe'
curl -LOJs --no-clobber 'https://github.com/stenzek/duckstation/releases/download/latest/duckstation-windows-x64-release.zip'
curl -LOJs --no-clobber 'https://github.com/PCSX2/pcsx2/releases/download/v1.7.3714/pcsx2-v1.7.3714-windows-64bit-AVX2-Qt.7z'
curl -LOJs --no-clobber 'https://github.com/RPCS3/rpcs3-binaries-win/releases/download/build-7e35679ec29472ac243ffd2c3c6733003fcfef57/rpcs3-v0.0.25-14476-7e35679e_win64.7z'

# Use Git to clone various repos
git clone 'https://github.com/Ottodix/Eole-foobar-theme.git'
git clone 'https://github.com/minischetti/metro-for-steam.git'
git clone 'https://github.com/redsigma/UPMetroSkin.git'

# Unzip archives and remove them (Requires 7zip cli tool)
Write-Output "Extracting Files"
Set-Location $DL
7z x *.zip -o*
7z x *.7z -o*
Remove-Item  -Path $DL\*.zip
Remove-Item  -Path $DL\*.7z

# Move files to desired location
Write-Output "Moving Files"
Copy-Item -Recurse -Force -Path $DL\pcsx2-* -Destination $PF
Copy-Item -Recurse -Force -Path $DL\rpcs3-* -Destination $PF
Copy-Item -Recurse -Force -Path $DL\duckstation-* -Destination $PF
Copy-Item -Recurse -Force -Path $DL\cemu_*\cemu_* -Destination $PF
Copy-Item -Recurse -Force -Path "$DL\UPMetroSkin\Unofficial 4.x Patch\Main Files [Install First]\*" -Destination $DL\metro-for-steam\
New-Item -Path $PF86\Steam\ -Name "skins" -ItemType "directory"
Copy-Item -Recurse -Force -Path $DL\metro-for-steam -Destination $PF86\Steam\skins\
& $PF86\foobar2000\foobar2000.exe | Out-Null # Launch foobar once to create config folder in APPDATA
Copy-Item -Recurse -Force -Path $DL\Eole-foobar-theme\* -Destination $env:APPDATA\foobar2000\ 

# Run app installers
Write-Output "Running app installers"
Set-Location $DL
.\Battle.net-Setup.exe | Out-Null
.\yuzu_install.exe | Out-Null
.\PeaceSetup.exe | Out-Null

# Clean Up
Write-Output "Cleaning Up"
Remove-Item -Recurse -Force $DL\* 
Move-Item -Path $PF\cemu_* -Destination $PF\Cemu 
Move-Item -Path $PF\duckstation-* -Destination $PF\Duckstation
Move-Item -Path $PF\pcsx2* -Destination $PF\PCSX2 
Move-Item -Path $PF\rpcs3* -Destination $PF\RPCS3
