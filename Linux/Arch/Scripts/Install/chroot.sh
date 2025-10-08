#!/usr/bin/env bash

init() {
  gum style --foreground="#00ff28" --bold "Setting Up Timezone"
  sleep 1
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  gum style --foreground="#00ff28" --bold "Syncing System Clock"
  sleep 1
  hwclock --systohc
  gum style --foreground="#00ff28" --bold "Updating Locales"
  sleep 1
  sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" >>/etc/locale.conf
  gum style --foreground="#00ff28" --bold "Enabling Multilib"
  sleep 1
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  pacman -Sy
  gum style --foreground="#00ff28" --bold "Updating Keyring"
  sleep 1
  pacman -S --noconfirm archlinux-keyring sudo
}

set_hostname() {
  hostname_choice=$(gum input --placeholder "Enter your hostname: ")
  echo "$hostname_choice" >>/etc/hostname
  {
    echo "127.0.0.1  localhost"
    echo "::1   localhost"
  } >>/etc/hosts
}

set_vconsole() {
  gum style --foreground="#00ff28" --bold "Setting up consolefont"
  sleep 1
  pacman -S --needed --noconfirm terminus-font
  if [[ "$VM_STATUS" == "bare_metal" ]]; then
    {
      echo "KEYMAP=us"
      echo "FONT=ter-132b"
    } >/etc/vconsole.conf
  else
    {
      echo "KEYMAP=us"
      echo "FONT=ter-124b"
    } >/etc/vconsole.conf
  fi
}

set_root_password() {
  root_pass=$(gum input --placeholder "Enter Your Root Password: ")
  echo root:"$root_pass" | chpasswd
}

create_user() {
  username=$(gum input --placeholder "Enter Your Username: ")
  useradd -m "$username"
  user_pass=$(gum input --placeholder "Enter Your User Password: ")
  echo "$username":"$user_pass" | chpasswd
  echo "$username ALL=(ALL) ALL" >>/etc/sudoers.d/"$username"
  export username
}

install_packages() {
  apps_log_file="/var/log/failed_apps.log"
  systemdservices_log_file="/var/log/failed_services.log"

  core_apps=(
    base-devel
    pacman-contrib
    networkmanager
    avahi
    mtools
    dosfstools
    exfatprogs
    bind
    cifs-utils
    cpupower
    i2c-tools
    iwd
    lm_sensors
    wireshark-qt
    syncthing
    nmap
    hashcat
    hashcat-utils
    hping
    tcpdump
    firefox
    firefoxpwa
    chromium
    handbrake
    handbrake-cli
    python
    python-pip
    python-virtualenv
    hugo
    tree-sitter
    go
    rustup
    luarocks
    nodejs
    npm
    jdk-openjdk
    wget
    curl
    gzip
    tar
    bash
    wl-clipboard
    ripgrep
    fd
    kitty
    ghostty
    openssh
    ssh-audit
    zsh
    zsh-autosuggestions
    zsh-completions
    git
    git-lfs
    rsync
    htop
    nvtop
    btop
    fastfetch
    lf
    atool
    highlight
    bat
    mediainfo
    ffmpegthumbnailer
    odt2txt
    cmatrix
    cowsay
    yt-dlp
    mpd
    ncmpcpp
    mpc
    mpv
    ttf-roboto-mono-nerd
    ttf-sourcecodepro-nerd
    ttf-terminus-nerd
    ttf-meslo-nerd
    ttf-mononoki-nerd
    ttf-nerd-fonts-symbols
    ttf-noto-nerd
    ttf-jetbrains-mono-nerd
    ttf-joypixels
    timeshift
    lazygit
    chezmoi
    tmux
    gimp
    ddcutil
    plymouth
    packer
    terraform
  )

  print=(
    cups
    cups-pdf
    hplip
  )

  systemd_services=(
    NetworkManager.service
    avahi-daemon.service
    reflector.service
    sshd.service
    systemd-timesyncd.service
    cups.service
    cpupower.service
  )

  gum style --foreground="#00ff28" --bold "Updating package database"
  if ! sudo pacman -Syu --noconfirm; then
    gum style --foreground="#ff0000" --bold "Failed to update package database"
  fi

  gum style --foreground="#00ff28" --bold "Installing packages"
  if [[ "$VM_STATUS" == "bare_metal" ]]; then

    for app in "${core_apps[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done

    for app in "${print[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done

    for service in "${systemd_services[@]}"; do
      if systemctl list-unit-files --type=service --all | grep -q "^$service"; then
        if ! systemctl enable "$service"; then
          gum style --foreground="#ff0000" --bold "Failed to enable service" | tee -a "$systemdservices_log_file"
        else
          gum style --foreground="#00ff28" --bold "$service successfully enabled"
        fi
      else
        gum style --foreground="#ff0000" --bold "Service $service does not exist" | tee -a $systemdservices_log_file
      fi
    done
    usermod -aG i2c "$username"
    usermod -aG wireshark "$username"
    usermod -aG input "$username"
    usermod -aG video "$username"

  else

    for app in "${core_apps[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        gum style --foreground="#ff0000" --bold "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done

    for service in "${systemd_services[@]}"; do
      if systemctl list-unit-files --type=service --all | grep -q "^$service"; then
        if ! systemctl enable "$service"; then
          gum style --foreground="#ff0000" --bold "Failed to enable service" | tee -a "$systemdservices_log_file"
        else
          gum style --foreground="#00ff28" --bold "$service successfully enabled"
        fi
      else
        gum style --foreground="#ff0000" --bold "Service $service does not exist" | tee -a $systemdservices_log_file
      fi
    done
    usermod -aG wireshark "$username"
  fi
  gum style --foreground="#00ff28" --bold "App installation complete"
  sleep 3
}

