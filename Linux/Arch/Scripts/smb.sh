#!/bin/bash

# Variables
DIR="/etc/samba/credentials"
SHARE="/etc/samba/credentials/share"
TRUENAS="/home/jake/TrueNAS"
NAS="//10.0.40.5"
OPT="_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"

# Create a TrueNAS directory with share mountpoints
if [ -d "$TRUENAS" ]; then
    echo "TrueNAS directory already exist"
fi

if [ ! -d "$TRUENAS" ]; then
    echo "TrueNAS directory does not exist, creating directory with mountpoints"
    mkdir -p $TRUENAS && cd $TRUENAS
    mkdir -p Jake EMP Assets Media MP
    echo "Finished creating directories"
fi

# Create /etc/samba/credentials directory
if [ -d "$DIR" ]; then
    echo "Credentials directory already exist"
    cd $DIR
fi

if [ ! -d "$DIR" ]; then
    echo "Credentials directory does not exist, Creating directory"
    mkdir -p $DIR && cd $DIR
fi

# Create the share file
if [ -d "$SHARE" ]; then
    echo "Share file already exist"
fi

if [ ! -d "$SHARE" ]; then
    echo "Share file does not exist, creating file"
    touch $SHARE
    echo "username=jake" >> $SHARE
    echo -n Password:
    read -s password
    echo
    echo password=$password >> $SHARE
fi

# Change ownership and file attributes of newly created directories and files
if [ -d "$SHARE" ]; then
    echo "Changing permissions"
    chown root:root $DIR
    chmod 700 $DIR
    chmod 600 $SHARE
fi

# Add SMB share to fstab for automounting

echo " " >> /etc/fstab
echo "$NAS/Jake              $TRUENAS/Jake           cifs            $OPT" >> /etc/fstab
echo " " >> /etc/fstab
echo "$NAS/Media             $TRUENAS/Media          cifs            $OPT" >> /etc/fstab
echo " " >> /etc/fstab
echo "$NAS/Assets            $TRUENAS/Assets         cifs            $OPT" >> /etc/fstab
echo " " >> /etc/fstab
echo "$NAS/MP                $TRUENAS/MP             cifs            $OPT" >> /etc/fstab
echo " " >> /etc/fstab
echo "$NAS/EMP                $TRUENAS/EMP             cifs            $OPT" >> /etc/fstab

systemctl daemon-reload
mount -a

