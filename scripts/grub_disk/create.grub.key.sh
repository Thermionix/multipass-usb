#!/bin/bash
set -e

# call to execute script in a shell from web;
# bash -c "$(curl -fsSL https://github.com/Thermionix/multipass-usb/raw/master/scripts/create.grub.key.sh)"

command -v parted > /dev/null || { echo "## please install parted" ; exit 1 ; }
command -v syslinux > /dev/null || { echo "## please install syslinux" ; exit 1 ; }
command -v grub-install > /dev/null || { echo "## please install grub" ; exit 1 ; }
command -v bsdtar > /dev/null || { echo "## please install bsdtar" ; exit 1 ; }
command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
command -v git > /dev/null || { echo "## please install git" ; exit 1 ; }
command -v whiptail >/dev/null 2>&1 || { echo "whiptail (pkg libnewt) required for this script" >&2 ; exit 1 ; }
command -v sgdisk >/dev/null 2>&1 || { echo "sgdisk (pkg gptfdisk) required for this script" >&2 ; exit 1 ; }

#command -v mkfs.exfat >/dev/null 2>&1 || { echo "mkfs.exfat (pkg exfat-utils) required" >&2 ; exit 1 ; }
command -v mkfs.vfat >/dev/null 2>&1 || { echo "mkfs.vfat (pkg dosfstools) required" >&2 ; exit 1 ; }

#command -v mkudffs >/dev/null 2>&1 || { echo "mkudffs (aur pkg udftools) required" >&2 ; exit 1 ; }
#[ $(lsmod | grep -o ^udf) ] || { echo "udf kernel module not loaded" >&2 ; exit 1 ; }


disks=`sudo parted --list --script | awk -F ": |, |Disk | " '/Disk \// { print $2" "$3$4 }'`
DSK=$(whiptail --nocancel --menu "Select the Disk to install to" 18 45 10 $disks 3>&1 1>&2 2>&3)

drivelabel=$(whiptail --nocancel --inputbox "please enter a label for the drive:" 10 40 "MULTIPASS01" 3>&1 1>&2 2>&3 | tr '[:lower:]' '[:upper:]')

# TODO : ask to support UEFI or not?

if whiptail --defaultno --yesno "COMPLETELY WIPE ${DSK}?" 8 40 ; then
	if ( grep -q ${DSK} /etc/mtab ); then
		echo "# unmounting ${DSK}"
		sudo umount ${DSK}* || /bin/true
		sleep 1
	fi

	echo "# wiping ${DSK}"
	sudo dd if=/dev/zero of=${DSK} bs=512 count=4000
	sudo sgdisk --zap-all ${DSK} || /bin/true
	sleep 1

	echo "# partitioning ${DSK}"

	echo "# creating partition table" 	
	sudo parted -s ${DSK} mklabel gpt
	#sudo parted -s ${DSK} mklabel msdos

	#sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 -1
	#sudo sgdisk --new=1:0:0 --typecode=1:ef00 ${DSK}

	#echo "# creating bios_grub partition"
	#sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 2
	#sudo parted -s ${DSK} set 1 bios_grub on

	#echo "# creating efi partition"
	#sudo parted -s ${DSK} -a optimal unit MB -- mkpart ESI 2 32
	#sudo parted -s ${DSK} set 2 boot on
	#sudo parted -s ${DSK} name 2 $drivelabel-efi

	#echo "# creating boot partition"
	#sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 32 -1

	#sudo mkudffs -b 512 --utf8 --vid=$drivelabel --lvid=$drivelabel  --media-type=hd ${DSK}3
	#sudo mkfs.vfat -F 32 ${DSK}2


	sudo parted -s ${DSK} -a optimal unit MB -- mkpart primary 1 -1
	sudo parted -s ${DSK} name 1 $drivelabel

	sudo mkfs.vfat -F 32 ${DSK}1

	sleep 1
	sudo partprobe ${DSK}
	sleep 1
	partboot="/dev/disk/by-label/$drivelabel"
	#partefi="/dev/disk/by-partlabel/$drivelabel-efi"

	tmpdir=/tmp/$drivelabel
	sudo mkdir -p $tmpdir
	sudo mount -o uid=$(id -u),gid=$(id -g) $partboot $tmpdir

	#efidir=$tmpdir/boot/efi
	#sudo mkdir -p $efidir
	#sudo mount -o uid=$(id -u),gid=$(id -g) $partefi $efidir

	if ( grep -q ${DSK} /etc/mtab ); then
		echo "# mounted $partboot at $tmpdir"

		trap 'echo unmounting $partboot ; ; sudo umount $tmpdir' EXIT
		#sudo umount $efidir

		echo "# installing grub on ${DSK}"
		#sudo grub-install --removable --target=x86_64-efi --root-directory=$tmpdir --efi-directory=$efidir --no-floppy ${DSK}
		#sudo grub-install --removable --target=i386-efi --root-directory=$tmpdir --efi-directory=$efidir --no-floppy ${DSK}
		sudo grub-install --target=i386-pc --root-directory=$tmpdir --no-floppy ${DSK}
		# --bootloader-id=$drivelabel
		sleep 1

		sudo chown -R `whoami` $tmpdir || /bin/true

		pushd $tmpdir
			echo "configfile /scripts/grub_resources/grub.head.cfg" > ./boot/grub/grub.cfg
			mkdir -p ./_ISO/

			repo="git@github.com:Thermionix/multipass-usb.git"
			extracttxt="repo:$repo\n\nclone git repo (yes)\ntarball extract a copy of master (no)\n\ncloning will allow you to git pull updates"

			if whiptail --defaultno --yesno "$extracttxt" 15 70 ; then
				git init
				git remote add origin $repo
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
