#!/bin/sh

echo "## listing available disks"
sudo parted --list | egrep "^Disk /"
read -e -p "Set disk to install to: " -i "sd" DSK

blockdevice=/dev/${DSK}
labelpart="multipass01"
tmpdir=/tmp/$labelpart
labelboot="boot"
partboot="/dev/disk/by-partlabel/$labelboot"

read -p "## WILL COMPLETELY WIPE $blockdevice"
read -p "Press [Enter] key to continue"

echo "## creating partition bios_grub"
sudo parted -s ${blockdevice} mklabel gpt
sudo parted -s ${blockdevice} -a optimal unit MB mkpart primary 1 2
sudo parted -s ${blockdevice} set 1 bios_grub on
echo "## creating partition $labelboot"
sudo parted -s ${blockdevice} -a optimal unit MB -- mkpart primary 2 -1
sudo parted -s ${blockdevice} name 2 $labelboot

sudo mkfs.vfat -n $labelpart $partboot

sudo mount $partboot $tmpdir

read -p "Press [Enter] key to continue"
 
sudo grub-install --no-floppy --root-directory=$tmpdir ${blockdevice}

sudo apt-get install syslinux
cp /usr/lib/syslinux/memdisk $tmpdir/grub/boot/
cp /boot/grub/fonts/unicode.pf2 $tmpdir/grub/boot/
