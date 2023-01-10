# Variables
$DL="$env:USERPROFILE\Downloads\"
# Install arch (WSL)
Set-Location $DL
New-Item -ItemType Directory -ErrorAction Ignore D:\WSL
curl -LOJs --no-clobber "https://github.com/yuk7/ArchWSL/releases/download/22.10.16.0/Arch.zip"
7z x *.zip -o*
Remove-Item -Path $DL\*.zip
Move-Item -Path $DL\Arch -Destination D:\WSL\
Set-Location D:\WSL\Arch
.\Arch.exe