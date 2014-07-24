#!/bin/bash
set -e

# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/resources/scripts/create.grub.key.sh)"

command -v parted > /dev/null || { echo "## please install parted" ; exit 1 ; }
command -v syslinux > /dev/null || { echo "## please install syslinux" ; exit 1 ; }
command -v grub-install > /dev/null || { echo "## please install grub" ; exit 1 ; }
command -v tar > /dev/null || { echo "## please install tar" ; exit 1 ; }
command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
command -v whiptail >/dev/null 2>&1 || { echo "whiptail (pkg libnewt) required for this script" >&2 ; exit 1 ; }
command -v sgdisk >/dev/null 2>&1 || { echo "sgdisk (pkg gptfdisk) required for this script" >&2 ; exit 1 ; }

disks=`sudo parted --list | awk -F ": |, |Disk | " '/Disk \// { print $2" "$3$4 }'`
DSK=$(whiptail --nocancel --menu "Select the Disk to install to" 18 45 10 $disks 3>&1 1>&2 2>&3)

# TODO : ask user for disk label?
drivelabel="multipass01"

partboot="/dev/disk/by-label/$drivelabel"
tmpdir=/tmp/$drivelabel

echo "## WILL COMPLETELY WIPE ${DSK}"
read -p "Press [Enter] key to continue"
sudo sgdisk --zap-all ${DSK}

sudo parted -s ${DSK} mklabel msdos
sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 -1

sleep 1

# TODO : investigate exfat udf f2fs
sudo mkfs.ext4 -L "${drivelabel}" ${DSK}1

sudo mkdir -p $tmpdir

sudo mount $partboot $tmpdir

if ( grep -q ${DSK} /etc/mtab ); then
	echo "info: $partboot mounted at $tmpdir"

	sudo grub-install --no-floppy --root-directory=$tmpdir ${DSK}

	sleep 1

	sudo chown -R `whoami` $tmpdir

	cp /usr/lib/syslinux/bios/memdisk $tmpdir/boot/grub/

	pushd $tmpdir
		curl -L https://github.com/Thermionix/multipass-usb/tarball/master | tar zx --strip 1
	popd

	echo "configfile /resources/grub_sources/grub.head.cfg" > $tmpdir/boot/grub/grub.cfg

	echo "## will unmount $partboot when ready"
	read -n 1 -p "Press any key to continue..."
	sudo umount $tmpdir
fi
