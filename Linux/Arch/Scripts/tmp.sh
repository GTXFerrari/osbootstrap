#!/bin/bash
cryptsetup open /dev/p2 cryptbtrfs
mount_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"
mount -o ${mount_opts},subvol=@ /dev/mapper/cryptbtrfs /mnt
mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}
mount -o ${mount_opts},subvol=@home /dev/mapper/cryptbtrfs /mnt/home
mount -o ${mount_opts},subvol=@snapshots /dev/mapper/cryptbtrfs /mnt/.snapshots
mount -o ${mount_opts},subvol=@cache /dev/mapper/cryptbtrfs /mnt/var/cache
mount -o ${mount_opts},subvol=@libvirt /dev/mapper/cryptbtrfs /mnt/var/lib/libvirt
mount -o ${mount_opts},subvol=@log /dev/mapper/cryptbtrfs /mnt/var/log
mount -o ${mount_opts},subvol=@tmp /dev/mapper/cryptbtrfs /mnt/var/tmp
mount /dev/p1 /mnt/boot
