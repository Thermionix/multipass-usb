#!/bin/bash

# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/scripts/create.grub.key.sh)"

if [ ! -f dependencies.sh ] ; then
	echo "unable to verify dependencies, please ensure the following are installed"
	echo "parted syslinux grub git"
	read -p "Press [Enter] key to continue"
else
	bash dependencies.sh parted syslinux grub git
	if [[ $? -ne 0 ]]; then exit
fi

echo "## listing available disks"
sudo parted --list | egrep "^Disk /"
read -e -p "Set disk to install to: " -i "sd" DSK

blockdevice=/dev/${DSK}

drivelabel="multipass01"
partboot="/dev/disk/by-partlabel/$drivelabel"
tmpdir=/tmp/$drivelabel

echo "## WILL COMPLETELY WIPE $blockdevice"
read -p "Press [Enter] key to continue"

echo "## creating partition bios_grub"
sudo parted -s ${blockdevice} mklabel gpt
sudo parted -s ${blockdevice} -a optimal unit MB mkpart primary 1 2
sudo parted -s ${blockdevice} set 1 bios_grub on
echo "## creating partition $drivelabel"
sudo parted -s ${blockdevice} -a optimal unit MB -- mkpart primary 2 -1
sudo parted -s ${blockdevice} name 2 $drivelabel

sleep 1
sudo mkfs.ext4 -L "${drivelabel}" $partboot

sudo mkdir -p $tmpdir

sudo mount $partboot $tmpdir

sudo grub-install --no-floppy --root-directory=$tmpdir ${blockdevice}

sleep 1

sudo chown -R `whoami` $tmpdir

cp /usr/lib/syslinux/memdisk $tmpdir/boot/grub/

pushd $tmpdir
	git clone https://github.com/Thermionix/multipass-usb.git $drivelabel; shopt -s dotglob nullglob; mv $drivelabel/* .; rmdir $drivelabel
popd

echo "## will unmount $partboot when ready"
read -p "Press [Enter] key to continue"
sudo umount $tmpdir
