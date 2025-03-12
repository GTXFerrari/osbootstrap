#!/usr/bin/env bash

# Gum Install
wget https://github.com/charmbracelet/gum/releases/download/v0.15.2/gum_0.15.2_amd64.deb
sudo dpkg -i gum_0.15.2_amd64.deb

# ZSH Setup
sudo apt install zsh git -y
sudo git clone https://github.com/zdharma-continuum/fast-syntax-highlighting /usr/share/zsh/plugins /usr/share/zsh/plugins/fast-syntax-highlighting
sudo git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh/plugins/zsh-autosuggestions
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/zsh-theme-powerlevel10k
chsh -s /usr/bin/zsh

# Install Apps
sudo apt update && sudo apt full-upgrade
sudo apt install htop git cifs-utils rsync -y

# Neovim
sudo apt-get install ninja-build gettext cmake curl build-essential file
git clone https://github.com/neovim/neovim && cd neovim || exit
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build && cpack -G DEB && sudo dpkg -i nvim-linux-x86_64.deb

# Docker
sudo apt-get install ca-certificates curl -y
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
git clone https://github.com/gtxferrari/osbootstrap /home/"$USER"
bash /home/$USER/osbootstrap/Linux/Arch/Scripts/Individual_Scripts/network_share_setup.sh

# APT Setup (Add non-free & contrib and update to trixie)
sudo sed -i '/^deb/ s/$/ contrib non-free/' /etc/apt/sources.list
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
sudo apt update && sudo apt full-upgrade
sudo apt autoremove
