#!/bin/bash

# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/scripts/create.grub.key.sh)"

command -v parted > /dev/null || { echo "## please install parted" ; exit 1 ; }
command -v syslinux > /dev/null || { echo "## please install syslinux" ; exit 1 ; }
command -v grub-install > /dev/null || { echo "## please install grub" ; exit 1 ; }
command -v tar > /dev/null || { echo "## please install tar" ; exit 1 ; }
command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
#command -v exfatfsck > /dev/null || { echo "## please install exfat-utils" ; exit 1 ; }
command -v whiptail >/dev/null 2>&1 || { echo "whiptail (pkg libnewt) required for this script" >&2 ; exit 1 ; }

disks=`sudo parted --list | awk -F ": |, |Disk | " '/Disk \// { print $2" "$3$4 }'`
DSK=$(whiptail --nocancel --menu "Select the Disk to install to" 18 45 10 $disks 3>&1 1>&2 2>&3)

drivelabel="multipass01"
partboot="/dev/disk/by-partlabel/$drivelabel"
tmpdir=/tmp/$drivelabel

enable_uefi=false
if whiptail --defaultno --yesno "create for UEFI system?" 8 40 ; then
	enable_uefi=true
fi

echo "## WILL COMPLETELY WIPE ${DSK}"
read -p "Press [Enter] key to continue"

#if $enable_uefi ; then

#else
echo "## creating partition bios_grub"
sudo parted -s ${DSK} mklabel gpt
sudo parted -s ${DSK} -a optimal unit MB mkpart primary 1 2
sudo parted -s ${DSK} set 1 bios_grub on
echo "## creating partition $drivelabel"
sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 2 -1
sudo parted -s ${DSK} name 2 $drivelabel

sleep 1

sudo mkfs.ext4 -L "${drivelabel}" $partboot
#mkudffs --media-type=hd --blocksize=512 --utf8 --vid="${drivelabel}" $partboot

sudo mkdir -p $tmpdir

sudo mount $partboot $tmpdir

if ( grep -q ${DSK} /etc/mtab ); then
	echo "info: $partboot mounted at $tmpdir"

	sudo grub-install --no-floppy --root-directory=$tmpdir ${DSK}

	sleep 1

	sudo chown -R `whoami` $tmpdir

	cp /usr/lib/syslinux/memdisk $tmpdir/boot/grub/

	pushd $tmpdir
		curl -L https://github.com/Thermionix/multipass-usb/tarball/master | tar zx --strip 1
	popd

	echo "configfile /scripts/grub.head.cfg" > $tmpdir/boot/grub/grub.cfg

	echo "## will unmount $partboot when ready"
	read -n 1 -p "Press any key to continue..."
	sudo umount $tmpdir
fi
