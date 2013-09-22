#!/bin/bash

for f in `find ../iso/ -type f -name "*.grub.cfg" -printf "%f\n"`
do
	echo "reading $f"
	#grep
	#--remote-url 
	# --remote-regex 
	# --remote-md5 
	# --grub-cfg $grubfile
	#bash pull.iso.sh params
done

#bash grub.generate.sh
