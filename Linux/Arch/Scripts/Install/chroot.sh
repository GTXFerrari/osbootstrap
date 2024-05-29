#!/usr/bin/env bash

init() {
  echo -e "${Green}Setting timezone.${NC}"
  sleep 1
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  echo -e "${Green}Syncing system clock.${NC}"
  sleep 1
  hwclock --systohc
  echo -e "${Green}Updating locales${NC}"
  sleep 1
  sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  echo -e "${Green}Enabling multilib.${NC}"
  sleep 1
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  echo -e "${Green}Updating mirrorlist.${NC}"
  reflector -c 'United States' -a 12 -p https --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Sy
  echo -e "${Green}Updating keyring.${NC}"
  sleep 1
  pacman -S --noconfirm archlinux-keyring sudo
}

set_hostname() {
  echo -n "Enter a value for hostname: "
  read -r hostname
  echo "$hostname" >>/etc/hostname
  {   echo "127.0.0.1  localhost"
      echo "::1   localhost"
  } >> /etc/hosts
}

set_vconsole() {
  if [[ "$VM_STATUS" == "none" ]]; then
    {  echo "KEYMAP=us"
      echo "FONT=ter-132b"
    } > /etc/vconsole.conf
  else
    {  echo "KEYMAP=us"
      echo "FONT=ter-124b"
    } > /etc/vconsole.conf
  fi
}

set_root_password() {
  echo -n "Enter a value for the root password: "
  read -r password
  echo root:"$password" | chpasswd
}

install_core_packages() {
  pacman -S --needed \
    base-devel \
    networkmanager \
    nm-connection-editor \
    iwd \
    avahi \
    bind \
    cifs-utils \
    pacman-contrib \
    xdg-user-dirs \
    xdg-utils \
    udisks2 \
    exfatprogs \
    mtools \
    dosfstools \
    cups \
    cups-pdf \
    hplip \
    alacritty \
    kitty \
    arch-install-scripts \
    rsync \
    openssh \
    ssh-audit \
    zsh \
    zsh-completions \
    zsh-autosuggestions \
    neofetch \
    fastfetch \
    htop \
    nvtop \
    btop \
    cmatrix \
    wireshark-qt \
    mpd \
    mpc \
    mpv \
    ncmpcpp \
    nerd-fonts \
    ttf-joypixels \
    lf \
    chafa \
    lynx \
    ueberzug \
    atool \
    highlight \
    bat \
    mediainfo \
    ffmpegthumbnailer \
    odt2txt \
    zathura \
    firefox \
    chromium \
    hugo \
    terminus-font \
    python \
    python-pip \
    python-virtualenv \
    openrgb

  systemctl enable \
    NetworkManager.service \
    avahi-daemon.service \
    iwd.service \
    cups.socket \
    reflector.timer \
    sshd.service \
    fstrim.timer \
    systemd-timesyncd.service \
}

create_user() {
  echo -n "Enter a username: "
  read -r username
  useradd -m "$username"
  echo -n "Enter a password: "
  read -r password
  echo "$username":"$password" | chpasswd
  echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/"$username"
  usermod -aG wireshark,input,video jake
}

install_bootloader() {
  while true; do
    PS3='Select a bootloader: '
    options=("GRUB" "Systemd-Boot")
    select opt in "${options[@]}"; do
      case $opt in
        "GRUB")
          pacman -S --needed --noconfirm grub efibootmgr os-prober sbctl
          grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
          grub-mkconfig -o /boot/grub/grub.cfg
          break 2
          ;;
          "Systemd-Boot")
          luksuuid=$(blkid -s UUID -o value /dev/${partition_choice}${partition_suffix}2)
          echo "Installing Bootloader"
          bootctl install
          touch /boot/loader/entries/arch.conf
          touch /boot/loader/entries/arch-zen.conf
          echo "title Arch Linux
          linux /vmlinuz-linux
          initrd /amd-ucode.img
          initrd /initramfs-linux.img
          options cryptdevice=UUID=$luksuuid:luks:allow-discards root=/dev/mapper/luks rootflags=subvol=@ rd.luks.options=discard nvidia_drm.modeset=1 amd_iommu=on rw" > /boot/loader/entries/arch.conf
          echo "title Arch Linux (Zen)
          linux /vmlinuz-linux-zen
          initrd /amd-ucode.img
          initrd /initramfs-linux-zen.img
          options cryptdevice=UUID=$luksuuid:luks:allow-discards root=/dev/mapper/luks rootflags=subvol=@ rd.luks.options=discard nvidia_drm.modeset=1 amd_iommu=on rw" > /boot/loader/entries/arch-zen.conf
          break 2
          ;;
        *)
          echo -e "${Red}Invalid option, select a valid bootloader.${NC}"
          ;;
      esac
    done
  done
}

