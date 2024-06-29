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
  echo -e "${Green}Setting up console font${NC}"
  sleep 1
  pacman -S --needed --noconfirm terminus-font
  if [[ "$VM_STATUS" == "not_in_vm" ]]; then
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

create_user() {
  echo -n "Enter a username: "
  read -r username
  useradd -m "$username"
  echo -n "Enter a password: "
  read -r password
  echo "$username":"$password" | chpasswd
  echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/"$username"
  export username
}

install_packages() {
  core_apps="base-devel networkmanager nm-connection-editor iwd avahi bind cifs-utils pacman-contrib xdg-user-dirs xdg-utils udisks2 mtools dosfstools alacritty kitty rsync openssh ssh-audit zsh zsh-autosuggestions zsh-completions fastfetch htop btop ttf-roboto-mono-nerd ttf-sourcecodepro-nerd ttf-terminus-nerd ttf-meslo-nerd ttfs-mononoki-nerd ttf-nerd-fonts-symbols ttf-noto-nerd ttf-jetbrains-mono-nerd lf chafa lynx ueberzug atool highlight bat mediainfo ffmpegthumbnailer odt2txxt zathura firefox torbrowser-launcher nyx chromium python python-pip python-virtualenv"
  non_vm_apps="exfatprogs cups cups-pdf hplip nvtop cmatrix cowsay wireshark-qt mpd mpc mpv ncmpcpp ttf-joypixels hugo openrgb syncthing"
  nvim_deps="tree-sitter go rustup luarocks composer php nodejs npm python python-pip jdk-openjdk wget curl gzip tar bash xclip wl-clipboard ripgrep fd"
  opsec_apps="nmap hashcat hashcat-utils hping tcpdump"


  echo -e "${Green}Installing packages${NC}"
  if [[ "$VM_STATUS" == "not_in_vm" ]]; then
    pacman -S --needed "$core_apps" "$non_vm_apps" "$nvim_deps" "$opsec_apps"
    systemctl enable \
      NetworkManager.service \
      avahi-daemon.service \
      iwd.service \
      reflector.timer \
      sshd.service \
      fstrim.timer \
      systemd-timesyncd.service \
      cups.socket \
      tor.service
	  usermod -aG wireshark,input,video "$username"
	else pacman -S --needed "$core_apps"
	  NetworkManager.service \
	    avahi-daemon.service \
	    iwd.service \
	    reflector.timer \
	    sshd.service \
	    fstrim.timer \
	    systemd-timesyncd.service \
	    tor.service
  fi
}

install_bootloader() {
  luksuuid=$(blkid -s UUID -o value /dev/${partition_choice}${partition_suffix}2)
  if [[ "$chosen_filesystem" == "btrfs" ]]; then
	  btrfs_options="rootflags=subvol=@"
  fi
  if [[ "$chosen_graphics" == "Nvidia" ]]; then
    nvidia_options="nvidia_drm.modeset=1"
  fi
  if [[ "$encryption" == "y" ]]; then
    luks_options="cryptdevice=UUID=$luksuuid:luks:allow-discards root=/dev/mapper/luks"
  fi
  if [[ "$ucode" == "amd-ucode" ]]; then
    iommu_options="amd_iommu=on iommu=pt"
  elif [[ "$ucode" == "intel-ucode" ]]; then
    iommu_options="intel_iommu=on iommu=pt"
  else iommu_options=""
  fi
  if [[ "$ucode" == "amd-ucode" ]]; then
    initrd="/amd-ucode.img"
  elif [[ "$ucode" == "intel-ucode" ]]; then
    initrd="/intel-ucode.img"
  else initrd=""
  fi

  systemdboot_options="$luks_options $btrfs_options $iommu_options $nvidia_options"

  if [[ "$uefi" == "32" ]]; then #TODO: Test this in vm by setting this var and exporting at start of host script
	  echo -e "${Green}Installing systemd-boot${NC}"
	  sleep 2
	  bootctl install
	  touch /boot/loader/entries/arch.conf
	  touch /boot/loader/entries/arch-zen.conf
	  echo "title Arch Linux
	  linux /vmlinuz-linux
	  initrd $initrd
	  initrd /initramfs-linux.img
	  options $systemdboot_options rw" > /boot/loader/entries/arch.conf
	  echo "title Arch Linux (Zen)
	  linux /vmlinuz-linux
	  initrd $initrd
	  initrd /initramfs-linux.img
	  options $systemdboot_options rw" > /boot/loader/entries/arch.conf
  else
	  while true; do
		  PS3='Select a bootloader: '
		  options=("GRUB" "Systemd-Boot")
		  select opt in "${options[@]}"; do
			  case $opt in
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
				  "Systemd-Boot")
					  echo -e "${Green}Installing systemd-boot${NC}"
					  sleep 2
					  bootctl install
					  touch /boot/loader/entries/arch.conf
					  touch /boot/loader/entries/arch-zen.conf
					  echo "title Arch Linux
					  linux /vmlinuz-linux
					  initrd $initrd
					  initrd /initramfs-linux.img
					  options $systemdboot_options rw" > /boot/loader/entries/arch.conf
					  echo "title Arch Linux (Zen)
					  linux /vmlinuz-linux
					  initrd $initrd
					  initrd /initramfs-linux.img
					  options $systemdboot_options rw" > /boot/loader/entries/arch.conf
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
  if [[ "$VM_STATUS" != "not_in_vm" ]]; then
    echo -e "${Green}System is in a VM, no graphics driver required${NC}"
    sleep 1
    return 0
  else
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
  fi
