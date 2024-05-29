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
  local chosen_filesystem=""
  local encryption=""
  local partition_suffix=""

  while true; do
    echo -e "${Green}Available disk partitions:${NC}"
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep -v "loop\|sr0"
    read -rp "Enter the name of the partition you want to use: " partition_choice
    export partition_choice

    if [[ "$partition_choice" == nvme* ]]; then
      partition_suffix="p"
      export partition_suffix
    else
      partition_suffix=""
      export partition_suffix
    fi

    if [[ -e "/dev/$partition_choice" ]]; then
      sgdisk -Z /dev/"$partition_choice"
      sgdisk --clear --new=1:0:+2G --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:system /dev/$partition_choice

      echo -en "${Green}Would you like to use LUKS encryption? (y/n) ${NC}"
      read -r encryption
      if [[ "$encryption" == "y" ]]; then
        cryptsetup luksFormat --type luks2 --align-payload=4096 -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/${partition_choice}${partition_suffix}2
        cryptsetup open /dev/${partition_choice}${partition_suffix} cryptarch
        export encryption
      fi

      while true; do
        PS3='Select a filesystem type: '
        options=("btrfs" "xfs" "ext4")
        select opt in "${options[@]}"; do
          case $opt in
            "btrfs")
              if [[ "$encryption" == "y" ]]; then
                mkfs.btrfs -L archbtrfs /dev/mapper/cryptarch
                mount /dev/mapper/cryptarch /mnt
                echo -e "${Green}Setting up subvolumes${NC}"
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
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="btrfs"
              else
                mkfs.btrfs -L archbtrfs /dev/${partition_choice}${partition_suffix}2
                mount /dev/${partition_choice}${partition_suffix} /mnt 
                echo -e "${Green}Setting up subvolumes${NC}"
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
                mount -o ${mount_opts},subvol=@ /dev/${partition_choice}${partition_suffix}2 /mnt
                mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
                mount -o ${mount_opts},subvol=@home /dev/${partition_choice}${partition_suffix}2 /mnt/home
                mount -o ${mount_opts},subvol=@snapshots /${partition_choice}${partition_suffix}2 /mnt/.snapshots
                mount -o ${mount_opts},subvol=@cache /${partition_choice}${partition_suffix}2 /mnt/var/cache
                mount -o ${mount_opts},subvol=@libvirt /${partition_choice}${partition_suffix}2 /mnt/var/lib/libvirt
                mount -o ${mount_opts},subvol=@log /${partition_choice}${partition_suffix}2 /mnt/var/log
                mount -o ${mount_opts},subvol=@tmp /${partition_choice}${partition_suffix}2 /mnt/var/tmp
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="btrfs"
              fi
              break 2
              ;;
            "xfs")
              if [[ "$encryption" == "y" ]]; then
                mkfs.xfs /dev/mapper/cryptarch
                mount /dev/mapper/cryptarch /mnt
                mkdir /mnt/{home,boot}
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="xfs"
              else
                mkfs.xfs /dev/${partition_choice}${partition_suffix}2
                mount /dev/${partition_choice}${partition_suffix}2 /mnt
                mkdir /mnt/{home,boot}
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="xfs"
              fi
              break 2
              ;;
            "ext4")
              if [[ "$encryption" == "y" ]]; then
                mkfs.ext4 /dev/mapper/cryptarch
                mount /dev/mapper/cryptarch /mnt
                mkdir /mnt/{home,boot}
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="ext4"
              else
                mkfs.ext4 /dev/${partition_choice}${partition_suffix}2
                mount /dev/${partition_choice}${partition_suffix}2 /mnt
                mkdir /mnt/{home,boot}
                mkfs.fat -F32 /dev/${partition_choice}${partition_suffix}1
                mount --mkdir /dev/${partition_choice}${partition_suffix}1 /mnt/boot
                chosen_filesystem="ext4"
              fi
              break 2
              ;;
            *)
              echo -e "${Red}Invalid option${NC}"
              ;;
          esac
        done
      done
      break
    else
      echo -e "${Red}Partition /dev/"$partition_choice" does not exist, enter a valid partition${NC}"
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
  if [[ "$chosen_filesystem" == "ext4" ]]; then
    fs="e2fsprogs"
  elif [[ "$chosen_filesystem" == "xfs" ]]; then
    fs="xfsprogs"
  elif [[ "$chosen_filesystem" == "btrfs" ]]; then
    fs="btrfs-progs"
  else 
    fs=""
  fi

  pacstrap -K /mnt \
    $fs \
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

  genfstab -U /mnt >> /mnt/etc/fstab
  cp ./chroot.sh /mnt
  arch-chroot /mnt ./chroot.sh
}

clean_up() {
  echo -n "Would you like to clean up and reboot? (y/n) "
  read -r reboot
  if [[ $reboot == "y" ]]; then
    echo -e "${Green}Cleaning up and rebooting.${NC}"
    rm /mnt/chroot.sh
    umount -R /mnt
    reboot
  else
    echo "Returning back to chrooted system"
    return 0
  fi
}

# Call functions
vm_check
termfonts
check_uefi
internet_check
drive_partition
pacstab
clean_up
