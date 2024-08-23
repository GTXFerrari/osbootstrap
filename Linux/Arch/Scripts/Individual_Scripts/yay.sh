#!/usr/bin/env bash

# Path
git_dir="/home/$USER/Git"
yay_dir="/home/$USER/Git/yay"

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

echo -ne "${Cyan}This script should be ran as a standard user after rebooting from the install ISO, would you like to continue? (y/n) ${NC}"
read -r usr 
if [[ "$usr" == "n" ]]; then
    exit
fi

# Create Git directory and clone paru
if [ ! -d "$git_dir" ]; then
    echo -e "${Cyan}Git directory does not exist, creating directory.${NC}"
    mkdir -p "$git_dir" && cd "$git_dir" || return
    else
    echo -e "${Green}Git directory already exists.${NC}"
    cd "$DIR" || return
fi

# Check to see if yay already exist, if not then make the PKGBUILD
if [ ! -d "$yay_dir" ]; then
    echo -e "${Cyan}Yay does not exist, cloning repo & building.${NC}"
    cd "$git_dir" && git clone https://aur.archlinux.org/yay.git && cd "$yay_dir" && makepkg -si
    else
    echo -e "${Green}Yay directory already exists.${NC}"
    cd "$yay_dir" && makepkg -si
fi

#Install packages with yay
yay_log=/var/log/yay_apps.log
echo -e "${Cyan}Installing packages from the AUR.${NC}"
aur_apps=(
  brave-bin
  ookla-speedtest-bin
  piavpn-bin
  razergenie
  proton-ge-custom-bin
  duckstation-git
  pcsx2-git
  rpcs3-bin
  cemu
  ryujinx
  cava
  python310
  nvim-lazy
  zsh-fast-syntax-highlighting
  zsh-theme-powerlevel10k-git
  ctpv-git 
  vmware-workstation
)

for app in "${aur_apps[@]}"; do
	if ! sudo yay -S "$aur_apps" ; then
		echo -n "${Cyan}" Package Not found, skipping...$"{NC}"
		sudo echo "$aur_apps" >> "$yay_log"
		fi
	done

sudo systemctl enable --now piavpn.service vmware-networks.service vmware-usbarbitrator.service
sudo systemctl start vmware-networks-configuration.service
sudo gpasswd -a "$USER" plugdev
