#!/bin/bash
set -x

# Stop display manager
hyprctl dispatch exit
systemctl stop display-manager
# systemctl --user -M jake@ stop plasma*

# Stop Sunshine
systemctl --user stop sunshine.service

# Stop Ollama
systemctl stop ollama.service

# Stop Open-Webui
docker container stop open-webui

# Unbind VTconsoles: might not be needed
# echo 0 >/sys/class/vtconsole/vtcon0/bind
# echo 0 >/sys/class/vtconsole/vtcon1/bind

# Unbind EFI Framebuffer
# echo efi-framebuffer.0 >/sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload NVIDIA kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_0b_00_0
virsh nodedev-detach pci_0000_0b_00_1

# Load vfio module
modprobe vfio-pci
