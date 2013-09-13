#!/bin/bash

#menuentry "freedos fdbasecd.iso" {
#	linux16 /boot/grub/memdisk iso
#	initrd16 $isopath/fdbasecd.iso
#}

# http://joelinoff.com/blog/?p=431
rm -rf /tmp/freedos
mkdir /tmp/freedos
cd /tmp/freedos
wget http://www.freedos.org/freedos/files/download/fd11src.iso
dd if=/dev/zero of=fdos11.img bs=1M count=80
qemu -cdrom fd11src.iso fdos11.img -boot d

#mount -o loop,blocksize=512,offset=32256 fd_sas1068e_p21.img /mnt/dos
#mount -o loop,blocksize=512,offset=32256 fd_sas1068e_p21.img /mnt/
# mount -o loop fdboot.img /mnt/freedos
#sudo mount -o loop fd_sas1068e_p21.img /mnt/


# $ mkdir /tmp/floppy
# $ sudo mount -t vfat -o loop,quiet,umask=000 E6410A12.img /tmp/floppy
# $ cp E6410A12.exe /tmp/floppy
# $ sudo umount /tmp/floppy
# $ sudo cp E6410A12.img /boot

# $ sudo apt-get install syslinux
# $ sudo cp /usr/lib/syslinux/memdisk /boot

# http://www.syslinux.org/wiki/index.php/MEMDISK
# http://wiki.gentoo.org/wiki/BIOS_Update/en

#$ bunzip2 FreeDOS-1.1-USB-Boot.img.bz2
#$ losetup -o 16384 /dev/loop0 FreeDOS-1.1-USB-Boot.img
#$ mkdir image
#$ mount /dev/loop0 image
#Put your stuff to image folder
#$ umount /mnt/image
#$ losetup -d /dev/loop0


#losetup -o 16384 /dev/loop0 fd_sas1068e_p21.img
#mount /dev/loop0 /mnt/
#cp dos/* /mnt/
#umount /mnt/
#losetup -d /dev/loop0
