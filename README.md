multipass-usb
=============

GRUB2 + USB pendrive + ISOs

use /scripts/create.grub.key.sh to setup the pendrive

bootable media are stored under /bootisos/

.iso files that support a loopback.cfg will be automatically added to the boot menu

.bin files will be automatically added to the boot menu

.img files will be automatically bootable via memdisk

.cfg in /bootisos/ are also appended as bootable entries

use /scripts/ophcrack.tables.pull.sh to populate /tables/ for ophcrack livecd

test using qemu ``sudo umount /dev/disk/by-label/multipass01 ; sudo qemu-system-x86_64 -drive file=`readlink -f /dev/disk/by-label/multipass01 | sed 's/[0-9]*//g'`,cache=none,if=virtio ``
