#!/bin/bash
pacman -S xorg plasma kde-applications plasma-nm packagekit-qt5 sddm
systemctl enable sddm
##NOTE## Add plasma-nm to kde taskbar via Panel options > Add Widgets > Networks menu
