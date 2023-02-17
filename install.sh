#!/bin/sh -e

printf "\nStart with configuration...\n\n"

# Load keymap
sudo loadkeys it
# Choose disk
while :
do
    sudo fdisk -l
    printf "\nDisk to install to (e.g. /dev/sda): " && read disk
    [[ -b $disk ]] && break
done
# Partition name
part1="$disk"1
part2="$disk"2
part3="$disk"3

printf "\nDone with configuration. Installing...\n\n"

# Partition disk
cfdisk $disk

# Format partitions
mkfs.fat -F 32 $part1                      # boot partition
fatlabel $part1 ESP
mkswap -L SWAP $part2                      # swap partition
mkfs.ext4 -L ROOT $part3                   # root partition

# Mount partitions
swapon /dev/disk/by-label/SWAP                  # mount swap
mount /dev/disk/by-label/ROOT /mnt              # mount root
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount /dev/disk/by-label/ESP /mnt/boot/efi      # mount efi

# Start ntpd
rc-service ntpd start

# Install base system and kernel
basestrap /mnt base base-devel openrc elogind-openrc grub os-prober efibootmgr doas intel-ucode dhcpcd iwd connman-openrc connman-gtk
basestrap /mnt linux linux-firmware linux-headers mkinitcpio

# Create fstab
fstabgen -U /mnt > /mnt/etc/fstab

# Chroot
sudo cp chroot-part.sh /mnt/ && sudo artix-chroot /mnt /bin/bash -c 'sh chroot-part.sh ; rm chroot-part.sh ; exit'

printf '\nInstallation finished.\n\nYou need to poweroff and remove the usb.\n'
