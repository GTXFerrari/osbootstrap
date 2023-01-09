#!/bin/bash
pacman -S xorg gnome gnome-extra gnome-tweaks gnome-themes-extra gdm
systemctl enable gdm.service
