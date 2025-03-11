#!/usr/bin/env bash

# Gum Install
wget https://github.com/charmbracelet/gum/releases/download/v0.15.2/gum_0.15.2_amd64.deb
sudo dpkg -i gum_0.15.2_amd64.deb

# Install Apps
sudo apt update && sudo apt full-upgrade
sudo apt install htop git cifs-utils rsync

# Neovim
sudo apt-get install ninja-build gettext cmake curl build-essential file
git clone https://github.com/neovim/neovim && cd neovim || exit
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build && cpack -G DEB && sudo dpkg -i nvim-linux-x86_64.deb

# Docker
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker

# Network Share Setup
git clone https://github.com/gtxferrari/osbootstrap
sh osbootstrap/Linux/Arch/Scripts/Individual_Scripts/network_share_setup.sh || exit
