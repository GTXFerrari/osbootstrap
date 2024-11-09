#!/usr/bin/env bash

sudo pacman -S --needed hyprland xdg-desktop-portal-hyprland hypridle hyprlock nwg-look wofi swww grim slurp ttf-font-awesome otf-font-awesome lf swayimg kitty

# Hyprpanel Setup
curl -fsSL https://bun.sh/install | bash &&
  sudo ln -s "$HOME"/.bun/bin/bun /usr/local/bin/bun

sudo pacman -S pipewire libgtop bluez bluez-utils btop networkmanager dart-sass wl-clipboard brightnessctl swww python gnome-bluetooth-3.0 pacman-contrib power-profiles-daemon
yay -S grimblast-git gpu-screen-recorder hyprpicker matugen-bin python-gpustat aylurs-gtk-shell-git
# Installs HyprPanel to ~/.config/ags
git clone https://github.com/Jas-SinghFSU/HyprPanel.git ~/Git/HyprPanel
ln -s "$(pwd)"/HyprPanel "$HOME"/.config/ags
