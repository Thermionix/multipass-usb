#!/bin/bash

# TODO : test qemu installed

# sync writes any data buffered in memory out to disk. 
sync

usbdev=$(mount | grep ${PWD%/*} | cut -f1 -d ' ' | sed 's/[0-9]*//g')

# TODO : use qemu-system-i386 if not x64 system
# -net user
# -display gtk
# ,readonly
sudo qemu-system-x86_64 -cpu host -machine type=pc,accel=kvm -vga std -m 2048 -name multipass \
 -drive file=$usbdev,cache=none,if=virtio