install_audio() {
  echo -e "${Green}Installing audio${NC}"
  sleep 1
  pacman -S --needed \
    pipewire \
    pipewire-docs \
    pipewire-alsa \
    lib32-pipewire \
    easyeffects \
    alsa-utils \
    alsa-plugins \
    pipewire-pulse \
    wireplumber \
    pipewire-jack \
    lib32-pipewire-jack \
    pulsemixer \
    bluez \
    bluez-utils \
    lsp-plugins \
    sof-firmware
  systemctl enable bluetooth.service
}

install_graphics() {
  local chosen_graphics=""
  if [[ "$VM_STATUS" != "none" ]]; then
    echo -e "${Green}System is in a VM, no graphics driver required${NC}"
    sleep 1
    return 0
  fi
    while true; do
      PS3='Select a graphics driver: '
      options=("Nvidia" "AMD" "Intel" "Exit")
      select opt in "${options[@]}"; do
        case $opt in
          "Nvidia")
            pacman -S --needed nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader opencl-nvidia lib32-opencl-nvidia python-pytorch-cuda cuda
            chosen_graphics="Nvidia"
            break 2
            ;;
          "AMD")
            pacman -S --needed mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau rocm-opencl-runtime
            chosen_graphics="AMD"
            break 2
            ;;
          "Intel")
            pacman -S --needed mesa lib32-mesa vulkan-intel
            chosen_graphics="Intel"
            break 2
            ;;
          "Exit")
            break 2
            ;;
          *)
            echo "Invalid choice. Please enter a valid option."
            ;;
        esac
      done
    done
export chosen_graphics
}

install_gaming() {
  if [[ "$VM_STATUS" == "none" ]]; then
    pacman -S --needed \
      steam \
      lutris \
      discord \
      retroarch \
      retroarch-assets-xmb \
      retroarch-assets-ozone \
      libretro-core-info \
      gamescope \
      obs-studio \
      mangohud \
      goverlay
        else
          return 0
  fi
}

install_wine() {
  if [[ "$VM_STATUS" == "none" ]]; then
    pacman -S --needed \
      wine-staging \
      wine-gecko \
      wine-mono \
      pipewire-pulse \
      lib32-libpulse \
      lib32-alsa-oss \
      lib32-gnutls \
      lib32-gst-plugins-base \
      lib32-gst-plugins-good \
      samba \
      winetricks \
      zenity
        else
          return 0
  fi
}

install_virtualization() {
  if [[ "$VM_STATUS" != "none" ]]; then
    echo -e "${Green}System is in a VM, skipping${NC}"
    sleep 1
    return 0
  else
    pacman -S --needed \
      qemu-full \
      virt-manager \
      dmidecode \
      edk2-ovmf \
      iptables-nft \
      dnsmasq \
      openbsd-netcat \
      bridge-utils \
      vde2 \
      libvirt \
      swtpm \
      docker \
      docker-compose

    systemctl enable docker.service libvirtd.service
    usermod -aG libvirt,docker jake

    if [[ ! -d /etc/docker ]]; then
      mkdir /etc/docker
    fi
    if [[ "chosen_filesystem" == "btrfs" ]]; then
      echo '{"storage-driver": "btrfs"}' >> /etc/docker/daemon.json
    fi
  fi
}

vm_check() {
  if [[ "$VM_STATUS" == "vmware" ]]; then
    pacman -S --needed --noconfirm open-vm-tools xf86-input-vmmouse xf86-video-vmware  mesa gtkmm gtk2
    systemctl enable vmtoolsd.service vmware-vmblock-fuse.service
  elif [[ "$VM_STATUS" == "kvm" ]]; then
    pacman -S --needed --noconfirm qemu-guest-agent
    systemctl enable gemu-guest-agent
  else
    return 0
  fi
}

zramd_setup() {
  echo "zram" > /etc/modules-load.d/zram.conf
  echo "ACTION==\"add\", KERNEL==\"zram0\", ATTR{comp_algorithm}=\"zstd\", ATTR{disksize}=\"8G\", RUN=\"/usr/bin/mkswap -U clear /dev/%k\", TAG+=\"systemd\"" > /etc/udev/rules.d/99-zram.rules
  echo " " >> /etc/fstab
  echo "# ZRAMD" >> /etc/fstab
  echo "/dev/zram0 	none	swap	defaults,pri=100 0 0" >> /etc/fstab
}

