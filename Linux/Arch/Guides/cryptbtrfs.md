# **Arch Linux Install (BTRFS+Encyption)**

&nbsp;

---
&nbsp;  


&nbsp;
# **Partition Setup**

### **Get the device names & create the partitions using gdisk**
```bash
lsblk

gdisk /dev/nvme0n1

# Drive can have a different format such as sda or vda (nvmeXnX is used for NVME drives)
```
* Create a new empty GUID partition table **(o)**

* Create the first partition on the device for the EFI directory **(n)** **(+512M in last sector)** Use code **(ef00)** for EFI 

* Use the rest of the space for data **(n)** **(Press enter to use all available space)** Use code **(8300)** for Linux filesystem

* Write the partitions to the disk **(w)**
 
 &nbsp;

 

### **Create the filesystem for the EFI partition**
```bash
mkfs.fat -F32 /dev/nvme0n1p1
```

&nbsp;

# **LUKS (Encryption)**
```bash
# A benchmark can be ran to determine the speed of different ciphers

cryptsetup benchmark

# Create a luks encrypted container 
cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/nvme0n1p2

# Open the LUKS container

cryptsetup open /dev/nvme0n1p2 cryptbtrfs
```

&nbsp;

### **Create the filesystem for the BTRFS partition**
```bash
mkfs.btrfs /dev/mapper/cryptbtrfs
```

&nbsp;

### **Create the btrfs subvolumes & set mount options**
```bash
# Mount the cryptdevice 
mount /dev/mapper/cryptbtrfs /mnt

# Move to the newly mounted directory
cd /mnt

# Create the subvolume for root & home
btrfs subvolume create @
btrfs subvolume create @home

# Unmount and remount with better options
cd /
unmount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/cryptbtrfs /mnt

# Create the boot & home directory
mkdir /mnt/{boot,home}

# Mount the home subvol
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/cryptbtrfs /mnt/home/

# Mount the efi directory
mount /dev/nvme0n1p1 /mnt/boot/
```

&nbsp;

# **Installation** 
### **Pacstrap**
```bash
# Once the drives are setup run pacstrap to install essential packages to the newly mounted system at /mnt

pacstrap /mnt base linux linux-headers linux-zen linux-zen-headers linux-firmware sof-firmware amd-ucode git neovim reflector man-db dosfstools btrfs-progs
```
### **Genfstab**
```bash
genfstab -U /mnt >> /mnt/etc/fstab

# You can use cat /etc/fstab to view the created file
```
### **Chroot**
```bash
arch-chroot /mnt
```
&nbsp;

# **Device Configuration**
### **mkinitcpio.conf**
```bash
# Add the btrfs module to the mkinitcpio.conf
MODULES=(btrfs)

# Add the encrypt hook to the mkinitcpio.conf

HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)

# Recreate initramfs
mkinitcpio -P (-P recreates for all installed kernels)
```
### **Bootloader**
```bash
# Add the kernel parameter to the GRUB bootloader
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID="UUID_OF_DEVICE:cryptbtrfs root=/dev/mapper/cryptbtrfs

# If using vim/neovim you can use the read command to get the UUID
:read ! blkid /dev/nvme0n1p2
```