install_bootloader() {
  luksuuid=$(blkid -s UUID -o value /dev/"${partition_choice}${partition_suffix}"2)
  if [[ "$chosen_filesystem" == "Btrfs" ]]; then
    btrfs_options="rootflags=subvol=@"
  fi

  if [[ "$chosen_graphics" == "Nvidia" ]]; then
    nvidia_options="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
  fi

  if [[ "$encryption" == "Yes" ]]; then
    luks_options="cryptdevice=UUID=$luksuuid:cryptarch:allow-discards root=/dev/mapper/cryptarch"
  fi

  if [[ "$ucode" == "amd-ucode" ]]; then
    iommu_options="amd_iommu=on iommu=pt"
  elif [[ "$ucode" == "intel-ucode" ]]; then
    iommu_options="intel_iommu=on iommu=pt"
  else
    iommu_options=""
  fi

  if [[ "$ucode" == "amd-ucode" ]]; then
    initrd="/amd-ucode.img"
  elif [[ "$ucode" == "intel-ucode" ]]; then
    initrd="/intel-ucode.img"
  else
    initrd=""
  fi

  systemdboot_options="$luks_options $btrfs_options $iommu_options $nvidia_options"
  if [[ "$uefi" == "32" ]]; then
    gum style --foreground="#00ff28" --bold "Instalaling systemd-boot"
    sleep 2
    bootctl install
    touch /boot/loader/entries/arch.conf
    touch /boot/loader/entries/arch-zen.conf
    echo "title Arch Linux
linux /vmlinuz-linux
initrd $initrd
initrd /initramfs-linux.img
options $systemdboot_options rw" | tee -a /boot/loader/entries/arch.conf
    echo "title Arch Linux (Zen)
linux /vmlinuz-linux-zen
initrd $initrd
initrd /initramfs-linux-zen.img
options $systemdboot_options rw" | tee -a /boot/loader/entries/arch-zen.conf
  else
    while true; do
      PS3='Select a bootloader: '
      options=("Systemd-Boot" "GRUB")
      select opt in "${options[@]}"; do
        case $opt in
        "Systemd-Boot")
          echo -e "${Green}Installing systemd-boot${NC}"
          sleep 2
          bootctl install
          touch /boot/loader/entries/arch.conf
          touch /boot/loader/entries/arch-zen.conf
          echo
          "title Arch Linux
linux /vmlinuz-linux
initrd $initrd
initrd /initramfs-linux.img
options $systemdboot_options rw" >/boot/loader/entries/arch.conf
          echo "title Arch Linux (Zen)
linux /vmlinuz-linux-zen
initrd $initrd
initrd /initramfs-linux-zen.img
options $systemdboot_options rw" >/boot/loader/entries/arch-zen.conf
          break 2
          ;;
        "GRUB")
          grub_cmdline="loglevel 3 quiet $luks_options $btrfs_options $iommu_options $nvidia_options"
          escaped_grub_cmdline=$(printf '%s\n' "$grub_cmdline" | sed 's/[&/\]/\\&/g')
          grub_file="/etc/default/grub"
          if [[ "$chosen_filesystem" == "btrfs" ]]; then
            grub_btree="grub-btrfs"
          fi
          echo -e "${Green}Installing GRUB${NC}"
          sleep 2
          pacman -S grub efibootmgr os-prober $grub_btree
          sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$escaped_grub_cmdline\"/" "$grub_file"
          grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
          grub-mkconfig -o /boot/grub/grub.cfg
          break 2
          ;;
        *)
          echo -e "${Red}Invalid option, select a valid bootloader.${NC}"
          sleep 3
          ;;
        esac
      done
    done
  fi
}

