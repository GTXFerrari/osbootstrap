#!/usr/bin/env bash

# Path
git_dir="/home/$USER/Git"
yay_dir="/home/$USER/Git/yay"

# Create checks for gum
pacman -S --needed gum

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
echo -e "${Cyan}Installing packages from the AUR.${NC}"
yay -S brave-bin ookla-speedtest-bin piavpn-bin razergenie proton-ge-custom-bin duckstation-git pcsx2-git rpcs3-bin cemu ryujinx cava python311 nvim-lazy zsh-fast-syntax-highlighting zsh-theme-powerlevel10k-git ctpv-git vmware-workstation

sudo systemctl enable --now piavpn.service vmware-networks.service vmware-usbarbitrator.service
sudo systemctl start vmware-networks-configuration.service
sudo gpasswd -a "$USER" plugdev
