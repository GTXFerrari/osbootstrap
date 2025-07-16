#!/usr/bin/env bash

# Logging
Logging() {
  exec > >(tee -i /var/log/archinstall.log)
  exec 2>&1
}

check_internet_connection() {
  websites=("archlinux.org" "google.com" "example.com")
  for site in "${websites[@]}"; do
    if ping -c 1 "$site" >/dev/null 2>&1; then
      return 0
    fi
  done
}

internet_check() {
  if check_internet_connection; then
    return 0
  else
    echo "No internet, check your connection. (To connect to wireless type iwctl)"
    sleep 5
    exit 1
  fi
}

check_dependencies() {
  while true; do
    if pacman -Qi gum >/dev/null 2>&1; then
      break
    else
      pacman -S --noconfirm gum
    fi
  done
}

vm_check() {
  gum style --foreground="#00ff28" --bold "Checking if machine is virtualized"
  sleep 2
  VM_TYPE=$(systemd-detect-virt)
  if [[ "$VM_TYPE" == "none" ]]; then
    VM_STATUS="bare_metal"
  elif [[ "$VM_TYPE" == "kvm" ]]; then
    VM_STATUS="kvm"
  elif [[ "$VM_TYPE" == "vmware" ]]; then
    VM_STATUS="vmware"
  else
    gum style --foreground="#227fb0" --bold "The system is using an unsupported VM type"
    sleep 5
    VM_STATUS="other"
  fi
  export VM_STATUS
}

termfonts() {
  gum style --foreground="#00ff28" --bold "Adjusting Fonts"
  sleep 2
  if [[ "$VM_STATUS" == "bare_metal" ]]; then
    setfont ter-132b
  else
    setfont ter-124b
  fi
}

check_uefi() {
  gum style --foreground="#00ff28" --bold "Checking UEFI Settings"
  if [[ -d /sys/firmware/efi/efivars/ ]]; then
    gum style --foreground="#00ff28" --bold "System is booted using UEFI, proceeding"
    sleep 2
  else
    gum style --foreground="#ff0000" --bold "System is not booted using UEFI, change in the BIOS before proceeding"
    sleep 5
    exit 1
  fi

  efi_platform_size_file="/sys/firmware/efi/fw_platform_size"
  if [[ -e "$efi_platform_size_file" ]]; then
    value=$(cat "$efi_platform_size_file")
  fi
  if [[ "$value" -eq 64 ]]; then
    gum style --foreground="#00ff28" --bold "The system is using a 64-bit UEFI, GRUB & systemd-boot are supported"
    uefi="64"
    sleep 2
  else
    gum style --foreground="#00ff28" --bold "The system is using a 32-bit UEFI, Only systemd-boot are supported"
    uefi="32"
    sleep 2
  fi
  export uefi
}