setup_audio() {
  echo -e "${Green}Setting up audio${NC}"
  sleep 1
  audio=(
    pipewire
    lib32-pipewire
    pipewire-docs
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    alsa-utils
    alsa-plugins
    bluez
    bluez-utils
    lsp-plugins
    sof-firmware
  )
  for app in "${audio[@]}"; do
    if ! sudo pacman -S --needed --noconfirm "$app"; then
      echo "Package not found: $app, skipping"
      echo "$app" >>"$apps_log_file"
    fi
  done
  systemctl enable bluetooth.service
  #NOTE: Requires user input to overwrite
  pacman -S --needed pipewire-jack lib32-pipewire-jack
}

graphics_driver() {
  if [[ "$VM_STATUS" == "bare_metal" ]]; then
    graphics_driver=$(gum choose --limit=1 --header="Choose a graphics driver" "Nvidia" "AMD" "Intel")
    if [[ "$graphics_driver" == "Nvidia" ]]; then
      nvidia_packages=(
        nvidia-open-dkms
        nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        vulkan-icd-loader
        lib32-vulkan-icd-loader
        opencl-nvidia
        lib32-opencl-nvidia
        python-pytorch-cuda
        cuda
        libva-nvidia-driver
        libva-utils
        ollama-cuda
        vulkan-tools
      )
      for app in "${nvidia_packages[@]}"; do
        if ! pacman -S --needed --noconfirm "$app"; then
          gum style --foreground="#fc0303" --bold "App not found. Skipping.."
          echo "$app" >>"$apps_log_file"
        fi
      done
      chosen_graphics="Nvidia"
      export chosen_graphics
      return 0
    elif [[ "$graphics_driver" == "AMD" ]]; then
      amd_packages=(
        mesa
        lib32-mesa
        xf86-video-amdgpu
        vulkan-radeon
        lib32-vulkan-radeon
        libva-mesa-driver
        lib32-libva-mesa-driver
        mesa-vdpau
        lib32-mesa-vdpau
        rocm-opencl-runtime
      )
      for app in "${amd_packages[@]}"; do
        if ! pacman -S --needed --noconfirm "$app"; then
          gum style --foreground="#fc0303" --bold "App not found. Skipping.."
          echo "$app" >>"$apps_log_file"
        fi
      done
      chosen_graphics="AMD"
      export chosen_graphics
      return 0
    elif [[ "$graphics_driver" == "Intel" ]]; then
      intel_packages=(
        mesa
        lib32-mesa
        vulkan-intel
      )
      for app in "${intel_packages[@]}"; do
        if ! pacman -S --needed --noconfirm "$app"; then
          gum style --foreground="#fc0303" --bold "App not found. Skipping.."
          echo "$app" >>"$apps_log_file"
        fi
      done
      chosen_graphics="Intel"
      export chosen_graphics
      return 0
    fi
  fi
}

#NOTE: Move the condition to the for loop
install_gaming() {
  if [[ "$VM_STATUS" == "bare_metal" ]]; then
    gaming_packages=(
      steam
      ttf-liberation
      lutris
      discord
      retroarch
      retroarch-assets-xmb
      retroarch-assets-ozone
      libretro-core-info
      gamescope
      obs-studio
      mangohud
      goverlay
      prismlauncher
    )
    for app in "${gaming_packages[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        echo "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done
  else
    return 0
  fi
}

install_wine() {
  if [[ "$VM_STATUS" == "bare_metal" ]]; then
    wine_packages=(
      wine
      wine-gecko
      wine-mono
      lib32-pipewire
      pipewire-pulse
      lib32-libpulse
      lib32-gnutls
      lib32-sdl2
      lib32-gst-plugins-base
      lib32-gst-plugins-good
      samba
      winetricks
    )
    for app in "${wine_packages[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        echo "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done
  else
    return 0
  fi
}

setup_virtualization() {
  if [[ "$VM_STATUS" != "bare_metal" ]]; then
    echo -e "${Green}System is in a VM, skipping QEMU install${NC}"
    sleep 1
    return 0
  else
    virt_packages=(
      qemu-full
      virt-manager
      dmidecode
      edk2-ovmf
      dnsmasq
      openbsd-netcat
      bridge-utils
      vde2
      libvirt
      swtpm
    )
    for app in "${virt_packages[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        echo "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done
    systemctl enable libvirtd.service
    usermod -aG libvirt "$username"
    usermod -aG kvm "$username"
  fi
  #NOTE: Requires user input for overwrite
  pacman -S iptables-nft
}

