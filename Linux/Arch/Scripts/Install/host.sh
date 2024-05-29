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

vm_check() {
  echo -e "${Green}Checking if machine is inside a VM${NC}"
  sleep 1
  VM_TYPE=$(systemd-detect-virt)
  if [[ "$VM_TYPE" == "none" ]]; then
    VM_STATUS="not_in_vm"
  elif [[ "$VM_TYPE" == "kvm" ]]; then
    VM_STATUS="kvm"
  elif [[ "$VM_TYPE" == "vmware" ]]; then
    VM_STATUS="vmware"
  else
    VM_STATUS=""
  fi
  export VM_STATUS
}

termfonts() {
  echo -e "${Green}Adjusting fonts${NC}"
  sleep 1
  if [[ "$VM_STATUS" == "not_in_vm" ]]; then
    setfont ter-132b
  else
    setfont ter-124b
  fi
}

check_uefi() {
  echo -e "${Green}Checking UEFI settings${NC}"
  if [[ -d /sys/firmware/efi/efivars/ ]]; then
    echo "System is booted using UEFI, proceeding"
    sleep 1
  else
    echo "System is not booted using UEFI, change in the BIOS before proceeding."
    sleep 5
    exit 1
  fi

  efi_platform_size_file="/sys/firmware/efi/fw_platform_size"
  if [[ -e "$efi_platform_size_file" ]]; then
    value=$(cat "$efi_platform_size_file")
  fi

  if [[ "$value" -eq 64 ]]; then
    echo "The system is using a 64 bit UEFI, GRUB & Systemd-Boot are supported" #TODO: Create a conditional for bootloader
    sleep 3
  else
    echo "The system is using a 32 bit UEFI, only Systemd-Boot is supported"
    sleep 3
  fi
}

check_internet_connection() {
  websites=("archlinux.org" "google.com" "example.com")
  echo -e "${Green}Checking internet${NC}"
  sleep 1
  for site in "${websites[@]}"; do
    if ping -c 1 "$site" > /dev/null 2>&1; then
      return 0
    fi
  done
  return 1
  #TODO: Combine this with internet check function since they should be in one function
}

internet_check() {
if check_internet_connection; then
  echo -e "${Green}Internet available, starting script${NC}"
else
  echo -e "${Red}No internet, check your connection${NC}"
  exit 1
fi
}

drive_partition() {
while true; do
  echo "Available disk partitions:"
  lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
  read -rp "Enter the name of the partition you want to use: " partition_choice
  export partition_choice
  if [[ -e "/dev/$partition_choice" ]]; then
    # Partition using sgdisk
    sgdisk -Z /dev/"$partition_choice"
    sgdisk --clear --new=1:0:+2G --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:system /dev/$partition_choice #TODO: Create a variable to determine if partition is NVME or not since nvme uses p# instead of just using partition + number like vda1,sda1 etc
    # Encryption
    while true; do
      if [[ $? -eq 0 ]]; then
        break
      else
        echo "Cryptsetup command failed, Retrying..."
        sleep 3
      fi
    done
    cryptsetup luksFormat --type luks2 --align-payload=4096 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/${partition_choice}p2 #TODO: fix partition variable
    cryptsetup open /dev/"${partition_choice}"p2 cryptbtrfs #TODO: Fix partition variable
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
    mkfs.fat -F32 /dev/"${partition_choice}"p1 #TODO: Fix partition variable
    mount --mkdir /dev/"${partition_choice}"p1 /mnt/boot #TODO: Fix partition variable
    break
  else
    echo "Partition '/dev/$partition_choice' does not exist, please choose a valid partition"
    sleep 3
  fi
done
}

pacstab() {
  cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
  if [[ "$VM_STATUS" == "not_in_vm" && "$cpu_vendor" == "AuthenticAMD" ]]; then
    ucode="amd-ucode"
  else 
    "$ucode" == "" #TODO: Can create a conditional for intel cpus
  fi

  pacstrap -K /mnt \
    $ucode \
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
    btrfs-progs

  genfstab -U /mnt >> /mnt/etc/fstab
  cp ./chroot.sh /mnt
  arch-chroot /mnt ./chroot.sh
}

clean_up() {
  echo -e "${Green}Cleaning up.${NC}"
  rm /mnt/chroot.sh
  umount -R /mnt
  echo -n "Would you like to reboot? (y/n) "
  read -r reboot
  if [[ $reboot == "y" ]]; then
    reboot
  else
    return 1
  fi
}


vm_check
termfonts
check_uefi
internet_check
drive_partition
pacstab
clean_up
