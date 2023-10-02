#!/usr/bin/env bash

# Colors
NC='\033[0m' # No Color
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

# Functions
drive_partition() {
while true; do
  echo "Available disk partitions:"
  lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
  read -p "Enter the name of the partition you want to use: " partition_choice
  if [ -e "/dev/$partition_choice" ]; then
    # Partition using sgdisk
    sgdisk -Z /dev/$partition_choice
    sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsys /dev/$partition_choice
    # Encryption
    cryptsetup luksFormat --type luks2 --align-payload=8192 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/${partition_choice}p2
    cryptsetup open /dev/${partition_choice}p2 cryptbtrfs
    # BTRFS
    mkfs.btrfs -L archbtrfs /dev/mapper/cryptbtrfs
    mount /dev/mapper/cryptbtrfs /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@libvirt
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@tmp
    umount -R /mnt
    mount_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
    mount -o ${mount_opts},subvol=@ /dev/mapper/cryptbtrfs /mnt
    mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
    mount -o ${mount_opts},subvol=@home /dev/mapper/cryptbtrfs /mnt/home
    mount -o ${mount_opts},subvol=@snapshots /dev/mapper/cryptbtrfs /mnt/.snapshots
    mount -o ${mount_opts},subvol=@cache /dev/mapper/cryptbtrfs /mnt/var/cache
    mount -o ${mount_opts},subvol=@libvirt /dev/mapper/cryptbtrfs /mnt/var/lib/libvirt
    mount -o ${mount_opts},subvol=@log /dev/mapper/cryptbtrfs /mnt/var/log
    mount -o ${mount_opts},subvol=@tmp /dev/mapper/cryptbtrfs /mnt/var/tmp
    mkfs.fat -F32 /dev/${partition_choice}p1
    mount --mkdir /dev/${partition_choice}p1 /mnt/boot
    break 
  else
    echo "Partition '/dev/$partition_choice' does not exist, please choose a valid partition"
    sleep 3
  fi
done
}

pacstab() {
  cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
  if [ "$cpu_vendor" == "AuthenticAMD" ]; then
    ucode="amd-ucode"
  else
    ucode="intel-ucode"
  fi

  pacstrap /mnt \
    base \
    linux \
    linux-headers \
    linux-zen \
    linux-zen-headers \
    linux-firmware \
    sof-firmware \
    $ucode \
    git \
    neovim \
    reflector \
    man-db \
    dosfstools \
    btrfs-progs

  genfstab -U /mnt >> /mnt/etc/fstab
  arch-chroot /mnt
}

init() {
  echo -e "${Green}Setting timezone.${NC}"
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  echo "Syncing system clock"
  hwclock --systohc
  sed -i '171s/.//' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  echo "Enabling multilib"
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  echo "Updating mirrorlist"
  reflector -c 'United States' -a 12 -p https --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Sy
  echo "Updating keyring"
  pacman -S --noconfirm archlinux-keyring sudo
}

set_hostname() {
  echo -n "Enter a value for hostname: "
  read -r hostname
  echo "$hostname" >>/etc/hostname
  {   echo "127.0.0.1  localhost"
      echo "::1   localhost"
      echo "127.0.1.1 $hostname.localdomain.$hostname"
  } >> /etc/hosts
}

set_root_password() {
  echo -n "Enter a value for the root password: "
  read -r password
  echo root:"$password" | chpasswd
}

install_core_packages() {
  pacman -S --needed \
    # Bootloader
    efibootmgr \
    sbctl \
    # Network
    networkmanager \
    nm-connection-editor \
    iwd \
    avahi \
    bind \
    cifs-utils \
    nfs-utils \
    # System Tools
    base-devel \
    pacman-contrib \
    polkit \
    cronie \
    # User Dirs
    xdg-user-dirs \
    xdg-utils \
    # Storage
    udisks2 \
    exfatprogs \
    mtools \
    dosfstools \
    btrfs-progs
    # Print
    cups \
    cups-pdf \
    hplip \
    # Cli Tools
    alacritty \
    arch-install-scripts
    rsync \
    openssh \
    ssh-audit \
    zsh \
    zsh-completions \
    zsh-autosuggestions \
    neofetch \
    htop \
    cmatrix
    cowsay \
    btop \
    nvtop \
    wireshark-qt \
    # Media
    mpd \
    mpc \
    mpv \
    ncmpcpp \
    # Fonts
    ttf-sourcecodepro-nerd \
    ttf-jetbrains-mono-nerd \
    ttf-joypixels
    # lf file manager
    lf \
    lynx \
    ueberzug \
    atool \
    highlight \
    atool \
    bat \
    mediainfo \
    ffmpegthumbnailer \
    odt2txt \
    # PDF & EPUB
    zathura \
    zathura-djvu \
    zathura-pdf-mupdf \
    zathura-ps \
    # User Apps
    firefox \
    bitwarden
  systemctl enable \
    NetworkManager.service \
    avahi-daemon.service \
    iwd.service \
    cups.socket \
    reflector.timer \
    sshd.service \
    fstrim.timer \
    cronie.service
usermod -aG wireshark jake
}

create_user() {
  echo -n "Enter a username: "
  read -r username
  useradd -m "$username"
  echo -n "Enter a password: "
  read -r password
  echo "$username":"$password" | chpasswd
  echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/"$username"
}