docker_setup() {
  echo -n "Install docker? (y/n) "
  read -r docker
  if [[ "$docker" == "y" ]]; then
    pacman -S --needed --noconfirm docker docker-compose docker-buildx ducker
    systemctl enable docker.service
    usermod -aG docker "$username"
    if [[ ! -d /etc/docker ]]; then
      mkdir /etc/docker
    fi
    if [[ "$chosen_filesystem" == "Btrfs" ]]; then
      echo '{"storage-driver": "btrfs"}' >>/etc/docker/daemon.json
    fi
    if [[ "$chosen_graphics" == "Nvidia" ]]; then
      pacman -S --needed --noconfirm nvidia-container-toolkit
    fi
  fi
}

vm_check() {
  if [[ "$VM_STATUS" == "vmware" ]]; then
    vmware_packages=(
      open-vm-tools
      xf86-input-vmmouse
      xf86-video-vmware
      mesa
      gtkmm
      gtk2
    )
    for app in "${vmware_packages[@]}"; do
      if ! sudo pacman -S --needed --noconfirm "$app"; then
        echo "Package not found: $app, skipping"
        echo "$app" >>"$apps_log_file"
      fi
    done
    systemctl enable vmtoolsd.service
    systemctl enable vmware-vmblock-fuse.service
  elif [[ "$VM_STATUS" == "kvm" ]]; then
    pacman -S --needed --noconfirm qemu-guest-agent
    systemctl enable gemu-guest-agent
  else
    return 0
  fi
}

zramd_setup() {
  echo "zram" >/etc/modules-load.d/zram.conf
  echo "ACTION==\"add\", KERNEL==\"zram0\", ATTR{comp_algorithm}=\"zstd\", ATTR{disksize}=\"8G\", RUN=\"/usr/bin/mkswap -U clear /dev/%k\", TAG+=\"systemd\"" >/etc/udev/rules.d/99-zram.rules
  echo " " >>/etc/fstab
  echo "# ZRAMD" >>/etc/fstab
  echo "/dev/zram0 	none	swap	defaults,pri=100 0 0" >>/etc/fstab
}

desktop_environment() {
  while true; do
    echo -n "Install a desktop environment? (y/n) "
    read -r desktop_environment
    if [[ $desktop_environment == "y" ]]; then
      export desktop_environment
      PS3='Enter your choice: '
      options=("KDE" "Gnome" "Exit")
      select opt in "${options[@]}"; do
        case $opt in
        "KDE")
          kde_packages=(
            plasma-desktop
          )
          for app in "${kde_packages[@]}"; do
            if ! sudo pacman -S --needed --noconfirm "$app"; then
              echo "Package not found: $app, skipping"
              echo "$app" >>"$apps_log_file"
            fi
          done
          systemctl enable sddm
          break 2
          ;;
        "Gnome")
          pacman -S --needed \
            gnome \
            gnome-extra \
            gnome-tweaks \
            gnome-themes-extra \
            gdm
          systemctl enable gdm
          break 2
          ;;
        "Exit")
          break 2
          ;;
        *)
          echo -e "${Red}Invalid option, select a valid option.${NC}"
          ;;
        esac
      done
    else
      break 2
    fi
  done
}

