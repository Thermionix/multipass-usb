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

drivelabel=$(whiptail --nocancel --inputbox "please enter a label for the drive:" 10 40 "multipass01" 3>&1 1>&2 2>&3)

if whiptail --defaultno --yesno "COMPLETELY WIPE ${DSK}?" 8 40 ; then
	sudo umount ${DSK}* || /bin/true
	sleep 1

	sudo sgdisk --zap-all ${DSK}
	sudo dd if=/dev/zero of=${DSK} bs=1M count=1
	sleep 1

	# TODO : exfat f2fs fat32
	case $(whiptail --menu "Choose a filesystem" 17 30 10 \
		"1" "udf" \
		"2" "ext4" \
		3>&1 1>&2 2>&3) in
			1)
				command -v mkudffs >/dev/null 2>&1 || { echo "mkudffs required" >&2 ; exit 1 ; }

				sudo parted -s ${DSK} mklabel msdos
				sudo parted -s ${DSK} -a optimal unit MB mkpart primary 1 2
				sudo parted -s ${DSK} set 1 bios_grub on
				sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 2 -1

				sudo mkudffs -b 512 --vid=$drivelabel --media-type=hd ${DSK}2
				sleep 1
				# TODO : maybe check udf module loaded?
			;;
			2)
				sudo parted -s ${DSK} mklabel msdos
				sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 -1
				sleep 1
				sudo mkfs.ext4 -L "${drivelabel}" ${DSK}1
			;;
	esac

	partboot="/dev/disk/by-label/$drivelabel"

	tmpdir=/tmp/$drivelabel
	sudo mkdir -p $tmpdir

	sudo mount $partboot $tmpdir

	if ( grep -q ${DSK} /etc/mtab ); then
		echo "info: $partboot mounted at $tmpdir"

		sudo grub-install --no-floppy --root-directory=$tmpdir ${DSK}
		sleep 1

		sudo chown -R `whoami` $tmpdir

		cp /usr/lib/syslinux/bios/memdisk $tmpdir/boot/grub/

		pushd $tmpdir
			# TODO : offer git checkout or tar extract
			curl -L https://github.com/Thermionix/multipass-usb/tarball/master | tar zx --strip 1
			echo "configfile /resources/grub_sources/grub.head.cfg" > ./boot/grub/grub.cfg
		popd

		echo "## will unmount $partboot when ready"
		read -n 1 -p "Press any key to continue..."
		sudo umount $tmpdir
	fi
fi
