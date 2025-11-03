#!/bin/bash
set -x

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_0b_00_0
virsh nodedev-reattach pci_0000_0b_00_1

# Unload vfio module
modprobe -r vfio-pci

# Rebind framebuffer to host
# echo "efi-framebuffer.0" >/sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Bind VTconsoles: might not be needed
# echo 1 >/sys/class/vtconsole/vtcon0/bind
# echo 1 >/sys/class/vtconsole/vtcon1/bind

# Start Ollama
systemctl start ollama.service

# Start Sunshine
systemctl --user start sunshine.service

# Start Open-Webui
docker container start open-webui

# Restart Display Manager
systemctl start display-manager
