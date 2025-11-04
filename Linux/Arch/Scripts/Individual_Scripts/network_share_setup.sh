#!/usr/bin/env bash

cred_dir="/etc/samba/credentials"
smb_share_file="/etc/samba/credentials/share"
truenas_dir="/mnt/truenas"
smb_nas_addr="//10.0.40.5"
smb_options="_netdev,nofail,credentials=/etc/samba/credentials/share 0 0"
nfs_nas_addr="truenas.local:"
nfs_options="defaults,timeo=900,retrans=5,_netdev 0 0"

# Check dependencies
dependencies_check() {
  echo "Checking script dependencies"
  sleep 2
  if [[ -f /etc/debian_version ]]; then
    sudo apt update && sudo apt install cifs-utils nfs-utils
  elif [[ -f /etc/arch_release ]]; then
    sudo pacman -Sy && sudo pacman -S --noconfirm gum cifs-utils nfs-utils
  fi
}

create_smb_share_files() {
  gum style --foreground="#00ff28" --bold "Setting Up Network Shares"

  if [[ ! -d "$cred_dir" ]]; then
    sudo mkdir -p $cred_dir
  fi

  if sudo test -f $smb_share_file; then
    gum style --foreground="#00ff28" --bold "Share file already exists"
  else
    sudo touch $smb_share_file
    smb_user=$(gum input --placeholder="Enter SMB Username")
    echo "username=$smb_user" | sudo tee -a "$smb_share_file" >/dev/null
    smb_pass=$(gum input --placeholder="Enter SMB Password")
    echo "password=$smb_pass" | sudo tee -a "$smb_share_file" >/dev/null
    gum style --foreground="#00ff28" --bold "Updating permissions..."
    sleep 2
    sudo chown root:root "$cred_dir" && sudo chmod 700 "$cred_dir" && sudo chmod 600 "$smb_share_file"
  fi
}

create_share_dirs() {
  if [[ ! -d $truenas_dir ]]; then
    sudo mkdir -p /mnt/truenas/smb/{media,stash,backups}
    sudo mkdir -p /mnt/truenas/nfs/{media,stash,backups}
  fi
}

fstab_automount_setup() {
  gum style --foreground="#00BBFF" "Setting up automounts in /etc/fstab"
  {
    echo " "
    echo "# SMB Shares"
    echo "$smb_nas_addr"/Backups "$truenas_dir"/smb/backups cifs "$smb_options"
    echo " "
    echo "$smb_nas_addr"/Stash "$truenas_dir"/smb/stash cifs "$smb_options"
    echo " "
    echo "$smb_nas_addr"/Media "$truenas_dir"/smb/media cifs "$smb_options"
    echo " "
    echo "# NFS Shares"
    echo "$nfs_nas_addr""/mnt/Alpha\040Centauri/Media_Dataset" /mnt/truenas/nfs/media nfs "$nfs_options"
    echo " "
    echo "$nfs_nas_addr""/mnt/Alpha\040Centauri/Backups_Dataset" /mnt/truenas/nfs/backups nfs "$nfs_options"
    echo " "
    echo "$nfs_nas_addr""/mnt/VY\040Canis\040Majoris/Media_Dataset" /mnt/truenas/nfs/stash nfs "$nfs_options"

  } | sudo tee -a /etc/fstab >/dev/null

  sudo systemctl daemon-reload && sudo mount -a
}

dependencies_check
create_share_dirs
create_smb_share_files
fstab_automount_setup
