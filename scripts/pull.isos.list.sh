#!/bin/bash

grubfile="../boot/grub/grub.cfg"

#bash pull.iso.sh --remote-url "http://sourceforge.net/projects/gparted/" --remote-regex "/gparted-live-stable(.*?)/\K(gparted-live(.*?)amd64.iso)" --local-regex "gparted-live(.*?)amd64.iso" --grub-cfg $grubfile
bash pull.iso.sh --remote-url "http://sourceforge.net/projects/ophcrack/" --remote-regex "ophcrack-notables-livecd-(.*?).iso" --grub-cfg $grubfile
#bash pull.iso.sh --remote-url "http://sourceforge.net/projects/systemrescuecd/" --remote-regex "systemrescuecd-x86(.*?).iso" --grub-cfg $grubfile
#bash pull.iso.sh --remote-url "http://sourceforge.net/projects/partedmagic/"

#bash pull.iso.sh --remote-url "ftp://pentoo.east.us.mirror.inerail.net/pentoo/" --remote-regex "pentoo-amd64(.*?).iso" --remote-md5 ".DIGESTS" --grub-cfg $grubfile

#bash pull.iso.sh --remote-url "ftp://ftp.iinet.net.au/linux/archlinux/iso/latest/"
#bash pull.iso.sh --remote-url "ftp://ftp.iinet.net.au/linux/linuxmint/debian/"

