#!/usr/bin/env bash

aur_log_file="/var/log/aur_failed_apps.log"

dep_checks() {
  while true; do
    if pacman -Qi gum >/dev/null 2>&1; then
      break
    else
      sudo pacman -S --noconfirm gum git
    fi
  done
}

intro_banner() {
  sleep 5 | gum style \
    --foreground "#d49d82" --border-foreground "#82B8D4" --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'Yay Install (AUR Helper)'
}

vm_check() {
  sleep 3 | gum style --foreground="#0099ff" "Checking if machine is in a VM"
  VM_TYPE=$(systemd-detect-virt)
  if [[ "$VM_TYPE" == "none" ]]; then
    VM_STATUS="bare_metal"
  elif [[ "$VM_TYPE" == "kvm" ]]; then
    VM_STATUS="kvm"
  elif [[ "$VM_TYPE" == "vmware" ]]; then
    VM_STATUS="vmware"
  else
    VM_STATUS="other"
  fi

}

install_yay() {
  while true; do
    if pacman -Qi yay >/dev/null 2>&1; then
      break
    else
      gum confirm "Would you like to setup an AUR helper?" || exit 0
      sudo git clone https://aur.archlinux.org/yay.git /opt/yay && cd /opt/yay && makepkg -si || exit 1
    fi
  done
}

install_pkgs() {
  aur_programs=(
    ookla-speedtest-bin
    piavpn-bin
    cava
    pistol-bin
    zsh-fast-syntax-highlighting
    zen-browser-bin
    jdownloader2
    ttf-joypixels
  )

  #NOTE: openrgb-git is needed to control 4090FE LED light since the main repo release is extremely old
  aur_gaming=(
    proton-ge-custom-bin
    rpcs3-bin
    razergenie
    openrgb-git
  )

  if [[ $VM_STATUS == "bare_metal" ]]; then
    for app in "${aur_programs[@]}"; do
      if ! yay -S --needed "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" | sudo tee -a "$aur_log_file"
      fi
    done

    for app in "${aur_gaming[@]}"; do
      if yay -S --needed "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" | sudo tee -a "$aur_log_file"
      fi
    done

    for app in "${aur_programs[@]}"; do
      if yay -S --needed "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" | sudo tee -a "$aur_log_file"
      fi
    done

    # Recommended from proton-ge-custom-bin
    sudo usermod -aG game "$USER"
    gum spin --spinner dot --title "Enabling Services..." -- systemctl enable --now piavpn.service

  else
    for app in "${aur_programs[@]}"; do
      if yay -S --needed "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" | sudo tee -a "$aur_log_file"
      fi
    done
  fi
  gum spin --spinner dot --title "Enabling Services..." -- systemctl enable --now piavpn.service
}

dep_checks
vm_check
intro_banner
install_yay
install_pkgs
