#!/bin/bash
set -e

# call to execute script in a shell from web;
# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/resources/scripts/create.grub.key.sh)"

command -v parted > /dev/null || { echo "## please install parted" ; exit 1 ; }
command -v syslinux > /dev/null || { echo "## please install syslinux" ; exit 1 ; }
command -v grub-install > /dev/null || { echo "## please install grub" ; exit 1 ; }
command -v bsdtar > /dev/null || { echo "## please install bsdtar" ; exit 1 ; }
command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
command -v git > /dev/null || { echo "## please install git" ; exit 1 ; }
command -v whiptail >/dev/null 2>&1 || { echo "whiptail (pkg libnewt) required for this script" >&2 ; exit 1 ; }
command -v sgdisk >/dev/null 2>&1 || { echo "sgdisk (pkg gptfdisk) required for this script" >&2 ; exit 1 ; }

disks=`sudo parted --list | awk -F ": |, |Disk | " '/Disk \// { print $2" "$3$4 }'`
DSK=$(whiptail --nocancel --menu "Select the Disk to install to" 18 45 10 $disks 3>&1 1>&2 2>&3)

drivelabel=$(whiptail --nocancel --inputbox "please enter a label for the drive:" 10 40 "multipass01" 3>&1 1>&2 2>&3)

if whiptail --defaultno --yesno "COMPLETELY WIPE ${DSK}?" 8 40 ; then
	if ( grep -q ${DSK} /etc/mtab ); then
		echo "# unmounting ${DSK}"
		sudo umount ${DSK}* || /bin/true
		sleep 1
	fi

	echo "# wiping ${DSK}"
	sudo dd if=/dev/zero of=${DSK} bs=512 count=4000
	sudo sgdisk --zap-all --clear -g ${DSK}
	sleep 1

	echo "# partitioning ${DSK}"
	sudo parted -s ${DSK} mklabel msdos
	sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 -1

	case $(whiptail --menu "Choose a filesystem" 18 30 10 \
		"1" "udf" \
		"2" "ext4" \
		"3" "vfat" \
		"4" "exfat" \
		3>&1 1>&2 2>&3) in
			1)
				command -v mkudffs >/dev/null 2>&1 || { echo "mkudffs (udftools) required" >&2 ; exit 1 ; }
				[ $(lsmod | grep -o ^udf) ] || { echo "udf kernel module not loaded" >&2 ; exit 1 ; }

				sudo mkudffs -b 512 --utf8 --vid=$drivelabel --media-type=hd ${DSK}1
			;;
			2)
				sudo mkfs.ext4 -L "${drivelabel}" ${DSK}1
			;;
			3)
				sudo mkfs.vfat -n "${drivelabel}" ${DSK}1
			;;
			4)
				sudo mkfs.exfat -n "${drivelabel}" ${DSK}1
			;;
	esac

	sleep 1
	sudo partprobe ${DSK}
	sleep 1
	partboot="/dev/disk/by-label/$drivelabel"

	tmpdir=/tmp/$drivelabel
	sudo mkdir -p $tmpdir

	sudo mount $partboot $tmpdir

	if ( grep -q ${DSK} /etc/mtab ); then
		echo "# mounted $partboot at $tmpdir"

		trap 'echo unmounting $partboot ; sudo umount $tmpdir' EXIT

		echo "# installing grub on ${DSK}"
		sudo grub-install --skip-fs-probe --no-floppy --root-directory=$tmpdir ${DSK}
		sleep 1

		sudo chown -R `whoami` $tmpdir

		pushd $tmpdir
			echo "configfile /resources/grub_sources/grub.head.cfg" > ./boot/grub/grub.cfg
			mkdir -p ./bootisos/

			repo="https://github.com/Thermionix/multipass-usb.git"
			extracttxt="repo:$repo\n\nclone git repo (yes)\ntarball extract a copy of master (no)\n\ncloning will allow you to git pull updates"

			if whiptail --defaultno --yesno "$extracttxt" 15 70 ; then
				git init
				git remote add origin git@github.com:Thermionix/multipass-usb.git
				git fetch
				git checkout -t origin/master
			else
				wget -qO- https://github.com/Thermionix/multipass-usb/tarball/master | bsdtar --strip-components 1 -xvf-
			fi

			cp /usr/lib/syslinux/bios/memdisk ./boot/grub/

			wget -qO- http://git.ipxe.org/releases/wimboot/wimboot-latest.zip | \
				bsdtar --include wimboot-*/wimboot --strip-components 1 -C ./boot/grub -xvf-
		popd
	fi
fi
