#!/bin/bash

# Variables
DIR="/home/jake/Git"
DWM="/home/jake/Git/dwm"
DMENU="/home/jake/Git/dmenu"
ST="/home/jake/Git/st"
DWMBLOCKS="/home/jake/Git/dwmblocks"
GIT="git clone https://github.com/gtxferrari"

# Create Git directory if it does not exist
if [ -d "$DIR" ]; then
    echo "Git directory already exist"
    cd $DIR
fi

if [ ! -d "$DIR" ]; then
    echo "Git directory does not exist, Creating directory"
    mkdir -p $DIR && cd $DIR
fi

# Check to see if dwm exist, if not clone repo
if [ -d "$DWM" ]; then
    echo "dwm already exist"
    cd $DWM
    make
    sudo make clean install
    echo "Finished compiling & installing dwm"
fi


if [ ! -d "$DWM" ]; then
    echo "dwm does not exist, Cloning repo"
    cd $DIR
    $GIT/dwm && cd $DWM
    make
    sudo make clean install
    echo "Finished compiling & installing dwm"
fi

# Check to see if dmenu exist, if not clone repo
if [ -d "$DMENU" ]; then
    echo "dmenu already exist"
    cd $DMENU
    make
    sudo make clean install
    echo "Finished compiling & installing dmenu"
fi


if [ ! -d "$DMENU" ]; then
    echo "dmenu does not exist, Cloning repo"
    cd $DIR
    $GIT/dmenu && cd $DMENU
    make
    sudo make clean install
    echo "Finished compiling & installing dmenu"
fi

# Check to see if st exist, if not clone repo
if [ -d "$ST" ]; then
    echo "st already exist"
    cd $ST
    make
    sudo make clean install
    echo "Finished compiling & installing st"
fi


if [ ! -d "$ST" ]; then
    echo "st does not exist, Cloning repo"
    cd $DIR
    $GIT/st && cd $ST
    make
    sudo make clean install
    echo "Finished compiling & installing st"
fi

# Check to see if dwmblocks exist, if not clone repo
if [ -d "$DWMBLOCKS" ]; then
    echo "dwmblocks already exist"
fi

if [ ! -d "$DWMBLOCKS" ]; then
    echo "dwmblocks does not exist, Cloning repo"
    cd $DIR
    $GIT/dwmblocks
    echo "Finished cloning dwmblocks"
fi

sudo pacman -S xorg-server xorg-xinit nitrogen picom qt5ct lxappearance gnome-themes-extra dunst gnome-keyring libsecret seahorse ttf-joypixels xorg-xsetroot polkit polkit-gnome
