multipass-usb
=============

GRUB2 + USB pendrive + ISOs

use /resources/scripts/create.grub.key.sh to setup the pendrive

bootable media are stored under /bootisos/

.cfg in /bootisos/ are appended as bootable entries

.bin files will be automatically added to the boot menu

.img files will be automatically bootable via memdisk

use /resources/scripts/ophcrack.tables.pull.sh to populate /tables/ for ophcrack livecd