desktop_environment() {
  while true; do
  echo -n "Would you like to install a desktop environment (y/n) "
  read -r desktop_environment 
  if [[ $desktop_environment == "y" ]]; then
    PS3='Please enter your choice: '
    options=("KDE" "Gnome" "Cinnamon" "Xfce" "Budgie" "Exit")
    select opt in "${options[@]}"
    do
      case $opt in
        "KDE")
          pacman -S --needed \
            xorg \
            plasma \
            kde-applications \
            plasma-nm \
            packagekit-qt5 \
            sddm \
            qt5-wayland \
            qt6-wayland
          systemctl enable sddm
          break 2
          ;;
        "Gnome")
          pacman -S --needed \
            xorg \
            gnome \
            gnome-extra \
            gnome-tweaks \
            gnome-themes-extra \
            gdm
          systemctl enable gdm.service
          break 2
          ;;
        "Cinnamon")
          pacman -S --needed \
            xorg \
            cinnamon \
            xed \
            xreader \
            metacity \
            gnome-shell \
            gnome-keyring \
            libsecret \
            seahorse \
            system-config-printer \
            blueberry \
            gnome-screenshot \
            gdm
          systemctl enable gdm.service
          break 2
          ;;
        "Xfce")
          pacman -S --needed \
            xorg \
            xfce4 \
            xfce4-goodies \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter
          systemctl enable lightdm.service
          break 2 
          ;;
        "Budgie")
          pacman -S --needed \
            xorg \
            budgie-desktop \
            budgie-desktop-view \
            budgie-extras \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter
          systemctl enable lightdm.service
          break 2
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
}

