#!/bin/bash

#bash pull.iso.sh --remote-url "http://sourceforge.net/projects/gparted/" --remote-regex "/gparted-live-stable(.*?)/\K(gparted-live(.*?)amd64.iso)" --local-regex "gparted-live(.*?)amd64.iso" --grub-cfg "../boot/grub/grub.cfg"

bash pull.iso.sh --remote-url "ftp://pentoo.east.us.mirror.inerail.net/pentoo/" --remote-regex "pentoo-amd64(.*?).iso" --remote-md5 ".DIGESTS"

#pentoo-amd64-2013.0_RC1.9.iso
#ftp://pentoo.east.us.mirror.inerail.net/pentoo/,pentoo-amd64(.*?).iso,,.DIGESTS
#http://sourceforge.net/projects/systemrescuecd/

#http://sourceforge.net/projects/ophcrack/

#ftp://ftp.iinet.net.au/linux/archlinux/iso/latest/
#ftp://ftp.iinet.net.au/linux/linuxmint/debian/
#http://sourceforge.net/projects/partedmagic/