install_bootloader() {
  echo "Installing Bootloader"
  bootctl install
  touch /boot/loader/entries/arch.conf
  touch /boot/loader/entries/arch-zen.conf
  echo "title Arch Linux
  linux /vmlinuz-linux
  initrd /amd-ucode.img
  initrd /initramfs-linux.img
  options cryptdedvice=UUID=ENTERUUID:allow-discards root=/dev/mapper/luks rootflags=subvol=@ rd.luks.options=discard nvidia_drm.modeset=1 amd_iommu=on" >> /boot/loader/entries/arch.conf
  echo "title Arch Linux (Zen)
  linux /vmlinuz-linux-zen
  initrd /amd-ucode.img
  initrd /initramfs-linux-zen.img
  options cryptdedvice=UUID=ENTERUUID:allow-discards root=/dev/mapper/luks rootflags=subvol=@ rd.luks.options=discard nvidia_drm.modeset=1 amd_iommu=on" >> /boot/loader/entries/arch-zen.conf
}

install_audio() {
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
  while true; do
  echo -n "Would you like to install a graphics driver (y/n) "
  read -r graphics_driver
  if [[ $graphics_driver == "y" ]]; then
    PS3='Please enter your choice: '
    options=("Nvidia" "AMD" "Intel" "Exit")
    select opt in "${options[@]}"
    do
      case $opt in 
        "Nvidia")
          pacman -S --needed \
            nvidia-dkms \
            nvidia-utils \
            lib32-nvidia-utils \
            nvidia-settings \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            opencl-nvidia \
            lib32-opencl-nvidia \
            nvidia-settings \
            python-pytorch-cuda
          exit
          ;;
        "AMD")
          pacman -S --needed \
            mesa \
            lib32-mesa \
            xf86-video-amdgpu \
            vulkan-radeon \
            lib32-vulkan-radeon \
            libva-mesa-driver \
            lib32-libva-mesa-driver \
            mesa-vdpau \
            lib32-mesa-vdpau \
            rocm-opencl-runtime 
          exit
          ;;
        "Intel")
          pacman -S --needed \
            mesa \
            lib32-mesa \
            vulkan-intel
          exit
          ;;
        "Exit")
          exit 
          ;;
        *)
          echo "Invalid choice. Please enter a valid option."
          ;;
   esac
 done
else
    break
  fi
done
}

install_gaming() {
  echo -n "Will this machine be used for gaming? (y/n) "
  read -r game
  if [[ "$game" == "y" ]]; then
  pacman -S --needed \
    steam \
    lutris \
    discord \
    retroarch \
    retroarch-assets-xmb \
    retroarch-assets-ozone \
    libretro-core-info \
    gamescope \
    yuzu
  fi
}

install_wine() {
  echo -n "Do you want to install Wine? (y/n) "
  read -r wine
  if [[ "$wine" == "y" ]]; then
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
  fi
}

install_virtualization() {
  echo -n "Are you using QEMU? (y/n) "
  read -r qemu
if [[ "$qemu" == "y" ]]; then
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
    swtpm
  systemctl enable libvirtd.service
  usermod -aG libvirt jake
fi
  echo -n "Are you using docker? (y/n) "
  read -r docker
if [[ "$docker" == "y" ]]; then
  pacman -S --needed \
    docker \
    docker-compose
  systemctl enable docker.service
  usermod -aG docker jake
fi
  echo -n "Is this machine a vmware guest? (y/n) "
  read -r vmware
if [[ "$vmware" == "y" ]]; then
  pacman -S --needed \
    open-vm-tools \
    xf86-input-vmmouse \
    xf86-video-vmware \
    mesa \
    gtkmm \
    gtk2
  systemctl enable vmtoolsd.service vmware-vmblock-fuse
fi
}

laptop() {
  echo -n "Is this machine a laptop? (y/n) "
  read -r laptop 
  if [[ $laptop == "y" ]]; then
    pacman -S --needed \
      acpid \
      tlp \
      acpilight
    systemctl enably tlp.service acpid.service
    usermod -aG video "$username"
  fi  
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
            latte-dock \
            plasma-nm \
            packagekit-qt5 \
            sddm \
            plasma-wayland-session \
            qt5-wayland \
            qt6-wayland
          systemctl enable sddm
          exit
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
          exit
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
          exit
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
          exit 
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
          exit
          ;;
        "Exit")
          exit
          ;;
        *)
          echo "Invalid choice. Please enter a valid option."
          ;;
      esac
    done 
  else
    break
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
            kwallet-pam \
            kwalletmanager \
            ksshaskpass \
            lightdm \
            lightdm-gtk-greeter \
            lightdm-webkit2-greeter \
            sxhkd \
            network-manager-applet \
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
          exit
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
          exit 
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
          exit 
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
          exit
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
          exit
          ;;
        "Exit")
          exit
          ;;
        *) echo "Invalid choice. Please enter a valid option."
          ;;
      esac
    done
  else
    break
  fi
done
}


drive_partition
pacstab
# Chroot
arch-chroot /mnt
#
init
set_hostname
set_root_password
create_user
install_core_packages
install_bootloader
install_audio
install_graphics
install_gaming
install_wine
install_virtualization
laptop
desktop_environment
window_manager
