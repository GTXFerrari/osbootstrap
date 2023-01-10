# **Arch Linux Install (LUKS+LVM)**

&nbsp;

---
&nbsp;  

<img src="https://archlinux.org/static/logos/archlinux-logo-dark-90dpi.ebdee92a15b3.png" width="700" height="250">


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

*  Create an 8GB Swap partition **(n)** **(+8G in the last sector)** Use code **(8200)** for Linux swap

* Use the rest of the space for data **(n)** **(Press enter to use all available space)** Use code **(8300)** for Linux filesystem

* Write the partitions to the disk **(w)**
 
 &nbsp;

 

### **Create the filesystem for the EFI partition**
```bash
mkfs.fat -F32 /dev/nvme0n1p1
```

&nbsp;
### **Set up SWAP**
```bash
mkswap /dev/nvme0n1p2

# Turn on SWAP

swapon /dev/nvme0n1p2
```
&nbsp;

&nbsp;

# **LUKS (Encryption)**
```bash
# A benchmark can be ran to determine the speed of different ciphers

cryptsetup benchmark

# Create a luks encrypted container 
cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 -y --use-urandom /dev/nvme0n1p3

# Open the LUKS container

cryptsetup open /dev/nvme0n1p3 cryptlvm
```
&nbsp;

# **LVM**
```bash
# Create a physical volume (Use pvs to show the created PV)

pvcreate /dev/mapper/cryptlvm

# Create a new volume group (Use vgs to show the created VG, "vg1" can be supplemented with any desired name)

vgcreate vg1 /dev/mapper/cryptlvm 

# Create the logical volumes (Use lvs to show the created LV's)

lvcreate -L 50G vg1 -n root
lvcreate -l 100%FREE vg1 -n home
```
### **Format the filesystems on each LV**
```bash
# You can supplement with your filesystem of choice i.e. ext4

mkfs.xfs /dev/vg1/root
mkfs.xfs /dev/vg1/home
```
### **Mount the filesystems**
```bash
mount /dev/vg1/root /mnt
mount --mkdir /dev/vg1/home /mnt/home
mount --mkdir /dev/nvm10n1p1 /mnt/boot
```
&nbsp;

# **Installation** 
### **Pacstrap**
```bash
# Once the drives are setup run pacstrap to install essential packages to the newly mounted system at /mnt

pacstrap /mnt base linux linux-headers linux-zen linux-zen-headers linux-firmware sof-firmware amd-ucode lvm2 git neovim reflector man-db dosfstools xfsprogs
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
# Add the encrypt and lvm2 hook to the mkinitcpio.conf

HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)
```
### **Bootloader**
```bash
# Add the kernel parameter to the GRUB bootloader
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 cryptdevice=UUID="UUID_OF_DEVICE:cryptlvm root=/dev/vg1/root

# If using vim/neovim you can use the read command to get the UUID
:read ! blkid /dev/nvme0n1
```
