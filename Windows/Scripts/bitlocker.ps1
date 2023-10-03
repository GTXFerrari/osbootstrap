# Variables
$UsrPin = Read-Host -Prompt 'Input your bitlocker pin'
$UsrPass = Read-Host -Prompt 'Input your bitlocker password'
$Pin = ConvertTo-SecureString $UsrPin -AsPlainText -Force
$Pass = ConvertTo-SecureString $UsrPass -AsPlainText -Force

Write-Warning "This script will enable bitlocker on the OS Drive & a data drive with the mount point D:. TPM+PIN also requires a custom group policy. Would you like to proceed?" -WarningAction Inquire 
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

# Enable Bitlocker
Enable-BitLocker -MountPoint "C" -EncryptionMethod XtsAes256 -Pin $Pin -TpmAndPinProtector  # Requires a custom group policy to enable PIN
# Enable additional recovery keys
Add-BitLockerKeyProtector -MountPoint "C" -RecoveryPasswordProtector   # Store the generated recoverypassword in a safe location
manage-bde -protectors -get C: > '\\10.0.40.5\Jake\Backups\Bitlocker\Jakes-PC Bitlocker Recovery Codes\C_Drive\BLRecoveryKey.txt'
# Enable bitlocker for Data drives (D:)
#Enable-BitLocker -MountPoint "D:" -EncryptionMethod XtsAes256 -PasswordProtector -Password $Pass
#Enable-BitLockerAutoUnlock -MountPoint "D:"
Restart-Computer -Confirm
