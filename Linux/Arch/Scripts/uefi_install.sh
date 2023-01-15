#!/usr/bin/env bash

# Functions
init() {
  echo "Setting timezone"
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  echo "Syncing system clock"
  hwclock --systohc
  sed -i '171s/.//' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  echo "Enabling multilib"
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  echo "Updating mirrorlist"
  reflector -c 'United States' -a 6 -p https --sort rate --save /etc/pacman.d/mirrorlist
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
function set_root_password() {
  echo -n "Enter a value for the root password: "
  read -r password

  echo root:"$password" | chpasswd
}
install_core_packages() {
  pacman -S --needed networkmanager nm-connection-editor network-manager-applet iwd avahi base-devel pacman-contrib dialog mtools xdg-user-dirs xdg-utils cifs-utils nfs-utils udisks2 bind cups cups-pdf hplip rsync openssh ssh-audit zsh zsh-completions zsh-autosuggestions firefox neofetch htop alacritty btop wireshark-qt polkit ranger atool ueberzug highlight exfat-utils cronie ttf-sourcecodepro-nerd lazygit mpd mpc mpv ncmpcpp
  systemctl enable NetworkManager.service avahi-daemon.service iwd.service cups.socket reflector.timer sshd.service fstrim.timer cronie.service
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
install_grub() {
  echo -n "Do you want to use GRUB as your bootloader? (y/n) "
  read -r grub

  if [[ $grub == "y" ]]; then
    pacman -S --needed --noconfirm grub efibootmgr os-prober
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
  fi

  echo -n "Are you using btrfs? (y/n) "
  read -r grub_btrfs
  if [[ $grub_btrfs == "y" ]]; then
    pacman -S --needed --noconfirm grub-btrfs
  fi
}
install_audio() {
  pacman -S --needed pipewire pipewire-docs pipewire-alsa lib32-pipewire easyeffects alsa-utils alsa-plugins pipewire-pulse wireplumber wireplumber-docs pipewire-jack lib32-pipewire-jack pulsemixer bluez bluez-utils lsp-plugins sof-firmware
  systemctl enable bluetooth.service
}
install_graphics() {
  echo -n "Are you using an NVIDIA graphics card (y/n) "
  read -r nvidia
  if [[ "$nvidia" == "y" ]]; then
    pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
  fi
  echo -n "Are you using an AMD graphics card (y/n) "
  read -r amd
  if [[ "$amd" == "y" ]]; then
    pacman -S --needed mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
  fi 
  echo -n "Are you using an Intel graphics card (y/n) "
  read -r intel
  if [[ "$intel" == "y" ]]; then
  pacman -S --needed mesa lib32-mesa vulkan-intel
  fi
}
install_gaming() {
  echo -n "Will this machine be used for gaming? (y/n) "
  read -r game
  if [[ "$game" == "y" ]]; then
  pacman -S --needed steam lutris discord retroarch retroarch-assets-xmb retroarch-assets-ozone libretro-core-info
  fi
}
install_wine() {
  echo -n "Do you want to install Wine? (y/n) "
  read -r wine
  if [[ "$wine" == "y" ]]; then
  pacman -S --needed wine-staging wine-gecko wine-mono pipewire-pulse lib32-libpulse lib32-alsa-oss lib32-gnutls lib32-gst-plugins-base lib32-gst-plugins-good samba winetricks zenity
  fi
}
install_virtualization() {
  echo -n "Are you using QEMU? (y/n) "
  read -r qemu
  if [[ "$qemu" == "y" ]]; then
  pacman -S  --needed virt-manager qemu-full qemu-emulators-full dmidecode edk2-ovmf iptables-nft dnsmasq openbsd-netcat bridge-utils vde2 libvirt swtpm qemu-audio-alsa qemu-audio-dbus qemu-audio-jack qemu-audio-oss qemu-audio-pa qemu-audio-sdl qemu-audio-spice qemu-block-curl qemu-block-dmg qemu-block-gluster qemu-block-iscsi qemu-block-nfs qemu-block-ssh qemu-chardev-baum qemu-chardev-spice qemu-docs qemu-hw-display-qxl qemu-hw-display-virtio-gpu qemu-hw-display-virtio-gpu-gl qemu-hw-display-virtio-gpu-pci qemu-hw-display-virtio-gpu-pci-gl qemu-hw-display-virtio-vga qemu-hw-display-virtio-vga-gl qemu-hw-s390x-virtio-gpu-ccw qemu-hw-usb-host qemu-hw-usb-redirect qemu-hw-usb-redirect qemu-hw-usb-smartcard qemu-img qemu-pr-helper qemu-system-aarch64 qemu-system-alpha qemu-system-arm qemu-system-avr qemu-system-cris qemu-system-hppa qemu-system-m68k qemu-system-microblaze qemu-system-mips qemu-system-nios2 qemu-system-or1k qemu-system-ppc qemu-system-riscv qemu-system-rx qemu-system-s390x qemu-system-sh4 qemu-system-sparc qemu-system-tricore qemu-system-x86 qemu-system-xtensa qemu-tests qemu-tools qemu-ui-curses qemu-ui-dbus qemu-ui-egl-headless qemu-ui-gtk qemu-ui-opengl qemu-ui-sdl qemu-ui-spice-app qemu-ui-spice-core qemu-user qemu-vhost-user-gpu qemu-virtiofsd
  systemctl enable libvirtd.service
  usermod -aG libvirt jake
  fi
  echo -n "Are you using docker? (y/n) "
  read -r docker
  if [[ "$docker" == "y" ]]; then
    pacman -S --needed docker docker-compose
    systemctl enable docker.Service
  fi
  echo -n "Is this machine a vmware guest? (y/n) "
  read -r vmware
  if [[ "$vmware" == "y" ]]; then
    pacman -S --needed open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa gtkmm gtk2
    systemctl enable vmtoolsd.service vmware-vmblock-fuse
  fi
}
laptop() {
  echo -n "Is this machine a laptop? (y/n) "
  read -r laptop 
  if [[ $laptop == "y" ]]; then
    pacman -S acpid tlp acpilight
    systemctl enably tlp.service acpid.service
    usermod -aG video "$username"
  fi  
}
desktop_environment() {
  echo -n "Would you like to install a desktop environment (y/n) "
  read -r desktop_environment 
  if [[ $desktop_environment == "y" ]]; then
PS3='Please enter your choice: '
options=("KDE" "Gnome" "Cinnamon" "Xfce" "Budgie" "None")
select opt in "${options[@]}"
do
    case $opt in
        "KDE")
            pacman -S --needed xorg plasma kde-applications plasma-nm packagekit-qt5 sddm
            systemctl enable sddm
            pacman -Rs network-manager-applet
            break
            ;;
        "Gnome")
            pacman -S --needed xorg gnome gnome-extra gnome-tweaks gnome-themes-extra gdm
            systemctl enable gdm.service
            break
            ;;
        "Cinnamon")
            pacman -S --needed xorg cinnamon xed xreader metacity gnome-shell gnome-keyring libsecret seahorse system-config-printer blueberry gnome-screenshot gdm
            systemctl enable gdm.service
            break
            ;;
        "Xfce")
            pacman -S --needed xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-webkit2-greeter
            systemctl enable lightdm.service
            break
            ;;
        "Budgie")
            pacman -S --needed xorg budgie-desktop budgie-desktop-view budgie-extras  lightdm lightdm-gtk-greeter lightdm-webkit2-greeter
            systemctl enable lightdm.service
            break
            ;;
        "None")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
  done
