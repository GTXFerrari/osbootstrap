# Variables
$NAS="\\10.0.40.5"
$sh=New-Object -com Shell.Application

Write-Warning "Please ensure this script is running as a normal user & not admin" -WarningAction Inquire

# Use 'net use' to map network drives & save credentials
Net Use Z: $NAS\Media /p:yes /savecred
Net Use Y: $NAS\Jake /p:yes /savecred
Net Use X: $NAS\LTS /p:yes /savecred
Net Use W: $NAS\MP /p:yes /savecred
Net Use V: $NAS\ISO /p:yes /savecred

# Rename network drives
$sh.NameSpace('Z:').Self.Name = 'Media'
$sh.NameSpace('Y:').Self.Name = 'Jake'
$sh.NameSpace('X:').Self.Name = 'LTS'
$sh.NameSpace('W:').Self.Name = 'MP'
$sh.NameSpace('V:').Self.Name = 'ISO'
