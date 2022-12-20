#!/bin/bash

# Variables
DIR="/home/jake/Git"
PARU="/home/jake/Git/paru"


# Create Git directory and clone paru
if [ -d "$DIR" ]; then
    echo "Git directory aleady exist"
    cd $DIR
fi

if [ ! -d "$DIR" ]; then
    echo "Git directory does not exist, Creating directory"
    mkdir -p $DIR && cd $DIR
fi

# Check to see if paru already exist, if not then make the PKGBUILD
if [ -d "$PARU" ]; then
    echo "paru directory already exist"
fi

if [ ! -d "$PARU" ]; then
    echo "paru directory does not exist, cloning repo"
    cd $DIR
    git clone https://aur.archlinux.org/paru
    cd $PARU
    makepkg -si
fi

#Install packages with paru
paru -S --needed betterdiscord-installer brave-bin cider fastfetch-git gdlauncher-bin mangohud noto-fonts-emoji-apple nsxiv ookla-speedtest-bin openrgb pfetch piavpn-bin proton-ge-custom-bin razergenie visual-studio-code-bin github-desktop-bin vmware-workstation cpu-x gwe duckstation-git pcsx2-git cemu yuzu-early-access lf goverlay-bin vkbasalt nvim-packer-git ccat zsh-fast-syntax-highlighting nerd-fonts-complete zsh-theme-powerlevel10k-git rpcs3-git

# Enable systemd services
sudo systemctl enable --now piavpn.service
sudo systemctl start vmware-networks-configuration.service
sudo systemctl enable --now vmware-networks.service
sudo systemctl enable --now vmware-usbarbitrator.service

# Add user to plugdev group for razergenie
sudo gpasswd -a jake plugdev
