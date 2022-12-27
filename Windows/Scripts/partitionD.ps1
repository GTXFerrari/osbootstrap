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
Get-Partition -DriveLetter C | Select DiskNumber
Start-Sleep 3
# Create new drive partition from extra space on OS disk
Write-Warning "Drive D is about to be created from disk 0, is the information correct?" -WarningAction Inquire
New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter D | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Games"