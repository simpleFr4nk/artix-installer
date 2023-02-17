#!/bin/sh

# Timezone
region_city=Europe/Rome
# Hostname
my_hostname=Leviathan
# User
user=ef

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
echo "--Root password--"
passwd

# Add user
useradd -m -G wheel,video,audio $user
echo "--$user password--"
passwd $user

# Set doas privileges
printf "permit persist :wheel\npermit nopass $user cmd reboot\npermit nopass $user cmd poweroff\n" >> /etc/doas.conf

# Hostname
printf "$my_hostname\n" > /etc/hostname
printf "hostname=\"$my_hostname\"\n" > /etc/conf.d/hostname
printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$my_hostname.localdomain\t$my_hostname\n" > /etc/hosts

# Connman
rc-update add connmand
