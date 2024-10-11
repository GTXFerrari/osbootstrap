#!/usr/bin/env bash

while true; do
  if pacman -Qi ollama-cuda >/dev/null 2>&1; then
    break
  else
    sudo pacman -S --noconfirm ollama-cuda
  fi
done

# Make ollama available over the network
if [[ ! -d /etc/systemd/system/ollama.service.d ]]; then
  sudo mkdir /etc/systemd/system/ollama.service.d
fi

echo '[Service]
Environment="OLLAMA_HOST=0.0.0.0"' | sudo tee /etc/systemd/system/ollama.service.d/http-host.conf

sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service
