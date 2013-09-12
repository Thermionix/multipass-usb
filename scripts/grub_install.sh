#!/bin/sh
 
DEVICE=sdf
 
mkfs.vfat -n multipass01 /dev/$DEVICE1
 
mount /dev/$DEVICE1 /mnt/
 
grub-install --no-floppy --root-directory=/mnt /dev/$DEVICE
 
apt-get install syslinux
cp /usr/lib/syslinux/memdisk /mnt/grub/boot/
cp /boot/grub/fonts/unicode.pf2 /mnt/grub/boot/