fi
}
window_manager() {
  echo -n "Would you like to install a tiling window manager (y/n) "
  read -r window_manager 
  if [[ $window_manager == "y" ]]; then

PS3='Please enter your choice: '
options=("Dwm" "Bspwm" "Awesome" "i3" "Xmonad" "None")
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
            pacman -S --needed xorg-server xorg-xinit xorg-xsetroot nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels lightdm lightdm-gtk-greeter lightdm-webkit2-greeter sxhkd
            if [ ! -d "$dir" ]; then
                echo "Git directory does not exist, creating directory"
                mkdir -p "$dir" && cd "$dir" || return
            else
                echo "Git directory already exists" 
                cd "$dir" || return
            fi
            if [ ! -d "$dwm" ]; then
                echo "dwm does not exist, cloning repo & compiling"
                cd "$dir" && $git/dwm && cd "$dir"/dwm && make && sudo make clean install
                echo "Finished compiling & installing dwm"
            else
                echo "dwm already exists, reinstalling"
                cd "$dwm" && make && sudo make clean install
                echo "Finished reinstalling dwm"
            fi
            if [ ! -d "$dmenu" ]; then
                echo "dmenu does note exist, cloning repo & compiling"
                cd "$dir" && $git/dmenu && cd "$dir"/dmenu && make && sudo make clean install
                echo "Finished compiling & installing dmenu"
            else
                echo "dmenu already exists, reinstalling"
                cd "$dir"/dmenu && make && sudo make clean install
                echo "Finished reinstalling dmenu"
            fi
            if [ ! -d "$st" ]; then
                echo "st does not exist, cloning repo & compiling"
                cd "$dir" && $git/st && cd "$dir"/st && make && sudo make clean install
                echo "Finished compiling & installing st"
            else
                echo "st already exists, reinstalling"
                cd "$dir"/st && make && sudo make clean install
                echo "Finished reinstalling st"
            fi
            if [ ! -d "$dwmblocks" ]; then
                echo "dwmblocks does not exist, cloning repo & compiling"
                cd "$dir" && $git/dwmblocks && cd "$dir"/dwmblocks && make && sudo make clean install
                echo "Finished installing & compiling dwmblocks"
            else 
                echo "dwmblocks already exists, reinstalling"
                cd "$dir"/dwmblocks && make && sudo make clean install
                echo "Finished reinstalling dwmblocks"
            fi
            break
            ;;
        "Bspwm")
             pacman -S --needed xorg-server xorg-xinit xorg-xsetroot bspwm rofi nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels lightdm lightdm-gtk-greeter lightdm-webkit2-greeter sxhkd
           systemctl enable lightdm.service
            break
            ;;
        "Awesome")
              pacman -S --needed xorg-server xorg-xinit xorg-xsetroot awesome nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels lightdm lightdm-gtk-greeter lightdm-webkit2-greeter sxhkd
              systemctl enable lightdm.service
            break
            ;;
        "i3")
             pacman -S --needed xorg-server xorg-xinit xorg-xsetroot i3 dmenu nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels lightdm lightdm-gtk-greeter lightdm-webkit2-greeter sxhkd
             systemctl enable lightdm.service
            break
            ;;
        "Xmonad")
            pacman -S --needed xorg-server xorg-xinit xorg-xsetroot xmonad xmonad-contrib dmenu nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels lightdm lightdm-gtk-greeter lightdm-webkit2-greeter sxhkd
            systemctl enable lightdm.service
           break
            ;;
        "None")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
 done
fi
}

# Call functions
init
set_hostname
set_root_password
create_user
install_core_packages
install_grub
install_audio
install_graphics
install_gaming
install_wine
install_virtualization
laptop
desktop_environment
window_manager