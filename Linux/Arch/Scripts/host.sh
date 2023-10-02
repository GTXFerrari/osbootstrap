#!/usr/bin/env bash

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

# Functions
drive_partition() {
while true; do
  echo "Available disk partitions:"
  lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
  read -p "Enter the name of the partition you want to use: " partition_choice
  if [ -e "/dev/$partition_choice" ]; then
    # Partition using sgdisk
    sgdisk -Z /dev/$partition_choice
    sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsys /dev/$partition_choice
    # Encryption
    cryptsetup luksFormat --type luks2 --align-payload=8192 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/${partition_choice}p2
    cryptsetup open /dev/${partition_choice}p2 cryptbtrfs
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
    mkfs.fat -F32 /dev/${partition_choice}p1
    mount --mkdir /dev/${partition_choice}p1 /mnt/boot
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

  pacstrap /mnt \
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
  cp /./chroot.sh /mnt # Possible breakage if PATH is wrong, need to find solution
  arch-chroot /mnt ./host.sh
}

drive_partition
pacstab
