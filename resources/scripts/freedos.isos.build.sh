#!/bin/bash
set -e

ISO_PATH_GRUB=/bootisos/
ISO_PATH_REL=../..$ISO_PATH_GRUB

FREEDOS_WORKDIR=/tmp/freedos/
LOOP_DIR=/tmp/fd_loop/

FREEDOS_BASEISO=./fdbasecd.iso
OUTPUT_ISO="fd_wdidle3.iso"
APPEND_ARCHIVE="wdidle3_1_05.zip"

OUTPUT_FULLPATH=$ISO_PATH_REL$OUTPUT_ISO
OUTPUT_GRUBCFG=$OUTPUT_FULLPATH.grub.cfg

function check_base_iso() {
	echo "# Checking $FREEDOS_BASEISO exists"
	# ELSE: wget http://www.freedos.org/download/download/fdbasecd.iso
}

function extract_freedos_iso() {
	echo "# Extracting $FREEDOS_BASEISO to $FREEDOS_WORKDIR"

	[ -d $LOOP_DIR ] && sudo rm -rf $LOOP_DIR
	[ -d $FREEDOS_WORKDIR ] && sudo rm -rf $FREEDOS_WORKDIR

	mkdir -p $LOOP_DIR
	mkdir -p $FREEDOS_WORKDIR

	sudo mount -o loop,ro $FREEDOS_BASEISO $LOOP_DIR

	cp -a $LOOP_DIR/* $FREEDOS_WORKDIR

	sudo umount $LOOP_DIR
	sudo rmdir $LOOP_DIR
}

function append_files() {
	echo "# Appending $APPEND_ARCHIVE contents to $FREEDOS_WORKDIR"
	unzip $APPEND_ARCHIVE -d $FREEDOS_WORKDIR
}

function create_iso() {
	echo "# Building output iso"

	chmod 755 $FREEDOS_WORKDIR/isolinux/isolinux.bin
	mkisofs -R -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
		-boot-load-size 4 -boot-info-table -o $OUTPUT_FULLPATH $FREEDOS_WORKDIR
}

function generate_grub() {
	echo "# Generating $OUTPUT_GRUBCFG"

cat << EOF > $OUTPUT_GRUBCFG
menuentry "$OUTPUT_ISO" {
	set iso_path="$ISO_PATH_GRUB$OUTPUT_ISO"
	linux16 /boot/grub/memdisk iso
	initrd16 \$iso_path
}
EOF

}

extract_freedos_iso
append_files
# TODO : pause and ask user to verify file structure in $FREEDOS_WORKDIR
create_iso
generate_grub

