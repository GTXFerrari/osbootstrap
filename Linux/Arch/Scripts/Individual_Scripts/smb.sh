#!/usr/bin/env bash

cred_dir="/etc/samba/credentials"
share_file="/etc/samba/credentials/share"
truenas_dir="/mnt/truenas"
nas_addr="//10.0.40.5"
smb_options="file_mode=0777,dir_mode=0777,_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"
echo -e "${Green}Setting up SMB shares${NC}"
sleep 1
sudo pacman -S --needed --noconfirm cifs-utils
if [[ ! -d "$cred_dir" ]]; then
  mkdir -p $cred_dir
fi
if [[ -e $share_file ]]; then
  echo -e "${Green}Share file already exists${NC}"
else
  touch $share_file
fi
echo -n Enter Username:
read -r Username
echo "username=$Username" | sudo tee -a "$share_file" >/dev/null
echo -n Enter Password:
read -r Password
echo "password=$Password" | sudo tee -a "$share_file" >/dev/null
echo -e "${Green}Updating permissions${NC}"
sleep 1
chown root:root "$cred_dir" && chmod 700 "$cred_dir" && chmod 600 "$share_file"
if [[ ! -d $truenas_dir ]]; then
  sudo mkdir -p /mnt/truenas/{media,iso,photos,gold,stash,stash2,jake}
fi
{
  echo " "
  echo "$nas_addr"/Jake "$truenas_dir"/jake cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Stash "$truenas_dir"/stash cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Stash2 "$truenas_dir"/stash2 cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Media "$truenas_dir"/media cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Gold "$truenas_dir"/gold cifs "$smb_options"
  echo " "
  echo "$nas_addr"/ISO "$truenas_dir"/iso cifs "$smb_options"
  echo " "
  echo "$nas_addr"/Photos "$truenas_dir"/photos cifs "$smb_options"

} | sudo tee -a /etc/fstab >/dev/null
