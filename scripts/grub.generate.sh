#!/bin/bash

grubfile="../boot/grub/grub.cfg"

cat grub.head.cfg > $grubfile

#for *grub.cfg in ../iso/
#cat
#strip comments
# >> $grubfile
cat ../iso/*grub.cfg >> $grubfile

cat grub.tail.cfg >> $grubfile
