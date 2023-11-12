#!/usr/bin/env bash

# Colors
export NC='\033[0m' # No Color
export Black='\033[0;30m'
export Red='\033[0;31m'
export Green='\033[0;32m'
export Yellow='\033[0;33m'
export Blue='\033[0;34m'
export Purple='\033[0;35m'
export Cyan='\033[0;36m'
export White='\033[0;37m'

# Functions

check_uefi() {
  if [ -d /sys/firmware/efi/efivars/ ]; then
    echo "System is booted using UEFI, proceeding"
  else
    echo "System is not booted using UEFI, change in the BIOS before proceeding."
    exit 1
  fi

  efi_platform_size_file="/sys/firmware/efi/fw_platform_size"
  if [ -e "$efi_platform_size_file" ]; then
    value=$(cat "$efi_platform_size_file")

    if [ "$value" -eq 64 ]; then
      echo "The system is using a 64 bit UEFI, proceeding..."
    else
      echo "The system is using a 32 bit UEFI, only systemd-boot is supported"
    fi
  fi
}

check_internet_connection() {
  websites=("archlinux.org" "google.com" "example.com")
  echo "Checking internet connection"
  sleep 2
  for site in "${websites[@]}"; do
    if ping -c 1 "$site" > /dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

internet_check() {
# Check for internet connection
if check_internet_connection; then
  echo "Internet connection available. Starting script"
else
  echo "No internet connection found. Exiting..."
  exit 1
fi
}

drive_partition() {
while true; do
  echo "Available disk partitions:"
  lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
  read -rp "Enter the name of the partition you want to use: " partition_choice
  export partition_choice
  if [ -e "/dev/$partition_choice" ]; then
    # Partition using sgdisk
    sgdisk -Z /dev/"$partition_choice"
    sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:system /dev/$partition_choice
    # Encryption
    while true; do
      if [ $? -eq 0 ]; then
        break
      else
        echo "Cryptsetup command failed, Retrying..."
        sleep 3
      fi
    done
    cryptsetup luksFormat --type luks2 --align-payload=4096 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/${partition_choice}p2 # Need to create a conditional in case the selected drive is not an NVME device
    cryptsetup open /dev/"${partition_choice}"p2 cryptbtrfs
    # BTRFS
    mkfs.btrfs -L archbtrfs /dev/mapper/cryptbtrfs
    mount /dev/mapper/cryptbtrfs /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@libvirt
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@tmp
    umount -R /mnt
    mount_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
    mount -o ${mount_opts},subvol=@ /dev/mapper/cryptbtrfs /mnt
    mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
    mount -o ${mount_opts},subvol=@home /dev/mapper/cryptbtrfs /mnt/home
    mount -o ${mount_opts},subvol=@snapshots /dev/mapper/cryptbtrfs /mnt/.snapshots
    mount -o ${mount_opts},subvol=@cache /dev/mapper/cryptbtrfs /mnt/var/cache
    mount -o ${mount_opts},subvol=@libvirt /dev/mapper/cryptbtrfs /mnt/var/lib/libvirt
    mount -o ${mount_opts},subvol=@log /dev/mapper/cryptbtrfs /mnt/var/log
    mount -o ${mount_opts},subvol=@tmp /dev/mapper/cryptbtrfs /mnt/var/tmp
    mkfs.fat -F32 /dev/"${partition_choice}"p1
    mount --mkdir /dev/"${partition_choice}"p1 /mnt/boot
    break 
  else
    echo "Partition '/dev/$partition_choice' does not exist, please choose a valid partition"
    sleep 3
  fi
done
}

pacstab() {
  cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
  if [ "$cpu_vendor" == "AuthenticAMD" ]; then
    ucode="amd-ucode"
  else
    ucode="intel-ucode"
  fi

  pacstrap -K /mnt \
    base \
    linux \
    linux-headers \
    linux-zen \
    linux-zen-headers \
    linux-firmware \
    sof-firmware \
    $ucode \
    git \
    neovim \
    reflector \
    man-db \
    dosfstools \
    btrfs-progs

  genfstab -U /mnt >> /mnt/etc/fstab
  cp /root/osbootstrap/Linux/Arch/Scripts/chroot.sh /mnt # Possible breakage if PATH is wrong, need to find solution
  arch-chroot /mnt ./chroot.sh
}


# Call functions
setfont ter-132n
check_uefi
internet_check
drive_partition
pacstab

# Clean Up
echo -e "${Green}Cleaning up.${NC}"
rm /mnt/chroot.sh
umount -R /mnt
reboot
