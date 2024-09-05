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

# Parameters
$vmName = Read-Host "Enter the name of your virtual machine"
$vhdPath = "D:\VM\Hyper-V\Storage\$vmName.vhdx"
$switchName = "ExternalSwitch"
$networkAdapterName = "Ethernet 2"

# Select ISO Choice
$osChoice = Read-Host "Do you want to use Linux or Windows? (Use W for Windows or L for Linux)"


if ($osChoice -eq "L" -or $ocChoice -eq "l")
{
    $distroChoice = Read-Host "Choose your linux distro (Fedora,Debian,Arch)"
    
    switch ($distroChoice)
    {
        "Fedora"
        {
            $smb_iso = "\\10.0.40.5\ISO\Linux\Fedora-Workstation-Live-x86_64-40\Fedora-Workstation-Live-x86_64-40-1.14.iso"
            $iso = "D:\VM\ISO\Fedora-Workstation-Live-x86_64-40-1.14.iso"
        }
        "Debian"
        {
            $smb_iso = "\\10.0.40.5\ISO\Linux\debian-12.6.0-amd64-netinst.iso"
            $iso = "D:\VM\ISO\debian-11.1.0-amd64-netinst.iso"
        }
        "Arch"
        {
            $smb_iso = "\\10.0.40.5\ISO\Linux\archlinux-2024.08.01-x86_64.iso"
            $iso = "D:\VM\ISO\archlinux-2021.10.01-x86_64.iso"
        }
        default
        {
            Write-Host "Invalid choice, Select a valid distro"
            return
        }
    }
} elseif ($osChoice -eq "W" -or $ocChoice -eq "w")
{
    $smb_iso = "\\10.0.40.5\ISO\Microsoft\Win11_23H2_English_x64v2.iso"
    $iso = "D:\VM\ISO\Win11_23H2_English_x64v2.iso"
} else
{
    Write-Host "Invalid choice, Select W (Windows) or L (Linux)."
}

# Check if the ISO exists
if (-not (Test-Path $iso))
{
    Write-Host "$iso not found, Gathering required files..."
    Copy-Item -Recurse -Path $smb_iso -Destination $iso -Verbose
} else
{
    Write-Host "ISO already exists."
}

# Create a Virtual Switch if it doesn't already exist
if (-not (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue))
{
    New-VMSwitch -Name $switchName -NetAdapterName $networkAdapterName -AllowManagementOS $true
}

# Create a folder for the VM if it doesn't exist
$vmFolder = "D:\VM\Hyper-V\Virtual Machines"
if (-not (Test-Path -Path $vmFolder))
{
    New-Item -ItemType Directory -Path $vmFolder
}

if ($osChoice -eq "W" -or $osChoice -eq "w")
{
    $memoryStartupBytes = 4GB
    $vhdSizeBytes = 120GB
} elseif ($osChoice -eq "L" -or $osChoice -eq "l")
{
    $memoryStartupBytes = 1GB
    $vhdSizeBytes = 50GB
}

# Create a Virtual Hard Disk
New-VHD -Path $vhdPath -SizeBytes $vhdSizeBytes -Dynamic

# Create the Virtual Machine
New-VM -Name $vmName -MemoryStartupBytes $memoryStartupBytes -Generation 2 -BootDevice VHD -Path $vmFolder -SwitchName $switchName
Set-VMProcessor -VMName $vmName -Count 8

# TPM (Needed for windows 11 vm's)
if ($osChoice -eq "W" -or $osChoice -eq "w")
{
    Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
    Enable-VMTPM -VMName $vmName
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On
}

# Disable Secure Boot for linux guests
if ($osChoice -eq "L" -or $osChoice -eq "l")
{
    Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
}

# Add the Virtual Hard Disk to the Virtual Machine
Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

# Set the ISO file for installation
Add-VMDvdDrive -VMName $vmName
Set-VMDvdDrive -VMName $vmName -Path $iso
Set-VMFirmware -VMName $vmName -FirstBootDevice (Get-VMDvdDrive -VMName $vmName)

If ($osChoice -eq "W" -or $osChoice -eq "w")
{
    $gpuP = Read-Host "Would you like to share the host GPU with the windows guest? (Y/N)"
    if ($gpuP -eq "Y" -or $gpuP -eq "y")
    {
        Add-VMGPUPartitionAdapter -VMName $vmName
        Set-VMGPUPartitionAdapter -VMName $vmName -MinPartitionVRAM 50000000 -MaxPartitionVRAM 500000000 -OptimalPartitionVRAM 500000000 -MinPartitionEncode 50000000 -MaxPartitionEncode 500000000 -OptimalPartitionEncode 500000000 -MinPartitionDecode 50000000 -MaxPartitionDecode 500000000 -OptimalPartitionDecode 500000000 -MinPartitionCompute 50000000 -MaxPartitionCompute 500000000 -OptimalPartitionCompute 500000000
        Set-VM -GuestControlledCacheTypes $true -VMName $vmName
        Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vmName
        Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vmName
        Set-VM -Name $vmName -CheckpointType Disabled
        # if (-not (Test-Path -Path $env:USERPROFILE\Documents\HyperV-Temp))
        # {
        #     $tmpnv = "$env:USERPROFILE\Documents\HyperV\Nvidia\"
        #     New-Item -ItemType Directory -Path $tmpnv
        #     Copy-Item -Recurse $env:SYSTEMROOT\System32\DriverStore\FileRepository\nv_disp* -Destination $tmpnv
        #     (WIP)
        # }
    }
}

# Start the Virtual Machine
Start-VM -Name $vmName

Write-Host "Virtual machine '$vmName' created and started successfully." -ForegroundColor Green
