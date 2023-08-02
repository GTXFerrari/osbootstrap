#!/usr/bin/env bash
# Variables
DIR="/etc/samba/credentials"
SHARE="/etc/samba/credentials/share"
TRUENAS="/home/jake/TrueNAS"
NAS="//10.0.40.5"
OPT="file_mode=0777,dir_mode=0777,_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"
echo "Downloading prerequisite packages"
sudo pacman -S --needed --noconfirm cifs-utils
# Create a TrueNAS directory with share mountpoints
if [ ! -d "$TRUENAS" ]; then
    echo "TrueNAS directory does not exist, creating"
    mkdir -p "$TRUENAS" && cd "$TRUENAS" && mkdir Jake MP LTS Media Media2 ISO
    else
    echo "TrueNAS directory already exists"
    cd "$TRUENAS" && mkdir Jake MP LTS Media Media2 ISO
fi
# Create /etc/samba/credentials directory
if [ ! -d "$DIR" ]; then
    echo "Credentials directory does not exist, creating directory"
    sudo mkdir -p /etc/samba/credentials
    else
    echo "Credentials directory already exists"
fi
# Create the share file
if [ ! -d "$SHARE" ]; then 
    echo "Share file does not exist, creating file"
    sudo touch "$SHARE"
    echo "username=$USER" | sudo tee -a "$SHARE" > /dev/null 
    echo -n Password:
    read -r Password
    echo "password=$Password" | sudo tee -a "$SHARE" > /dev/null 
 else
    echo "Share file already exists"
fi    
# Change ownership and file attributes of newly created directories and files
if [ -d "$SHARE" ]; then
    echo "Changing permissions"
    chown root:root "$DIR" && chmod 700 "$DIR" && chmod 600 "$SHARE"
fi
# Add SMB share to fstab for automounting
{
    echo " "
    echo "$NAS"/Jake       "$TRUENAS"/Jake         cifs        "$OPT"
    echo " "
    echo "$NAS"/LTS        "$TRUENAS"/LTS          cifs        "$OPT"
    echo " "
    echo "$NAS"/Media      "$TRUENAS"/Media        cifs        "$OPT"
    echo " "
    echo "$NAS"/MP         "$TRUENAS"/MP           cifs        "$OPT"
    echo " "
    echo "$NAS"/Media2     "$TRUENAS"/Media2       cifs        "$OPT"
    echo " "
    echo "$NAS"/ISO         "$TRUENAS"/ISO         cifs        "$OPT"

} | sudo tee -a /etc/fstab > /dev/null
echo "Mounting Shares"
systemctl daemon-reload && sudo mount -a
