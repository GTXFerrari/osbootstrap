#!/usr/bin/env bash
# Variables

# Path
DIR="/home/jake/Git"
PARU="/home/jake/Git/paru"

# Colors
NC='\033[0m' # No Color

# Regular Colors
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

echo -n -e "${Blue}This script should be ran as a standard user after rebooting from the install ISO, would you like to continue? (y/n) ${NC}"
read -r usr 
if [[ "$usr" == "n" ]]; then
    exit
fi

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
  fastfetch-git \
  ookla-speedtest-bin \
  openrgb \
  pfetch \
  piavpn-bin \
  proton-ge-custom-bin \
  razergenie \
  visual-studio-code-bin \
  github-desktop-bin \
  vmware-workstation \
  cpu-x \
  duckstation-git \
  pcsx2-git \
  cemu \
  nvim-lazy \
  zsh-fast-syntax-highlighting \
  zsh-theme-powerlevel10k-git \
  rpcs3-git \
  cava \

# Enable systemd services
sudo systemctl enable --now \
  piavpn.service \
  vmware-networks.service \
  vmware-usbarbitrator.service
sudo systemctl start vmware-networks-configuration.service

# Add user to plugdev group for razergenie
sudo gpasswd -a "$USER" plugdev
