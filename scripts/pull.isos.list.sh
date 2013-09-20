#!/bin/bash

grubfile="../boot/grub.entries.cfg"

#bash pull.iso.sh --remote-url "ftp://ftp.iinet.net.au/linux/linuxmint/debian/" --remote-regex "linuxmint(.*?)mate(.*?)64(.*?).iso" --remote-md5 "md5sums.txt" --grub-cfg $grubfile
bash pull.iso.sh --remote-url "ftp://ftp.iinet.net.au/linux/archlinux/iso/latest/" --remote-regex "archlinux-(.*?)-dual.iso" --remote-md5 "md5sums.txt" --grub-cfg $grubfile

#ftp://ftp.iinet.net.au/linux/linuxmint/stable/  /15/ recursive? organise by time? linuxmint-15-mate-dvd-64bit.iso

bash pull.iso.sh --remote-url "http://sourceforge.net/projects/gparted/" --remote-regex "/gparted-live-stable(.*?)/\K(gparted-live(.*?)amd64.iso)" --local-regex "gparted-live(.*?)amd64.iso" --grub-cfg $grubfile
bash pull.iso.sh --remote-url "http://sourceforge.net/projects/ophcrack/" --remote-regex "ophcrack-notables-livecd-(.*?).iso" --grub-cfg $grubfile
bash pull.iso.sh --remote-url "http://sourceforge.net/projects/systemrescuecd/" --remote-regex "systemrescuecd-x86(.*?).iso" --grub-cfg $grubfile
#bash pull.iso.sh --remote-url "http://sourceforge.net/projects/partedmagic/"

bash pull.iso.sh --remote-url "ftp://pentoo.east.us.mirror.inerail.net/pentoo/" --remote-regex "pentoo-amd64(.*?).iso" --remote-md5 ".DIGESTS" --grub-cfg $grubfile


