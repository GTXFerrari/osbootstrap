#!/usr/bin/env bash

aur_log_file="/var/log/aur_failed_apps.log"
git_dir="/home/$USER//Git"
yay_dir="/home/$USER//Git/yay"

while true; do
  if pacman -Qi gum >/dev/null 2>&1; then
    break
  else
    sudo pacman -S --noconfirm gum git
  fi
done

sleep 5 | gum style \
  --foreground "#d49d82" --border-foreground "#82B8D4" --border double \
  --align center --width 50 --margin "1 2" --padding "2 4" \
  'Yay Install (AUR Helper)'

sleep 3 | gum style --foreground="#0099ff" "Checking if machine is in a VM"
VM_TYPE=$(systemd-detect-virt)
if [[ "$VM_TYPE" == "none" ]]; then
  VM_STATUS="not_in_vm"
elif [[ "$VM_TYPE" == "kvm" ]]; then
  VM_STATUS="kvm"
elif [[ "$VM_TYPE" == "vmware" ]]; then
  VM_STATUS="vmware"
else
  VM_STATUS="other"
fi

gum confirm "Would you like to setup an AUR helper?" || exit 0

if [ ! -d "$git_dir" ]; then
  mkdir -p "$git_dir" && cd "$git_dir" || exit
else
  cd "$git_dir" || exit
fi

if [[ $? -eq 0 ]]; then
  if [[ ! -d $yay_dir ]]; then
    cd "$git_dir" && git clone https://aur.archlinux.org/yay.git && cd "$yay_dir" && makepkg -si
  else
    sleep 3 | gum style --foreground="#0099ff" "Yay is already cloned.. Proceeding"
    cd "$yay_dir" && makepkg -si
  fi
fi

aur_programs=(
  timeshift-autosnap
  ookla-speedtest-bin
  piavpn-bin
  cava
  pistol-git
  zsh-fast-syntax-highlighting
  zsh-theme-powerlevel10k-git
  zsh-autosuggestions
)

#NOTE: openrgb-git is needed to control 4090FE LED light since the main repo release is extremely old
aur_gaming=(
  proton-ge-custom-bin
  dolphin-emu
  cemu
  duckstation-git
  pcsx2-git
  rpcs3-bin
  razergenie
  openrgb-git
)

if [[ $VM_STATUS == "not_in_vm" ]]; then
  for app in "${aur_programs[@]}"; do
    if ! yay -S --needed "$app"; then
      gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
      echo "$app" >>"$apps_log_file"
    fi
  done

  for app in "${aur_gaming[@]}"; do
    if yay -S --needed "$app"; then
      echo "Package not found: $app, skipping"
      echo "$app" | sudo tee -a "$aur_log_file"
    fi
  done
fi

for app in "${aur_programs[@]}"; do
  if yay -S --needed "$app"; then
    echo "Package not found: $app, skipping"
    echo "$app" | sudo tee -a "$aur_log_file"
  fi
done

if [[ $VM_STATUS == "not_in_vm" ]]; then
  sudo usermod -aG games "$USER"
fi

gum spin --spinner points --title "Enabling Services..." -- sudo systemctl enable --now piavpn.service
