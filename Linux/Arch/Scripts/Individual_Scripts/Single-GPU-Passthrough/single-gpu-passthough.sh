#!/usr/bin/env bash

check_dependencies() {
  while true; do
    if pacman -Qi gum >/dev/null 2>&1; then
      break
    else
      pacman -S --noconfirm gum
    fi
  done
}

intro_banner() {
  sleep 1 | gum style \
    --foreground "#d49d82" --border-foreground "#82B8D4" --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'Single GPU Passthrough Helper Script'
}

create_vm() {
  os_choice=$(gum choose --header "Choose your OS" "Windows" "Linux")

}

create_hook_dirs() {
  vm_name=$(gum input --placeholder "Enter Your VM Name" --prompt Name:)
  if [[ ! -d /etc/libvirt/hooks ]]; then
    sudo mkdir -p /etc/libvirt/hooks
  fi
  sudo mkdir -p /etc/libvirt/hooks/qemu.d/"$vm_name"/{prepare,release}
  sudo mkdir -p /etc/libvirt/hooks/qemu.d/"$vm_name"/prepare/begin
  sudo mkdir -p /etc/libvirt/hooks/qemu.d/"$vm_name"/release/end
  export vm_name
}

setup_hooks() {
  sudo cp ./Files/qemu /etc/libvirt/hooks/ && sudo chmod +x /etc/libvirt/hooks/qemu
  sudo cp ./Files/start.sh /etc/libvirt/hooks/qemu.d/"$vm_name"/prepare/begin && sudo chmod +x /etc/libvirt/hooks/qemu.d/"$vm_name"/prepare/begin/start.sh
  sudo cp ./Files/stop.sh /etc/libvirt/hooks/qemu.d/"$vm_name"/release/end && sudo chmod +x /etc/libvirt/hooks/qemu.d/"$vm_name"/release/end/stop.sh
}

setup_roms() {
  if [[ ! -d /var/lib/libvirt/roms ]]; then
    sudo mkdir /var/lib/libvirt/roms
  fi
  sudo cp ./Files/4090_Patched.rom /var/lib/libvirt/roms/4090.rom
}

win11_setup() {
  preconfig_win11=$(gum choose --header "Would you like to setup the main Windows 11 gaming VM" --limit 1 "Yes" "No")
  if [[ $preconfig_win11 == "Yes" ]]; then
    sudo virsh define "/mnt/truenas/smb/backups/Virtual Machine/Libvirt/Win11/Win11.xml"
    sudo rsnyc -av --progress "/mnt/truenas/smb/backups/Virtual Machine/Libvirt/Win11/Windows11_25H2.img" /var/lib/libvirt/images/Windows11_25H2.img
    sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/Windows11_25H2.img && sudo chmod 600 /var/lib/libvirt/images/Windows11_25H2
  fi
}

# Function Calls
check_dependencies
intro_banner
create_hook_dirs
setup_hooks
setup_roms
win11_setup
