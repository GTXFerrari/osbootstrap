#!/usr/bin/env bash
window_manager() {
  echo -n "Would you like to install a window manager (y/n)"
  read -r window_manager 
  if [[ $window_manager == "y" ]]; then

PS3='Please enter your choice: '
options=("Dwm" "Bspwm" "Awesome" "i3" "Xmonad" "None")
dm="lightdm lightdm-gtk-greeter lightdm-webkit2-greeter"
x11="xorg-server xorg-xinit xorg-xsetroot"
base="nitrogen picom qt5ct lxappearance gnome-themes-extra dunst polkit polkit-gnome gnome-keyring libsecret seahorse ttf-joypixels"
dir="/home/jake/Git"
dwm="/home/jake/Git/dwm"
dmenu="/home/jake/Git/dmenu"
st="/home/jake/Git/st"
dwmblocks="/home/jake/Git/dwmblocks"
git="git clone https://github.com/gtxferrari"
select opt in "${options[@]}"
do
    case $opt in 
        "Dwm")
            pacman -S --needed "$x11" "$base" "$dm" sxhkd 
            if [ ! -d "$dir" ]; then
                echo "Git directory does not exist, creating directory"
                mkdir -p "$dir" && cd "$dir" || return
            else
                echo "Git directory already exists" 
                cd "$dir" || return
            fi
            if [ ! -d "$dwm" ]; then
                echo "dwm does not exist, cloning repo & compiling"
                cd "$dir" && "$git"/dwm && cd "$dir"/dwm make && sudo make clean install
                echo "Finished compiling & installing dwm"
            else
                echo "dwm already exists, reinstalling"
                cd "$dwm" && make && sudo make clean install
                echo "Finished reinstalling dwm"
            fi
            if [ ! -d "$dmenu" ]; then
                echo "dmenu does note exist, cloning repo & compiling"
                cd "$dir" && "$git"/dmenu && cd "$dir"/dmenu && make && sudo make clean install
                echo "Finished compiling & installing dmenu"
            else
                echo "dmenu already exists, reinstalling"
                cd "$dir"/dmenu && make && sudo make clean install
                echo "Finished reinstalling dmenu"
            fi
            if [ ! -d "$st" ]; then
                echo "st does not exist, cloning repo & compiling"
                cd "$dir" && "$git"/st && cd "$dir"/st && make && sudo make clean install
                echo "Finished compiling & installing st"
            else
                echo "st already exists, reinstalling"
                cd "$dir"/st && make && sudo make clean install
                echo "Finished reinstalling st"
            fi
            if [ ! -d "$dwmblocks" ]; then
                echo "dwmblocks does not exist, cloning repo & compiling"
                cd "$dir" && "$git"/dwmblocks && cd "$dir"/dwmblocks && make && sudo make clean install
                echo "Finished installing & compiling dwmblocks"
            else 
                echo "dwmblocks already exists, reinstalling"
                cd "$dir"/dwmblocks && make && sudo make clean install
                echo "Finished reinstalling dwmblocks"
            fi
            break
            ;;
        "Bspwm")
            pacman -S --needed  "$x11" "$base" "$dm" sxhkd bspwm rofi
            systemctl enable lightdm.service
            break
            ;;
        "Awesome")
            pacman -S --needed "$x11" "$base" "$dm" sxhkd awesome 
            systemctl enable lightdm.service
            break
            ;;
        "i3")
            pacman -S --needed "$x11" "$dm" sxhkd i3 dmenu 
            systemctl enable lightdm.service
            break
            ;;
        "Xmonad")
            pacman -S --needed "$x11" "$dm" sxhkd xmonad xmonad-contrib dmenu
            systemctl enable lightdm.service
            break
            ;;
        "None")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
 done
fi
}
window_manager
