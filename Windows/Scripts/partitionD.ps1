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

# Ensure D drive letter is not taken
Set-Partition -DriveLetter D -NewDriveLetter H
Get-Partition -DriveLetter C | Select-Object DiskNumber
Start-Sleep 3

# Create new drive partition from extra space on OS disk
Write-Warning "Drive D is about to be created from disk 0, is the information correct?" -WarningAction Inquire
New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter D | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Games"

# Create directories in new partition
Set-Location -LiteralPath D:
New-Item -ItemType Directory VM,Games,Code,WSL
Set-Location -LiteralPath D:\Games
New-Item -ItemType Directory Steam,EA,Blizzard,Emulator,Ubisoft
Set-Location -LiteralPath D:\Games\Emulator
New-Item -ItemType Directory Nintendo,Microsoft,Sony,Retroarch 
Set-Location -LiteralPath D:\Games\Emulator\Nintendo
New-Item -ItemType Directory Switch,'Wii U'
New-Item -ItemType Directory Switch\Titles
New-Item -ItemType Directory 'Wii U\Titles'
Set-Location -LiteralPath D:\Games\Emulator\Sony
New-Item -ItemType Directory 'Playstation 3','Playstation 2','Playstation 1'
New-Item -ItemType Directory 'Playstation 3\Titles'
New-Item -ItemType Directory 'Playstation 2\Titles'
New-Item -ItemType Directory 'Playstation 1\Titles'
Set-Location -LiteralPath D:\Games\Emulator\Retroarch
New-Item -ItemType Directory ROMS
Set-Location -LiteralPath D:\VM
New-Item -ItemType Directory VMware,ISO

# Move Game files to location 
robocopy /V /ETA /E Z:\Games\Nintendo\Switch\ D:\Games\Emulator\Nintendo\Switch\Titles\
robocopy /V /ETA /E 'Z:\Games\Nintendo\Wii U\BOTW' 'D:\Games\Emulator\Nintendo\Wii U\Titles\'
robocopy /V /ETA /E 'Z:\Games\Sony\Playstation 3\' 'D:\Games\Emulator\Sony\Playstation 3\Titles\'