setup_window_manager() {
  if [[ $desktop_environment = "y" ]]; then
    exit 0
  else
    while true; do
      echo -n "Install a tiling window manager (y/n) "
      read -r window_manager
      if [[ $window_manager == "y" ]]; then
        PS3='Enter your choice: '
        options=("Dwm" "Hyprland" "Exit")
        dwm_build="git clone https://github.com/GTXFerrari/dwm"
        dmenu_build="https://github.com/GTXFerrari/dmenu"
        dwmblocks_build="https://github.com/GTXFerrari/dwmblocks"
        git_dir="/home/$username/Git"
        select opt in "${options[@]}"; do
          case $opt in
          "Dwm")
            dwm_packages=(
              xorg-server
              xorg-xinit
              xorg-xsetroot
              scrot
              nitrogen
              blueman
              picom
              qt5ct
              qt6ct
              lxappearance
              gnome-themes-extra
              dunst
              polkit
              polkit-kde-agent
              gnome-keyring
              libsecret
              seahorse
              network-manager-applet
              unclutter
              cronie
              pasystray
              papirus-icon-theme
            )
            for app in "${dwm_packages[@]}"; do
              if ! sudo pacman -S --needed --noconfirm "$app"; then
                echo "Package not found: $app, skipping"
                echo "$app" >>"$apps_log_file"
              fi
            done
            # Check dirs & clone builds
            if [[ ! -d $git_dir ]]; then
              mkdir -p /home/"$username"/Git
            else
              echo -e "$Green Git directory already exists"
            fi

            if [[ ! -d $git_dir/dwm ]]; then
              $dwm_build
            else
              echo -e "$Green dwm folder already exists"
            fi

            if [[ ! -d $git_dir/dmenu ]]; then
              $dmenu_build
            else
              echo -e "$Green dmenu folder already exists"
            fi

            if [[ ! -d $git_dir/dmenu ]]; then
              $dwmblocks_build
            else
              echo -e "$Green dwmblocks folder already exists"
            fi

            # Build
            make "$git_dir"/dwm/ && sudo make clean install "$git_dir"/dwm/
            make "$git_dir"/dmenu/ && sudo make clean install "$git_dir"/dmenu/
            make "$git_dir"/dwmblocks/ && sudo make clean install "$git_dir"/dwmblocks/

            # Setup nitrogen wallpaper slideshow
            nitrogen_slideshow_cron="*/5 * * * * (export DISPLAY=:1.0 && /bin/date && /usr/bin/nitrogen --set-zoom-fill --random /home/$username/Pictures/Wallpapers/ --save) > /tmp/myNitrogen.log 2>&1"
            (crontab -l | grep -F "$nitrogen_slideshow_cron") || (
              crontab -l
              echo "$nitrogen_slideshow_cron"
            ) | crontab -
            ;;
          "Hyprland")
            hyprland_packages=(
              hyprland
              qt5-wayland
              qt6-wayland
              qt5ct
              qt6ct
              libva
              kitty
              xdg-desktop-portal-hyprland
              nwg-look
              polkit-kde-agent
              waybar
              wofi
              pavucontrol
              swaync
              gvfs-smb
            )
            for app in "${hyprland_packages[@]}"; do
              if ! sudo pacman -S --needed --noconfirm "$app"; then
                echo "Package not found: $app, skipping"
                echo "$app" >>"$apps_log_file"
              fi
            done
            ;;
          "Exit")
            break 2
            ;;
          *)
            echo "Invalid choice. Please enter a valid option."
            ;;
          esac
        done
      else
        break 2
      fi
    done
  fi
}

mkinitcpio_setup() {
  if [[ "$chosen_filesystem" == "btrfs" ]]; then
    btrfs_module="btrfs"
  else
    btrfs_module=""
  fi
  if [[ "$encryption" == "Yes" ]]; then
    encrypt_hook="encrypt"
  else
    encrypt_hook=""
  fi
  nvidia_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm $btrfs_module"
  kvm_modules="virtio virtio_blk virtio_pci virtio_net $btrfs_module"
  vmware_modules="vmw_balloon vmw_pvscsi vsock vmw_vsock_vmci_transport vmwgfx vmxnet3 $btrfs_module"
  hooks="base udev autodetect microcode modconf keyboard keymap consolefont plymouth block $encrypt_hook filesystems fsck"
  mkinitcpio_conf="/etc/mkinitcpio.conf"
  if [[ "$VM_STATUS" == "bare_metal" && "$chosen_graphics" == "Nvidia" ]]; then
    sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
    sed -i "/MODULES=(/ s/)/$nvidia_modules)/" "$mkinitcpio_conf"
    sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
    sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
  elif [[ "$VM_STATUS" == "kvm" ]]; then
    sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
    sed -i "/MODULES=(/ s/)/$kvm_modules)/" "$mkinitcpio_conf"
    sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
    sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
  elif [[ "$VM_STATUS" == "vmware" ]]; then
    sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
    sed -i "/MODULES=(/ s/)/$vmware_modules)/" "$mkinitcpio_conf"
    sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
    sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
  else
    sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
    sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
  fi
  mkinitcpio -P
  #TODO: Fix sed command so it does not replace all instances of HOOK & MODULE including commented lines
}

pacman_conf() {
  sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
  sed -i 's/^#Color/Color/' /etc/pacman.conf
  sed -i '/# Misc options/a ILoveCandy' /etc/pacman.conf
}

# TODO: Update DE Section, add systemctl start NetworkManager for plasma.

init
set_hostname
set_vconsole
set_root_password
create_user
install_packages
graphics_driver
setup_audio
install_gaming
install_wine
# install_bootloader
setup_virtualization
docker_setup
vm_check
# desktop_environment
# setup_window_manager
# mkinitcpio_setup
zramd_setup
pacman_conf
