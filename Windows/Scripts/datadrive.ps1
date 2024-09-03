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

# Bitlocker for data drive
$UsrPass = Read-Host -Prompt 'Input your bitlocker password'
$Pass = ConvertTo-SecureString $UsrPass -AsPlainText -Force

# Ensure D drive letter is not taken
Set-Partition -DriveLetter D -NewDriveLetter H
Get-Partition -DriveLetter C | Select-Object DiskNumber
Start-Sleep 3

# Create new drive partition from extra space on OS disk
Write-Warning "Drive D is about to be created from disk 0, is the information correct?" -WarningAction Inquire
$cDriveDiskNumber = (Get-Partition -DriveLetter C).DiskNumber
New-Partition -DiskNumber $cDriveDiskNumber -UseMaximumSize -DriveLetter D | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data"

# Create directories in new partition
Set-Location -LiteralPath D:
New-Item -ItemType Directory Code,Games,Git,Pictures,VM
Set-Location -LiteralPath D:\Games
New-Item -ItemType Directory Blizzard,EA,Emulator,Steam,Ubisoft
Set-Location -LiteralPath D:\VM
New-Item -ItemType Directory VMware,ISO

# Move Game files to destination
robocopy /V /ETA /E '\\10.0.40.5\Media\Games\Emulator\' 'D:\Games\Emulator\'

# Enable bitlocker for Data drives (D:)
Enable-BitLocker -MountPoint "D:" -EncryptionMethod XtsAes256 -PasswordProtector -Password $Pass
Enable-BitLockerAutoUnlock -MountPoint "D:"

Restart-Computer -Confirm
