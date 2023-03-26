#!/usr/bin/env bash
# Variables
DIR="/home/jake/Git"
PARU="/home/jake/Git/paru"
echo -n "This script should be ran as a standard user after rebooting from the install ISO, would you like to continue? (y/n) "
read -r usr 
if [[ "$usr" == "n" ]]; then
    exit
fi
# Create Git directory and clone paru
if [ ! -d "$DIR" ]; then
    echo "Git directory does not exist, creating directory"
    mkdir -p "$DIR" && cd "$DIR" || return
    else
    echo "Git directory already exists"
    cd "$DIR" || return
fi
# Check to see if paru already exist, if not then make the PKGBUILD
if [ ! -d "$PARU" ]; then
    echo "Paru does not exist, cloning repo & building"
    cd "$DIR" && git clone https://aur.archlinux.org/paru && cd "$PARU" && makepkg -si
    else
    echo "Paru directory already exists"
fi
#Install packages with paru
echo "Installing packages from the AUR"
paru -S --needed betterdiscord-installer brave-bin cider fastfetch-git gdlauncher-bin mangohud noto-fonts-emoji-apple nsxiv ookla-speedtest-bin openrgb pfetch piavpn-bin proton-ge-custom-bin razergenie visual-studio-code-bin vmware-workstation cpu-x duckstation-git pcsx2-git cemu lf goverlay-bin nvim-packer-git zsh-fast-syntax-highlighting zsh-theme-powerlevel10k-git rpcs3-git adwaita-qt5 adwaita-qt6 xone-dkms
# zramd
echo -n "Would you like to use zramd for your swap? (y/n) "
read -r zram
if [[ "$zram" == "y" ]]; then
    paru -S --needed zramd
fi
# Enable systemd services
sudo systemctl enable --now piavpn.service vmware-networks.service vmware-usbarbitrator.service zramd.service
sudo systemctl start vmware-networks-configuration.service
# Add user to plugdev group for razergenie
sudo gpasswd -a "$USER" plugdev