export chosen_graphics
}

install_gaming() {
  if [[ "$VM_STATUS" == "not_in_vm" ]]; then
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
  if [[ "$VM_STATUS" == "not_in_vm" ]]; then
    pacman -S --needed \
      wine \
      wine-gecko \
      wine-mono \
      lib32-pipewire \
      pipewire-pulse \
      lib32-libpulse \
      lib32-gnutls \
      lib32-sdl2 \
      lib32-gst-plugins-base \
      lib32-gst-plugins-good \
      samba \
      winetricks
        else
          return 0
  fi
}

setup_virtualization() {
  if [[ "$VM_STATUS" != "not_in_vm" ]]; then
    echo -e "${Green}System is in a VM, skipping QEMU install${NC}"
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
      systemctl enable libvirtd.service
	  usermod -aG libvirt,kvm "$username"
  fi
}

singlegpu_passthrough() {
  hooks_dir="/etc/libvirt/hooks"
  hooks_qemu_file="/etc/libvirt/hooks/qemu"
  qemu_start_dir="/etc/libvirt/hooks/qemu.d/win11/prepare/begin"
  qemu_start_file="/etc/libvirt/hooks/qemu.d/win11/prepare/begin/start.sh"
  qemu_stop_dir="/etc/libvirt/hooks/qemu.d/win11/release/end"
  qemu_stop_file="/etc/libvirt/hooks/qemu.d/win11/end/stop.sh"
  if [[ "$chosen_graphics" != "Nvidia" ]]; then
    echo -e "${Green}Single GPU passthrough is only supported for NVIDIA${NC}"
    sleep 1
    return 0
  else
    virsh net-start default
    virsh net-autostart default
    mkdir -p $hooks_dir
    touch $hooks_qemu_file
    chmod +x $hooks_qemu_file
    mkdir -p $qemu_start_dir
    touch $qemu_start_file
    mkdir -p $qemu_stop_dir
    touch $qemu_stop_file

    cat > "$hooks_qemu_file" << 'EOF'
    #!/usr/bin/env bash

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"
    MISC="${@:4}"

    BASEDIR="$(dirname $0)"

    HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
    set -e # If a script exits with an error, we should as well.

    if [ -f "$HOOKPATH" ]; then
      eval "\"$HOOKPATH\"" "$@"
    elif [ -d "$HOOKPATH" ]; then
      while read file; do
	eval "\"$file\"" "$@"
      done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
    fi
EOF


    cat > "$qemu_start_file" << EOF
    #!/usr/bin/env bash

    set -x

# Stop display manager
systemctl stop display-manager
systemctl --user -M $username@ stop plasma*

# Unbind VTconsoles: might not be needed
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload GPU kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia


# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_01_00_0
virsh nodedev-detach pci_0000_01_00_1

# Load vfio module
modprobe vfio-pci
EOF

cat > "$qemu_stop_file" << EOF
#!/usr/bin/env bash

set -x

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_01_00_0
virsh nodedev-reattach pci_0000_01_00_1

# Unload vfio module
modprobe -r vfio-pci

# Rebind framebuffer to host
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Bind VTconsoles: might not be needed
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
systemctl start display-manager
EOF
    fi

}

