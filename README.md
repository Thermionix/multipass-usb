multipass-usb
=============

GRUB2 + USB pendrive + ISOs

use /scripts/create.grub.key.sh to setup the pendrive

bootable media are stored under /iso/

*.grub.cfg in /iso/ are concatenated into /boot/grub/grub.cfg by /scripts/gen.grub.cfg.sh

use /scripts/ophcrack.tables.pull.sh to populate /tables/ for ophcrack livecd

test using qemu ``sudo umount /dev/disk/by-label/multipass01 ; sudo qemu-system-x86_64 -drive file=`readlink -f /dev/disk/by-label/multipass01 | sed 's/[0-9]*//g'`,cache=none,if=virtio ``
