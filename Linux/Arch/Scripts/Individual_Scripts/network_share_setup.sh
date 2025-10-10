#!/usr/bin/env bash

cred_dir="/etc/samba/credentials"
share_file="/etc/samba/credentials/share"
truenas_dir="/mnt/truenas"
nas_addr="//10.0.40.5"
smb_options="_netdev,nofail,file_mode=0777,dir_mode=0777,credentials=/etc/samba/credentials/share 0 0"

# Check dependencies
echo "Checking script dependencies"
sleep 2
if [[ -f /etc/debian_version ]]; then
  sudo apt update && sudo apt install cifs-utils
elif [[ -f /etc/arch_release ]]; then
  sudo pacman -Sy && sudo pacman -S --noconfirm gum cifs-utils
fi

gum style --foreground="#00ff28" --bold "Setting Up SMB Shares"

if [[ ! -d "$cred_dir" ]]; then
  sudo mkdir -p $cred_dir
fi

if [[ -e $share_file ]]; then
  gum style --foreground="#00ff28" --bold "Share file already exists"
else
  sudo touch $share_file
fi

smb_user=$(gum input --placeholder="Enter SMB Username")
echo "username=$smb_user" | sudo tee -a "$share_file" >/dev/null
smb_pass=$(gum input --placeholder="Enter SMB Password")
echo "password=$smb_pass" | sudo tee -a "$share_file" >/dev/null
gum style --foreground="#00ff28" --bold "Updating permissions..."
sleep 2
sudo chown root:root "$cred_dir" && sudo chmod 700 "$cred_dir" && sudo chmod 600 "$share_file"

if [[ ! -d $truenas_dir ]]; then
  sudo mkdir -p /mnt/truenas/{media,stash,backups,gold}
fi

{
  echo " "
  echo "$nas_addr"/Backups "$truenas_dir"/backups cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Stash "$truenas_dir"/stash cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Media "$truenas_dir"/media cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Gold "$truenas_dir"/gold cifs "$smb_options"

} | sudo tee -a /etc/fstab >/dev/null

sudo systemctl daemon-reload && sudo mount -a
