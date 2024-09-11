# Variables
$NAS="\\10.0.40.5"
$sh=New-Object -com Shell.Application

Write-Warning "Please ensure this script is running as a normal user & not admin" -WarningAction Inquire

# Use 'net use' to map network drives & save credentials
Net Use Z: $NAS\Media /p:yes /savecred
Net Use Y: $NAS\Jake /p:yes /savecred
Net Use X: $NAS\Stash /p:yes /savecred
Net Use W: $NAS\Stash2 /p:yes /savecred
Net Use V: $NAS\Gold /p:yes /savecred
Net Use U: $NAS\ISO /p:yes /savecred
Net Use T: $NAS\Photos /p:yes /savecred

# Rename network drives
$sh.NameSpace('Z:').Self.Name = 'Media'
$sh.NameSpace('Y:').Self.Name = 'Jake'
$sh.NameSpace('X:').Self.Name = 'Stash'
$sh.NameSpace('W:').Self.Name = 'Stash2'
$sh.NameSpace('V:').Self.Name = 'Gold'
$sh.NameSpace('U:').Self.Name = 'ISO'
$sh.NameSpace('T:').Self.Name = 'Photos'

# Wallpapers
New-Item -ItemType Directory $env:USERPROFILE\Pictures\Wallpapers
robocopy /V /ETA /E \\10.0.40.5\Jake\Assets\Wallpapers\3440x1440 $env:USERPROFILE\Pictures\Wallpapers\

# Powershell
Install-Module PSWindowsUpdate
Install-Module -Name Terminal-Icons -Repository PSGallery
Install-Script winfetch
Copy-Item \\10.0.40.5\Jake\Backups\Powershell\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\PowerShell\
