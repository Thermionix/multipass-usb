multipass-usb
=============

GRUB2 + USB pendrive + ISOs

*/resources/scripts/create.grub.key.sh* will:
* wipe specified disk
* install grub2
* copy in memdisk
* extract a copy of this repository
* set grub to load /resources/grub_sources/grub.head.cfg

*/bootisos/* directory stores the bootable media 
* .cfg are appended as bootable grub entries
* .bin are automatically added entries
* .img are automatically added entries (using memdisk)

*/resources/scripts/update.isos.sh* will:
* scan for *.conf in /resources/iso_sources/
* if local file exists compare filenames
* offer to download latest iso
* check md5sum if available
* generate a grub.cfg for the iso

*/resources/scripts/ophcrack.tables.pull.sh* will
* populate /tables/ for ophcrack livecd
* tables_xp_free_small & tables_vista_free
