#!/bin/bash

grubfile="../boot/grub/grub.cfg"
isodir="../iso"

cat grub.head.cfg > $grubfile

for f in `find $isodir -type f -name "*.grub.cfg" -printf "%f\n"`
do
	filepath=`grep -P -m 1 "^\s*set iso_path=" $isodir/$f | cut -d "=" -f 2 | sed "s/\"//g"`
	if [ "$filepath" != "" ] ; then
		filename=$(basename $filepath)
		if [ -f $isodir/$filename ] ; then
			echo "# appending $filename grub.cfg"
			cat $isodir/$f >> $grubfile
		fi
	fi
done

cat grub.tail.cfg >> $grubfile
