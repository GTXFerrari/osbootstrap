#!/usr/bin/env bash

singlegpu_passthrough() {
  hooks_dir="/etc/libvirt/hooks"
  hooks_qemu_file="/etc/libvirt/hooks/qemu"
  qemu_start_dir="/etc/libvirt/hooks/qemu.d/win11/prepare/begin"
  qemu_start_file="/etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh"
  qemu_stop_dir="/etc/libvirt/hooks/qemu.d/win11/release/end"
  qemu_stop_file="/etc/libvirt/hooks/qemu.d/win11/end/stop.sh"
  if [[ "$chosen_graphics" != "Nvidia" ]]; then
    echo -e "${Green}Single GPU passthrough is only supported for NVIDIA${NC}"
    sleep 1
    return 0
  else
    virsh net-start default
    virsh net-autostart default
    mkdir -p $hooks_dir
    touch $hooks_qemu_file
    chmod +x $hooks_qemu_file
    mkdir -p $qemu_start_dir
    touch $qemu_start_file
    mkdir -p $qemu_stop_dir
    touch $qemu_stop_file

    cat > "$hooks_qemu_file" << 'EOF'
    #!/usr/bin/env bash

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"
    MISC="${@:4}"

    BASEDIR="$(dirname $0)"

    HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
    set -e # If a script exits with an error, we should as well.

    if [ -f "$HOOKPATH" ]; then
      eval "\"$HOOKPATH\"" "$@"
    elif [ -d "$HOOKPATH" ]; then
      while read file; do
	eval "\"$file\"" "$@"
      done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
    fi
EOF


    cat > "$qemu_start_file" << EOF
    #!/usr/bin/env bash

    set -x

# Stop display manager
systemctl stop display-manager
systemctl --user -M $username@ stop plasma*

# Unbind VTconsoles: might not be needed
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload GPU kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia


# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_01_00_0
virsh nodedev-detach pci_0000_01_00_1

# Load vfio module
modprobe vfio-pci
EOF

cat > "$qemu_stop_file" << EOF
#!/usr/bin/env bash

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
    fi

}

singlegpu_passthrough
