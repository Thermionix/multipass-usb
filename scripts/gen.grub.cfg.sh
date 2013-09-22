#!/bin/bash

grubfile="../boot/grub/grub.cfg"

cat grub.head.cfg > $grubfile

cat ../iso/*grub.cfg >> $grubfile

cat grub.tail.cfg >> $grubfile
