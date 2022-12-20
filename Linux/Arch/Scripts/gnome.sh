#!/bin/bash

CHEZ="chezmoi init --apply https://github.com/gtxferrari/dotfiles"

# Install dots
$CHEZ

sudo pacman -S xorg gnome gnome-extra gnome-tweaks gnome-themes-extra