#TODO: Create option for mdadm $raid variable
drive_partition() {
  while true; do
    gum style --foreground="#00ff28" --bold "Available Disk Partitions:"
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
    partition_choice=$(gum input --placeholder "Enter Your Drive Partition For Installation (Ex. sda || vda || nvme0n1")
    export partition_choice
    #TODO: Test with vda/sda in a vm
    if [[ "$partition_choice" == nvme* ]]; then
      partition_suffix="p"
    fi
    export partition_suffix
    if [[ -e "/dev/$partition_choice" ]]; then
      sgdisk -Z /dev/"$partition_choice"
      sgdisk --clear --new=1:0:+2G --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:system /dev/"$partition_choice"
      break
    else
      gum style --foreground="#ff0000" --bold "Partition does not exist"
      sleep 3
    fi
  done

  #NOTE: Encryption
  encryption=$(gum choose --limit=1 --header="Would you like to use encryption?" "Yes" "No")
  if [[ "$encryption" == "Yes" ]]; then
    cryptsetup luksFormat --type luks2 --align-payload=4096 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/"${partition_choice}""${partition_suffix}"2
    cryptsetup open /dev/"${partition_choice}""${partition_suffix}2" cryptarch
  fi

  while true; do
    chosen_filesystem=$(gum choose --limit=1 --header="Choose your filesystem type:" "Btrfs" "Xfs" "Ext4")
    filesystem_verify=$(gum choose --limit=1 --header="Did you choose $chosen_filesystem?" "Yes" "No")
    if [[ $filesystem_verify == "Yes" ]]; then
      break
    fi
  done
  export chosen_filesystem

  if [[ $chosen_filesystem == "Btrfs" && $encryption == "Yes" ]]; then
    mkfs.btrfs -L archbtrfs /dev/mapper/cryptarch
    mount /dev/mapper/cryptarch /mnt
    gum style --foreground="#00ff28" --bold "Setting up subvolumes"
    sleep 2
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@libvirt
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@tmp
    umount -R /mnt
    mount_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
    mount -o ${mount_opts},subvol=@ /dev/mapper/cryptarch /mnt
    mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
    mount -o ${mount_opts},subvol=@home /dev/mapper/cryptarch /mnt/home
    mount -o ${mount_opts},subvol=@snapshots /dev/mapper/cryptarch /mnt/.snapshots
    mount -o ${mount_opts},subvol=@cache /dev/mapper/cryptarch /mnt/var/cache
    mount -o ${mount_opts},subvol=@libvirt /dev/mapper/cryptarch /mnt/var/lib/libvirt
    mount -o ${mount_opts},subvol=@log /dev/mapper/cryptarch /mnt/var/log
    mount -o ${mount_opts},subvol=@tmp /dev/mapper/cryptarch /mnt/var/tmp
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  elif [[ $chosen_filesystem == "Btrfs" && $encryption == "No" ]]; then
    mkfs.btrfs -L archbtrfs /dev/"${partition_choice}${partition_suffix}"2
    mount /dev/"${partition_choice}${partition_suffix}" /mnt
    gum style --foreground="#00ff28" --bold "Setting up subvolumes"
    sleep 2
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@libvirt
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@tmp
    umount -R /mnt
    mount_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
    mount -o ${mount_opts},subvol=@ /dev/"${partition_choice}${partition_suffix}"2 /mnt
    mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
    mount -o ${mount_opts},subvol=@home /dev/"${partition_choice}${partition_suffix}"2 /mnt/home
    mount -o ${mount_opts},subvol=@snapshots /"${partition_choice}${partition_suffix}"2 /mnt/.snapshots
    mount -o ${mount_opts},subvol=@cache /"${partition_choice}${partition_suffix}"2 /mnt/var/cache
    mount -o ${mount_opts},subvol=@libvirt /"${partition_choice}${partition_suffix}"2 /mnt/var/lib/libvirt
    mount -o ${mount_opts},subvol=@log /"${partition_choice}${partition_suffix}"2 /mnt/var/log
    mount -o ${mount_opts},subvol=@tmp /"${partition_choice}${partition_suffix}"2 /mnt/var/tmp
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  elif [[ $chosen_filesystem == "Xfs" && $encryption == "Yes" ]]; then
    mkfs.xfs /dev/mapper/cryptarch
    mount /dev/mapper/cryptarch /mnt
    mkdir /mnt/{home,boot}
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  elif [[ $chosen_filesystem == "Xfs" && $encryption == "No" ]]; then
    mkfs.xfs /dev/"${partition_choice}${partition_suffix}"2
    mount /dev/"${partition_choice}${partition_suffix}"2 /mnt
    mkdir /mnt/{home,boot}
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  elif [[ $chosen_filesystem == "Ext4" && $encryption == "Yes" ]]; then
    mkfs.ext4 /dev/mapper/cryptarch
    mount /dev/mapper/cryptarch /mnt
    mkdir /mnt/{home,boot}
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  elif [[ $chosen_filesystem == "Ext4" && $encryption == "No" ]]; then
    mkfs.ext4 /dev/"${partition_choice}${partition_suffix}"2
    mount /dev/"${partition_choice}${partition_suffix}"2 /mnt
    mkdir /mnt/{home,boot}
    mkfs.fat -F32 /dev/"${partition_choice}${partition_suffix}"1
    mount --mkdir /dev/"${partition_choice}${partition_suffix}"1 /mnt/boot
  fi
}

pacstab() {
  cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
  if [[ "$VM_STATUS" == "bare_metal" && "$cpu_vendor" == "AuthenticAMD" ]]; then
    cpu_ucode="amd-ucode"
  elif [[ "$VM_STATUS" == "bare_metal" && "$cpu_vendor" == "GenuineIntel" ]]; then
    cpu_ucode="intel-ucode"
  else
    cpu_ucode=""
  fi
  if [[ "$chosen_filesystem" == "Ext4" ]]; then
    fs_userspace_utilities="e2fsprogs"
  elif [[ "$chosen_filesystem" == "Xfs" ]]; then
    fs_userspace_utilities="xfsprogs"
  elif [[ "$chosen_filesystem" == "Btrfs" ]]; then
    fs_userspace_utilities="btrfs-progs"
  fi
  export cpu_ucode

  gum style --foreground="#00ff28" --bold "Updating Mirrorlist"
  reflector -c 'United States' -a 24 -p https --sort rate --save /etc/pacman.d/mirrorlist

  pacstrap -K /mnt \
    "$filesystem_userspace_utilities" \
    "$cpu_ucode" \
    base \
    linux \
    linux-headers \
    linux-zen \
    linux-zen-headers \
    linux-firmware \
    sof-firmware \
    git \
    neovim \
    reflector \
    man-db \
    dosfstools \
    gum

  genfstab -U /mnt >>/mnt/etc/fstab
  cp ./chroot.sh /mnt
  cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
  arch-chroot /mnt ./chroot.sh
}

clean_up() {
  gum confirm "Would you like to clean up and reboot?"
  if [[ $? == 0 ]]; then
    rm /mnt/chroot.sh
    umount -R /mnt
    reboot
  else
    gum style --foreground="#00ff28" --bold "Returning back to chroot env"
    arch-chroot /mnt
  fi
}

intro_banner() {
  sleep 5 | gum style \
    --foreground "#d49d82" --border-foreground "#82B8D4" --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'Arch Install Script'
}

Logging
check_internet_connection
internet_check
check_dependencies
intro_banner
vm_check
termfonts
check_uefi
drive_partition
pacstab
clean_up
