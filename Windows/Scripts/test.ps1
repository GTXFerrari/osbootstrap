wget -O $env:USERPROFILE\Downloads\btop4winLHM.zip "https://github.com/aristocratos/btop4win/releases/download/v1.0.4/btop4win-LHM-x64.zip"
Expand-Archive -Path $env:USERPROFILE\Downloads\btop4winLHM.zip -DestinationPath $env:USERPROFILE\Downloads\btop4win
Move-Item -Path $env:USERPROFILE\Downloads\btop4win\btop4win\btop4win.exe -Destination $env:USERPROFILE\Downloads\btop4win\btop4win\btop.exe
Move-Item -Path $env:USERPROFILE\Downloads\btop4win\btop4win -Destination $env:PROGRAMFILES
# Add btop to PATH
$btop_path = "C:\Program Files\btop4win"
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$btop_path*")
{
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$btop_path", [System.EnvironmentVariableTarget]::User)
    Write-Host "btop added to user PATH."
} else
{
    Write-Host "Path already exists in the user PATH."
}
# Refresh env
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Process) + ";"
$env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) + ";"
$env:Path += [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
