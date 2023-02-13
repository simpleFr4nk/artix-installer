#!/bin/sh -e

printf "\nStart with configuration...\n\n"

# Load keymap
sudo loadkeys it
# Choose disk
while :
do
    sudo fdisk -l
    printf "\nDisk to install to (e.g. sda): " && read disk
    [[ -b $disk ]] && break
done
# Partition name
part1="$disk"1
part2="$disk"2
part3="$disk"3
# Timezone
region_city="Europe/Rome"
# Hostname
my_hostname="Arti"
# User
user="ef"

install_variable () {
    echo disk=$disk part1=$part1 part2=$part2 part3=$part3 \
        region_city=$region_city my_hostname=$my_hostname
}

printf "\nDone with configuration. Installing...\n\n"

# Partition disk
cfdisk /dev/$disk

# Format partitions
mkfs.fat -F 32 /dev/$part1                      # boot partition
fatlabel /dev/$part1 ESP
mkswap -L SWAP /dev/$part2                      # swap partition
mkfs.ext4 -L ROOT /dev/$part3                   # root partition

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
sudo artix-chroot /mnt 

# Set timezone
ln -sf /usr/share/zoneinfo/$region_city /etc/localtime
hwclock --systohc

# Localization
printf "en_US.UTF-8 UTF-8\n" >> /etc/locale.gen
locale-gen

# Set locale systemwide
printf "LANG=en_US.UTF-8\nLC_COLLATE="C"\n" > /etc/locale.conf
printf "KEYMAP=it\n" > /etc/vconsole.conf

# Install boot loader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# Root user
printf "--Root password--\n"
passwd
# Add user
useradd -m -G wheel,video,audio $user
printf "--$user password--\n"
passwd $user

# Set doas privileges
printf "permit persist :wheel\npermit nopass $user cmd reboot\npermit nopass $user cmd poweroff" >> /etc/doas.conf

# Hostname
printf "$my_hostname\n" > /etc/hostname
printf "hostname=\"$my_hostname\"\n" > /etc/conf.d/hostname
printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$my_hostname.localdomain\t$my_hostname\n" > /etc/hosts

# Connman
rc-update add connmand

# Exit chroot
exit

printf '\nInstallation finished.\n\nYou need to poweroff and remove the usb.\n'
