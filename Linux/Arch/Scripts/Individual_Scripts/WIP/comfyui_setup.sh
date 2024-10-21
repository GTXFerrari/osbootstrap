#!/usr/bin/env bash

git_dir=/home/$USER/Git
comfy_dir=/home/$USER/Git/ComfyUI

if [[ ! -d "$git_dir" ]]; then
  mkdir /home/"$USER"/Git
fi

while true; do
  if pacman -Qi git >/dev/null 2>&1; then
    break
  else
    sudo pacman -S --noconfirm git
  fi
done

if [[ ! -d $comfy_dir ]]; then
  git clone https://github.com/comfyanonymous/ComfyUI.git "$git_dir/ComfyUI"
fi

ln -s "$HOME/AI/Image Generation/Models/Prefect Pony XL/Checkpoints/*" "$HOME/AI/Image Generation/ComfyUI/models/checkpoints/"

# FLUX Setup
"$HOME/AI/Image Generation/Models/FLUX/gguf/
