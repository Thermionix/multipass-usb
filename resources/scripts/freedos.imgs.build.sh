#!/bin/bash
set -e

ISO_PATH_GRUB=/bootisos/
ISO_PATH_REL=../..$ISO_PATH_GRUB

LOOP_DIR=/tmp/fd_loop/

FREEDOS_IMG=$ISO_PATH_REL"fdboot.img"

IMG_FILENAME="fd_wdidle3.img"
IMG_PATH=$ISO_PATH_REL$IMG_FILENAME
IMG_GROW="+30M"

APPEND_ARCHIVE="wdidle3_1_05.zip"

function check_base_img() {
	echo "# Checking $FREEDOS_IMG exists"
	
	if [ ! -f $FREEDOS_IMG ] ; then
		wget -O $FREEDOS_IMG http://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.0/fdboot.img
	fi
}

function copy_img() {
	if [ -f $FREEDOS_IMG ] ; then
		cp $FREEDOS_IMG $IMG_PATH
	else
		echo "# $FREEDOS_IMG doesn't exist, aborting"
		exit
	fi
}

function expand_img() {
	qemu-img resize $IMG_PATH $IMG_GROW
}

function mount_img() {
	echo "# Mounting $IMG_PATH to $LOOP_DIR"

	[ -d $LOOP_DIR ] && sudo rm -rf $LOOP_DIR
	mkdir -p $LOOP_DIR

	sudo mount -o loop,rw,uid=$(id -u),gid=$(id -g) $IMG_PATH $LOOP_DIR

	ls -la $LOOP_DIR
}

function unmount_img() {
	echo "# umount & rm $LOOP_DIR"
	sudo umount $LOOP_DIR
	sudo rmdir $LOOP_DIR
}

function append_files() {
	echo "# Appending $APPEND_ARCHIVE contents to $LOOP_DIR"
	unzip $APPEND_ARCHIVE -d $LOOP_DIR
}

trap unmount_img EXIT

check_base_img
copy_img
expand_img
mount_img
append_files
# TODO : pause and ask user to verify file structure in $LOOP_DIR


