#!/usr/bin/env bash

echo "Setting timezone"
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
echo "Syncing system clock"
hwclock --systohc
echo "Generating locale"
sed -i '171s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Enabling multilib"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
echo "Updating mirrorlist"
reflector -c 'United States' -a 6 -p https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
echo "Updating keyring"
pacman -S --noconfirm archlinux-keyring

set_hostname() {
  echo -n "Enter a value for hostname: "
  read -r hostname

  echo "$hostname" >>/etc/hostname
  echo "127.0.0.1 localhost" >>/etc/hosts
  echo "::1       localhost" >>/etc/hosts
  echo "127.0.1.1 $hostname.localdomain.$hostname" >>/etc/hosts
}


function set_root_password() {
  echo -n "Enter a value for the root password: "
  read -r password

  echo root:$password | chpasswd
}

install_core_packages() {
  pacman -S --needed networkmanager nm-connection-editor network-manager-applet iwd avahi base-devel pacman-contrib dialog mtools xdg-user-dirs xdg-utils cifs-utils nfs-utils udisks2 bind cups cups-pdf hplip rsync openssh ssh-audit zsh zsh-completions zsh-autosuggestions firefox neofetch htop alacritty btop wireshark-qt polkit ranger atool ueberzug highlight exfat-utils cronie ttf-sourcecodepro-nerd lazygit mpd mpc mpv ncmpcpp
  systemctl enable NetworkManager.service avahi-daemon.service iwd.service cups.socket reflector.timer sshd.service fstrim.timer cronie.service bluetooth.service 
usermod -aG wireshark jake
}

create_user() {
  echo -n "Enter a username: "
  read -r username
  useradd -m -s /bin/zsh $username
  echo -n "Enter a password: "
  read -r password
  echo $username:$password | chpasswd
  echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username
}


install_grub() {
  echo -n "Do you want to use GRUB as your bootloader? (y/n)"
  read -r grub

  if [[ $grub == "y" ]]; then
    pacman -S --needed --noconfirm grub efibootmgr os-prober
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
  fi

  echo -n "Are you using btrfs? (y/n)"
  read -r grub_btrfs
  if [[ $grub_btrfs == "y" ]]; then
    pacman -S --needed --noconfirm grub-btrfs
  fi
}

install_audio() {
  pacman -S --needed pipewire pipewire-docs pipewire-alsa lib32-pipewire easyeffects alsa-utils alsa-plugins pipewire-pulse wireplumber wireplumber-docs pipewire-jack lib32-pipewire-jack pulsemixer bluez bluez-utils lsp-plugins sof-firmware
}

install_graphic() {
  echo "Are you using an NVIDIA graphics card (y/n)"
  read -r nvidia

  if [[ "$nvidia" == "y" ]]; then
    pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
  fi
}

install_gaming() {
  pacman -S --needed steam lutris discord retroarch retroarch-assets-xmb retroarch-assets-ozone libretro-core-info
}

install_wine() {
  pacman -S --needed wine-staging wine-gecko wine-mono pipewire-pulse lib32-libpulse lib32-alsa-oss lib32-gnutls lib32-gst-plugins-base lib32-gst-plugins-good samba winetricks zenity
}

install_virtualization() {
  echo "Are you using QEMU? (y/n)"
  read -r qemu

  if [[ "$qemu" == "y" ]]; then
  pacman -S  --needed virt-manager qemu-full qemu-emulators-full dmidecode edk2-ovmf iptables-nft dnsmasq openbsd-netcat bridge-utils vde2 libvirt swtpm qemu-audio-alsa qemu-audio-dbus qemu-audio-jack qemu-audio-oss qemu-audio-pa qemu-audio-sdl qemu-audio-spice qemu-block-curl qemu-block-dmg qemu-block-gluster qemu-block-iscsi qemu-block-nfs qemu-block-ssh qemu-chardev-baum qemu-chardev-spice qemu-docs qemu-hw-display-qxl qemu-hw-display-virtio-gpu qemu-hw-display-virtio-gpu-gl qemu-hw-display-virtio-gpu-pci qemu-hw-display-virtio-gpu-pci-gl qemu-hw-display-virtio-vga qemu-hw-display-virtio-vga-gl qemu-hw-s390x-virtio-gpu-ccw qemu-hw-usb-host qemu-hw-usb-redirect qemu-hw-usb-redirect qemu-hw-usb-smartcard qemu-img qemu-pr-helper qemu-system-aarch64 qemu-system-alpha qemu-system-arm qemu-system-avr qemu-system-cris qemu-system-hppa qemu-system-m68k qemu-system-microblaze qemu-system-mips qemu-system-nios2 qemu-system-or1k qemu-system-ppc qemu-system-riscv qemu-system-rx qemu-system-s390x qemu-system-sh4 qemu-system-sparc qemu-system-tricore qemu-system-x86 qemu-system-xtensa qemu-tests qemu-tools qemu-ui-curses qemu-ui-dbus qemu-ui-egl-headless qemu-ui-gtk qemu-ui-opengl qemu-ui-sdl qemu-ui-spice-app qemu-ui-spice-core qemu-user qemu-vhost-user-gpu qemu-virtiofsd
  systemctl enable libvirtd.service
  usermod -aG libvirt jake
  fi

  echo "Are you using docker? (y/n)"
  read -r docker

  if [[ "$docker" == "y" ]]; then
    pacman -S --needed docker docker-compose
    systemctl enable docker.Service
  fi

  echo "Is this machine a vmware guest? (y/n)"
  read -r vmware

  if [[ "$vmware" == "y" ]]; then
    pacman -S --needed open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa gtkmm gtk2
    systemctl enable vmtoolsd.service vmware-vmblock-fuse
  fi
}

laptop() {
  echo "Is this machine a laptop? (y/n)"
  read -r laptop 

  if [[ $laptop == "y" ]]; then
    pacman -S acpid tlp acpilight
    systemctl enably tlp.service acpid.service
    usermod -aG video $username
}

printf "\e[1;32mDone! Type exit, umount -R /mnt and reboot.\e[0m"
