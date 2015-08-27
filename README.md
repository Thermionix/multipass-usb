multipass-usb
=============

GRUB2 + USB pendrive + ISOs

*/scripts/create.grub.key.sh* will:
* wipe specified disk
* install grub2
* copy in memdisk
* extract a copy of this repository
* set grub to load /scripts/grub_resources/grub.head.cfg

*/bootisos/* directory stores the bootable media 
* .cfg are appended as bootable grub entries

*/scripts/update.isos.sh* will:
* scan for *.conf in /scripts/grub_templates/
* if local file exists compare filenames
* offer to download latest iso
* check md5sum if available
* generate a grub.cfg for the iso

*/scripts/generate.dos.image.sh* will
* pull a *.exe file
* generate a freedos img including the .exe
* generate a grub.cfg for the freedos.img
