#!/usr/bin/env bash

# Colors
export NC='\033[0m' # No Color
export Black='\033[0;30m'
export Red='\033[0;31m'
export Green='\033[0;32m'
export Yellow='\033[0;33m'
export Blue='\033[0;34m'
export Purple='\033[0;35m'
export Cyan='\033[0;36m'
export White='\033[0;37m'

CHECK_IOMMU() {
  amdiommu="sudo dmesg | grep 'AMD IOMMUv2 loaded and initialized'"
  if [ -n "$amdiommu" ]; then
    echo -e "${Green}IOMMU is loaded & working.${NC}"
  else 
    echo -e "${Red}IOMMU is not loaded, check your UEFI/BIOS settings.${NC}"
  fi

}


CHECK_RESIZEABLEBARGPU() {
  nvidia_smi_output=$(nvidia-smi -q | grep "Resizable BAR")
  if [[ -n $nvidia_smi_output ]]; then
    echo -e "${Red}Reisizable BAR is enabled, disable it it the UEFI/BIOS for GPU Passthrough to work correctly.${NC}"
  else
    echo -e "${Green}Resizable BAR is not enabled, GPU Passthrough should function correctly.${NC}"
  fi
}

INSTALL_DEPS() {
  sudo pacman -S --needed qemu libvirt edk2-ovmf virt-manager dnsmasq iptables-nft
  sudo systemctl enable --now libvirtd
  sudo usermod -aG kvm,input,libvirt "$USER"
}

CREATE_HOOKS(){
  # QEMU Hook
  sudo mkdir /etc/libvirt/hooks
  sudo touch /etc/libvirt/hooks/qemu
  sudo chmod +x /etc/libvirt/hooks/qemu
  cat << 'EOF' > /etc/libvirt/hooks/qemu
  #!/bin/bash

  GUEST_NAME="$1"
  HOOK_NAME="$2"
  STATE_NAME="$3"
  MISC="${@:4}"

  BASEDIR="$(dirname "$0")"

  HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
  set -e # If a script exits with an error, we should as well.

  if [ -f "$HOOKPATH" ]; then
    eval "\"$HOOKPATH\"" "$@"
  elif [ -d "$HOOKPATH" ]; then
    while read -r file; do
      eval "\"$file\"" "$@"
    done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print)"
  fi
EOF

  # Start Script
  sudo mkdir -p /etc/libvirt/hooks/qemu.d/win11/prepare/begin
  sudo touch /etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
  sudo chmod +x /etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
  cat << 'EOF' > /etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh
#!/bin/bash
set -x

# Stop display manager
systemctl --user -M jake@ stop plasma*
systemctl stop display-manager

# Unbind VTconsoles: might not be needed
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload NVIDIA kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_01_00_0
virsh nodedev-detach pci_0000_01_00_1

# Load vfio module
modprobe vfio-pci
EOF

  sudo mkdir -p /etc/libvirt/hooks/qemu.d/win11/release/end
  sudo touch /etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh
  sudo chmod +x /etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh
  cat << 'EOF' > /etc/libvirt/hooks/qemu.d/win11/release/end/stop.sh
#!/bin/bash
set -x

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_01_00_0
virsh nodedev-reattach pci_0000_01_00_1

# Unload vfio module
modprobe -r vfio-pci

# Rebind framebuffer to host
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Bind VTconsoles: might not be needed
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
systemctl start display-manager
EOF
}

GPUROM(){
  sudo mkdir /var/lib/libvirt/gpurom
  sudo cp /mnt/truenas/jake/Linux/GPURom/4090patch.rom
}

# Call functions
CHECK_IOMMU
CHECK_RESIZEABLEBARGPU
INSTALL_DEPS
CREATE_HOOKS
GPUROM

