#!/usr/bin/env bash

git_dir=$HOME/Git

sudo pacman -S --needed hyprland hypridle hyprlock kitty nwg-look wofi swww xdg-desktop-portal-hyprland grim slurp ttf-font-awesome otf-font-awesome lf nautilus polkit-gnome swayimg swaync

# Hyprpanel Setup
curl -fsSL https://bun.sh/install | bash &&
  sudo ln -s "$HOME"/.bun/bin/bun /usr/local/bin/bun

sudo pacman -S pipewire libgtop bluez bluez-utils btop networkmanager dart-sass wl-clipboard brightnessctl swww python gnome-bluetooth-3.0 pacman-contrib power-profiles-daemon
yay -S grimblast-git gpu-screen-recorder hyprpicker matugen-bin python-gpustat aylurs-gtk-shell-git
# Installs HyprPanel to ~/.config/ags
cd "$git_dir" && git clone https://github.com/Jas-SinghFSU/HyprPanel.git &&
  ln -s "$(pwd)"/HyprPanel "$HOME"/.config/ags