docker_setup() {
  echo -en "${Green}Would you like to use docker? (y/n) "
  read -r docker
  if [[ "$docker" == "y" ]]; then
    pacman -S --needed --noconfirm docker docker-compose
    systemctl enable docker.service
    usermod -aG docker "$username"
    if [[ ! -d /etc/docker ]]; then
      mkdir /etc/docker
    fi
    if [[ "$chosen_filesystem" == "btrfs" ]]; then
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

smb_setup() {
  cred_dir="/etc/samba/credentials"
  share_file="/etc/samba/credentials/share"
  truenas_dir="/mnt/truenas"
  nas_addr="//10.0.40.5"
  smb_options="file_mode=0777,dir_mode=0777,_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"
  echo -e "${Green}Setting up SMB shares${NC}"
  sleep 1
  sudo pacman -S --needed --noconfirm cifs-utils
  if [[ ! -d "$cred_dir" ]]; then
    mkdir -p $cred_dir
  fi
  if [[ -e $share_file ]]; then
    echo -e "${Green}Share file already exists${NC}"
  else touch $share_file
  fi
  echo "$username" | sudo tee -a "$share_file" > /dev/null 
  echo -n Password:
  read -r Password
  echo "password=$Password" | sudo tee -a "$share_file" > /dev/null 
  echo -e "${Green}Updating permissions${NC}"
  sleep 1
  chown root:root "$cred_dir" && chmod 700 "$cred_dir" && chmod 600 "$share_file"
  if [[ ! -d $truenas_dir ]]; then
    mkdir -p /mnt/truenas/{media,iso,photos,gold,stash,stash2}
  fi
  {
    echo " "
    echo "$nas_addr"/Jake       "$truenas_dir"/jake         cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/Stash        "$truenas_dir"/stash          cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/Stash2        "$truenas_dir"/stash2          cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/Media      "$truenas_dir"/media        cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/Gold         "$truenas_dir"/gold           cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/ISO         "$truenas_dir"/iso         cifs        "$smb_options"
    echo " "
    echo "$nas_addr"/Photos	   "$truenas_dir"/photos	cifs        "$smb_options"

  } | sudo tee -a /etc/fstab > /dev/null
}

desktop_environment() {
  while true; do
  echo -n "Would you like to install a desktop environment (y/n) "
  read -r desktop_environment 
  if [[ $desktop_environment == "y" ]]; then
    PS3='Please enter your choice: '
    options=("KDE" "Gnome" "Exit")
    select opt in "${options[@]}"
    do
      case $opt in
        "KDE")
          pacman -S --needed \
	    plasma-desktop \
	    kscreen \
	    kscreenlocker \
	    spectacle \
	    bluedevil \
	    breeze \
	    breeze-gtk \
	    breeze-plymouth \
	    xdg-desktop-portal-kde \
	    systemsettings \
	    print-manager \
	    powerdevil \
	    polkit \
	    polkit-kde-agent \
	    plymouth-kcm \
	    plasma5support \
	    plasma-workspace-wallpapers \
	    plasma-workspace \
	    plasma-vault \
	    plasma-systemmonitor \
	    plasma-pa \
	    plasma-nm \
	    plasma-integration \
	    plasma-firewall \
	    plasma-disks \
	    plasma-browser-integration \
	    milou \
	    libplasma \
	    libksysguard \
	    libkscreen \
	    layer-shell-qt \
	    kwrited \
	    kwayland-integration \
	    qt5-wayland \
	    qt6-wayland \
	    kde-gtk-config \
	    kwallet \
	    kwallet-pam \
	    ksshaskpass \
	    ksystemstats \
	    kpipewire \
	    plasma-pa \
	    kmenuedit \
	    kinfocenter \
	    kglobalaccel \
	    kglobalacceld \
	    kgamma \
	    kde-cli-tools \
	    kactivitymanagerd \
	    flatpak \
	    flatpak-builder \
	    discover \
	    flatpak-kcm \
	    drkonqi \
	    sddm \
	    sddm-kcm \
	    dolphin \
	    dolphin-plugins \
	    kompare \
	    baloo \
	    baloo-widgets \
	    kdegraphics-thumbnailers \
	    kimageformats \
	    libheif \
	    qt6-imageformats \
	    kdesdk-thumbnailers \
	    ffmpegthumbs \
	    taglib \
	    audiocd-kio \
	    udisks2 \
	    kde-inotify-survey \
	    kdenetwork-filesharing \
	    kio-gdrive \
	    kio-admin \
	    kio-extras \
	    kio-fuse \
	    libappindicator-gtk3 \
	    gwenview \
	    qt5-imageformats \
	    icoutils \
	    iio-sensor-proxy \
	    noto-fonts \
	    noto-fonts-emoji \
	    maliit-keyboard \
	    power-profiles-daemon \
	    switcheroo-control \
	    xsettingsd \
	    ark \
	    unarchiver \
	    unrar \
	    filelight \
	    kcalc \
	    kdialog
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
  while true; do
  echo -n "Would you like to install a tiling window manager (y/n) "
  read -r window_manager 
  if [[ $window_manager == "y" ]]; then
    PS3='Please enter your choice: '
    options=("Dwm" "Hyprland" "Exit")
    dwm_build="git clone https://github.com/GTXFerrari/dwm"
    dmenu_build="https://github.com/GTXFerrari/dmenu"
    dwmblocks_build="https://github.com/GTXFerrari/dwmblocks"
    git_dir="/home/$username/Git"
    select opt in "${options[@]}"
    do
      case $opt in
        "Dwm")
          pacman -S --needed \
	    xorg-server \
            xorg-xinit \
            xorg-xsetroot \
	    scrot \
            nitrogen \
	    blueman \
            picom \
            qt5ct \
	    qt6ct \
            lxappearance \
            gnome-themes-extra \
            dunst \
            polkit \
            polkit-kde-agent \
	    gnome-keyring \
	    libsecret \
	    seahorse \
            network-manager-applet \
            unclutter \
	    cronie \
	    pasystray \
            papirus-icon-theme

	  # Check dirs & clone builds
	  if [[ ! -d $git_dir ]]; then
	    mkdir -p /home/"$username"/Git
	  else echo -e "$Green Git directory already exists"
	  fi

	  if [[ ! -d $git_dir/dwm ]]; then
	    $dwm_build
	  else echo -e "$Green dwm folder already exists"
	  fi

	  if [[ ! -d $git_dir/dmenu ]]; then
	    $dmenu_build
	  else echo -e "$Green dmenu folder already exists"
	  fi

	  if [[ ! -d $git_dir/dmenu ]]; then
	    $dwmblocks_build
	  else echo -e "$Green dwmblocks folder already exists"
	  fi

	  # Build
	  make "$git_dir"/dwm/ && sudo make clean install "$git_dir"/dwm/
	  make "$git_dir"/dmenu/ && sudo make clean install "$git_dir"/dmenu/
	  make "$git_dir"/dwmblocks/ && sudo make clean install "$git_dir"/dwmblocks/

	  # Setup nitrogen wallpaper slideshow
	  nitrogen_slideshow_cron="*/5 * * * * (export DISPLAY=:1.0 && /bin/date && /usr/bin/nitrogen --set-zoom-fill --random /home/$username/Pictures/Wallpapers/ --save) > /tmp/myNitrogen.log 2>&1"
	  (crontab -l | grep -F "$nitrogen_slideshow_cron") || (crontab -l; echo "$nitrogen_slideshow_cron") | crontab -
          ;;
	"Hyprland")
	  pacman -S --needed \
	    hyprland \
	    qt5-wayland \
	    qt6-wayland \
	    qt5ct \
	    qt6ct \
	    libva \
	    kitty \
	    xdg-desktop-portal-hyprland \
	    nwg-look \
	    polkit-kde-agent \
	    waybar \
	    wofi \
	    pavucontrol \
	    swaync \
	    gvfs-smb 
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
  if [[ "$chosen_filesystem" == "btrfs" ]]; then
    btrfs_module="btrfs"
  else btrfs_module=""
  fi
  if [[ "$encryption" == "y" ]]; then
    encrypt_hook="encrypt"
  else encrypt_hook=""
  fi
  nvidia_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm $btrfs_module"
  kvm_modules="virtio virtio_blk virtio_pci virtio_net $btrfs_module"
  vmware_modules="vmw_balloon vmw_pvscsi vsock vmw_vsock_vmci_transport vmwgfx vmxnet3 $btrfs_module"
  hooks="base udev autodetect microcode modconf keyboard keymap consolefont block $encrypt_hook filesystems fsck"
  mkinitcpio_conf="/etc/mkinitcpio.conf"
  if [[ "$VM_STATUS" == "not_in_vm" && "$chosen_graphics" == "Nvidia" ]]; then
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
