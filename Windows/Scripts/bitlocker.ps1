# Variables
$Pin = ConvertTo-SecureString "ENTERPIN" -AsPlainText -Force

Write-Warning "This script will enable bitlocker on the C: drive (Requires Admin) The passwords should be set prior to the script running. TPM+PIN also requires a custom group policy. Would you like to proceed?" -WarningAction Inquire
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
Enable-BitLocker -MountPoint "C" -EncryptionMethod XtsAes256 -Pin $Pin -TpmAndPinProtector -Confirm # Requires a custom group policy to enable PIN
Restart-Computer -Confirm
