#!/usr/bin/env bash

cred_dir="/etc/samba/credentials"
share_file="/etc/samba/credentials/share"
truenas_dir="/mnt/truenas"
nas_addr="//10.0.40.5"
smb_options="_netdev,nofail,file_mode=0777,dir_mode=0777,credentials=/etc/samba/credentials/share 0 0"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run the script using sudo or as root!"
fi

# Check dependencies
echo "Checking script dependencies"
sleep 2
while true; do
  if pacman -Qi gum >/dev/null 2>&1; then
    break
  else
    pacman -S --noconfirm gum cifs-utils
  fi
done

gum style --foreground="#00ff28" --bold "Setting Up SMB Shares"

if [[ ! -d "$cred_dir" ]]; then
  mkdir -p $cred_dir
fi

if [[ -e $share_file ]]; then
  gum style --foreground="#00ff28" --bold "Share file already exists"
else
  touch $share_file
fi

smb_user=$(gum input --placeholder="Enter SMB Username")
echo "username=$smb_user" | tee -a "$share_file" >/dev/null
smb_pass=$(gum input --placeholder="Enter SMB Password")
echo "password=$smb_pass" | tee -a "$share_file" >/dev/null
gum style --foreground="#00ff28" --bold "Updating permissions..."
sleep 2
chown root:root "$cred_dir" && chmod 700 "$cred_dir" && chmod 600 "$share_file"

if [[ ! -d $truenas_dir ]]; then
  mkdir -p /mnt/truenas/{media,stash,jake}
fi

{
  echo " "
  echo "$nas_addr"/Jake "$truenas_dir"/jake cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Stash "$truenas_dir"/stash cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Media "$truenas_dir"/media cifs "$smb_options"

} | tee -a /etc/fstab >/dev/null
