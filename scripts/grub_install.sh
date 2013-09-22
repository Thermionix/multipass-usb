#!/bin/bash

# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/scripts/grub_install.sh)"

bash dependencies.sh parted syslinux grub git

echo "## listing available disks"
sudo parted --list | egrep "^Disk /"
read -e -p "Set disk to install to: " -i "sd" DSK

blockdevice=/dev/${DSK}

labelboot="multipass01"
partboot="/dev/disk/by-partlabel/$labelboot"
tmpdir=/tmp/$labelboot

echo "## WILL COMPLETELY WIPE $blockdevice"
read -p "Press [Enter] key to continue"

echo "## creating partition bios_grub"
sudo parted -s ${blockdevice} mklabel gpt
sudo parted -s ${blockdevice} -a optimal unit MB mkpart primary 1 2
sudo parted -s ${blockdevice} set 1 bios_grub on
echo "## creating partition $labelboot"
sudo parted -s ${blockdevice} -a optimal unit MB -- mkpart primary 2 -1
sudo parted -s ${blockdevice} name 2 $labelboot

sleep 1
sudo mkfs.ext4 $partboot

sudo mkdir -p $tmpdir

sudo mount $partboot $tmpdir

sudo chown -R `whoami` $tmpdir

pushd $tmpdir
	git init .
	git remote add -t \* -f origin https://github.com/Thermionix/multipass-usb.git
	git fetch
	git checkout master
popd

sudo grub-install --no-floppy --root-directory=$tmpdir ${blockdevice}

sleep 1

cp /usr/lib/syslinux/memdisk $tmpdir/boot/grub/


echo "## will unmount $partboot when ready"
read -p "Press [Enter] key to continue"
sudo umount $tmpdir
