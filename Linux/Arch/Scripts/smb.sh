#!/usr/bin/env bash

# Variables
DIR="/etc/samba/credentials"
SHARE="/etc/samba/credentials/share"
TRUENAS="/mnt/truenas"
NAS="//10.0.40.5"
OPT="file_mode=0777,dir_mode=0777,_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"

# Colors
NC='\033[0m' # No Color
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

echo -e "${Blue}Downloading prerequisite packages.${NC}"
sudo pacman -S --needed --noconfirm cifs-utils
# Create a trueNAS directory with share mountpoints
if [ ! -d "$TRUENAS" ]; then
    echo -e "${Red}TrueNAS directory does not exist, creating.${NC}"
    sudo mkdir -p "$TRUENAS" && cd "$TRUENAS" && sudo mkdir jake gold stash stash2 media iso
    else
    echo -e "${Blue}TrueNAS directory already exists.${NC}"
    cd "$TRUENAS" && sudo mkdir jake gold stash media iso 
fi

# Create /etc/samba/credentials directory
if [ ! -d "$DIR" ]; then
    echo -e "${Red}Credentials directory does not exist, creating directory.${NC}"
    sudo mkdir -p /etc/samba/credentials
    else
    echo -e "${Blue}Credentials directory already exists.${NC}"
fi

# Create the share file
if [ ! -d "$SHARE" ]; then 
    echo -e "${Red}Share file does not exist, creating file.${NC}"
    sudo touch "$SHARE"
    echo "username=$USER" | sudo tee -a "$SHARE" > /dev/null 
    echo -n Password:
    read -r Password
    echo "password=$Password" | sudo tee -a "$SHARE" > /dev/null 
 else
    echo -e "${Blue}Share file already exists.${NC}"
fi    

# Change ownership and file attributes of newly created directories and files
if [ -d "$SHARE" ]; then
    echo -e "${Blue}Changing permissions.${NC}"
    chown root:root "$DIR" && chmod 700 "$DIR" && chmod 600 "$SHARE"
fi

# Add SMB share to fstab for automounting
{
    echo " "
    echo "$NAS"/Jake       "$TRUENAS"/jake         cifs        "$OPT"
    echo " "
    echo "$NAS"/Stash        "$TRUENAS"/stash          cifs        "$OPT"
    echo " "
    echo "$NAS"/Stash2        "$TRUENAS"/stash2          cifs        "$OPT"
    echo " "
    echo "$NAS"/Media      "$TRUENAS"/media        cifs        "$OPT"
    echo " "
    echo "$NAS"/Gold         "$TRUENAS"/gold           cifs        "$OPT"
    echo " "
    echo "$NAS"/ISO         "$TRUENAS"/iso         cifs        "$OPT"

} | sudo tee -a /etc/fstab > /dev/null
echo -e "${Blue}Mounting Shares.${NC}"
sudo systemctl daemon-reload && sudo mount -a
