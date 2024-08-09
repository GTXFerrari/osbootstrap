#!/usr/bin/env bash

# Path
DIR="/home/$USER/Git"
PARU="/home/$USER/Git/paru"

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

echo -ne "${Blue}This script should be ran as a standard user after rebooting from the install ISO, would you like to continue? (y/n) ${NC}"
read -r usr 
if [[ "$usr" == "n" ]]; then
    exit
fi

check_secure_boot() {
pacman -S --needed --noconfirm mokutil
secure_boot=$(mokutil --sb-state 2>&1)

if [[ "$secure_boot" == *"SecureBoot enabled"* ]]; then
	sb_status="enabled"
else
	sb_status="disabled"
fi

if [[ "$sb_status" == "enabled" ]]; then
  install_sbctl="sbctl"
else
  install_sbctl=""
fi
export sb_status
export install_sbctl
#TODO: Set up sbctl in post install
}

# Create Git directory and clone paru
if [ ! -d "$DIR" ]; then
    echo -e "${Red}Git directory does not exist, creating directory.${NC}"
    mkdir -p "$DIR" && cd "$DIR" || return
    else
    echo -e "${Blue}Git directory already exists.${NC}"
    cd "$DIR" || return
fi

# Check to see if paru already exist, if not then make the PKGBUILD
if [ ! -d "$PARU" ]; then
    echo -e "${Red}Paru does not exist, cloning repo & building.${NC}"
    cd "$DIR" && git clone https://aur.archlinux.org/paru && cd "$PARU" && makepkg -si
    else
    echo -e "${Green}Paru directory already exists.${NC}"
fi

#Install packages with paru
echo -e "${Blue}Installing packages from the AUR.${NC}"
paru -S --needed \
  brave-bin \
  ookla-speedtest-bin \
  piavpn-bin \
  razergenie \
  github-desktop-bin \
  vmware-workstation \
  proton-ge-custom-bin \
  duckstation-git \
  pcsx2-git \
  rpcs3-bin \
  cemu \
  ryujinx \
  cava \
  python310 \
  nvim-lazy \
  zsh-fast-syntax-highlighting \
  zsh-theme-powerlevel10k-git \
  ctpv-git \
  kwin-effects-forceblur \
  kwin-polonium

#TODO: Create condition for kwin-polonium & kwin-forceblur if kde was chosen in the install

sudo systemctl enable --now \
  piavpn.service \
  vmware-networks.service \
  vmware-usbarbitrator.service
  sudo systemctl start vmware-networks-configuration.service

# Add user to plugdev group for razergenie
sudo gpasswd -a "$USER" plugdev