window_manager() {
  while true; do
  echo -n "Would you like to install a tiling window manager (y/n) "
  read -r window_manager 
  if [[ $window_manager == "y" ]]; then
    PS3='Please enter your choice: '
    options=("Dwm" "Bspwm" "Awesome" "i3" "Xmonad" "Exit")
    dir="/home/jake/Git"
    dwm="/home/jake/Git/dwm"
    dmenu="/home/jake/Git/dmenu"
    st="/home/jake/Git/st"
    dwmblocks="/home/jake/Git/dwmblocks"
    git="git clone https://github.com/gtxferrari"
    select opt in "${options[@]}"
    do
      case $opt in 
        "Dwm")
          pacman -S --needed xorg-server \
            xorg-xinit \
            xorg-xsetroot \
            nitrogen \
            picom \
            qt5ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
            sxhkd \
            network-manager-applet \
            unclutter \
            papirus-icon-theme
          if [ ! -d "$dir" ]; then
            echo -e "${Red}Git directory does not exist, creating directory.${NC}"
            mkdir -p "$dir" && cd "$dir" || return
          else
            echo -e "${Green}Git directory already exists.${NC}" 
            cd "$dir" || return
          fi
          sleep 3
          if [ ! -d "$dwm" ]; then
            echo -e "${Red}Dwm does not exist, cloning repo & compiling.${NC}"
            cd "$dir" && $git/dwm && cd "$dir"/dwm && make && sudo make clean install
            echo -e "${Blue}Finished compiling & installing dwm.${NC}"
          else
            echo -e "${Green}dwm already exists, reinstalling.${NC}"
            cd "$dwm" && make && sudo make clean install
            echo -e "${Blue}Finished reinstalling dwm.${NC}"
          fi
          sleep 3
          if [ ! -d "$dmenu" ]; then
            echo -e "${Red}Dmenu does not exist, cloning repo & compiling.${NC}"
            cd "$dir" && $git/dmenu && cd "$dir"/dmenu && make && sudo make clean install
            echo -e "${Blue}Finished compiling & installing dmenu.${NC}"
          else
            echo -e "${Green}dmenu already exists, reinstalling.${NC}"
            cd "$dir"/dmenu && make && sudo make clean install
            echo -e "${Blue}Finished reinstalling dmenu.${NC}"
          fi
          sleep 3
          if [ ! -d "$st" ]; then
            echo -e "${Red}St does not exist, cloning repo & compiling.${NC}"
            cd "$dir" && $git/st && cd "$dir"/st && make && sudo make clean install
            echo -e "${Blue}Finished compiling & installing st.${NC}"
          else
            echo -e "${Green}St already exists, reinstalling.${NC}"
            cd "$dir"/st && make && sudo make clean install
            echo -e "${Blue}Finished reinstalling st.${NC}"
          fi
          sleep 3
          if [ ! -d "$dwmblocks" ]; then
            echo -e "${Red}Dwmblocks does not exist, cloning repo & compiling.${NC}"
            cd "$dir" && $git/dwmblocks && cd "$dir"/dwmblocks && make && sudo make clean install
            echo -e "${Blue}Finished installing & compiling dwmblocks.${NC}"
          else 
            echo -e "${Green}Dwmblocks already exists, reinstalling.${NC}"
            cd "$dir"/dwmblocks && make && sudo make clean install
            echo -e "${Blue}Finished reinstalling dwmblocks.${NC}"
          fi
          chown -R jake:jake $dir
          break 2
          ;;
        "Bspwm")
          pacman -S --needed \
            xorg-server \
            xorg-xinit \
            xorg-xsetroot \
            bspwm \
            rofi \
            nitrogen \
            picom \
            qt5ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
            kwallet-pam \
            kwalletmanager \
            ksshaskpass \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter \
            sxhkd \
            papirus-icon-theme
          systemctl enable lightdm.service
          break 2 
          ;;
        "Awesome")
          pacman -S --needed \
            xorg-server \
            xorg-xinit \
            xorg-xsetroot \
            awesome \
            nitrogen \
            picom \
            qt5ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
            kwallet-pam \
            kwalletmanager \
            ksshaskpass \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter \
            sxhkd \
            papirus-icon-theme
          systemctl enable lightdm.service
          break 2 
          ;;
        "i3")
          pacman -S --needed xorg-server \
            xorg-xinit \
            xorg-xsetroot \
            i3 \
            dmenu \
            nitrogen \
            picom \
            qt5ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
            kwallet-pam \
            kwalletmanager \
            ksshaskpass \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter \
            sxhkd \
            papirus-icon-theme
          systemctl enable lightdm.service
          break 2
          ;;
        "Xmonad")
          pacman -S --needed \
            xorg-server \
            xorg-xinit \
            xorg-xsetroot \
            xmonad \
            xmonad-contrib \
            dmenu \
            nitrogen \
            picom \
            qt5ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
            kwallet-pam \
            kwalletmanager \
            ksshaskpass \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter \
            sxhkd \
            papirus-icon-theme
          systemctl enable lightdm.service
          break 2
          ;;
        "Exit")
          break 2
          ;;
        *) echo "Invalid choice. Please enter a valid option."
          ;;
      esac
    done
  else
    break 2
  fi
done
}

mkinitcpio_setup() {
  nvidia_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm btrfs"
  kvm_modules="virtio virtio_blk virtio_pci virtio_net"
  vmware_modules="vmw_balloon vmw_pvscsi vsock vwm_sock_vmci_transport vmwgfx vmxnet3"
  hooks="base udev keyboard autodetect keymap consolefont modconf block encrypt filesystems fsck"
  mkinitcpio_conf="/etc/mkinitcpio.conf"

  if [[ $VM_STATUS == "not_in_vm" && chosen_graphics == "nvidia" ]]; then
   sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
   sed -i "/MODULES=(/ s/)/$nvidia_modules)/" "$mkinitcpio_conf"
   sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
   sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
 elif [[ $VM_STATUS == "kvm" ]]; then
   sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
   sed -i "/MODULES=(/ s/)/$kvm_modules)/" "$mkinitcpio_conf"
   sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
   sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
 elif [[ $VM_STATUS == "vmware" ]]; then
   sed -i 's/\(MODULES=([^)]*\))/MODULES=()/' "$mkinitcpio_conf"
   sed -i "/MODULES=(/ s/)/$vmware_modules)/" "$mkinitcpio_conf"
   sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
   sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
 else
   sed -i 's/\(HOOKS=([^)]*\))/HOOKS=()/' "$mkinitcpio_conf"
   sed -i "/HOOKS=(/ s/)/$hooks)/" "$mkinitcpio_conf"
  fi

  mkinitcpio -P # Rebuild mkinit for all installed kernels
}


# Call functions
init
set_hostname
set_vconsole
set_root_password
create_user
install_core_packages
install_bootloader
install_audio
install_graphics
install_gaming
install_wine
install_virtualization
vm_check
mkinitcpio_setup
zramd_setup
desktop_environment
window_manager
