#!/bin/bash

pushd ../_ISO/ > /dev/null

for d in `find . -type d`
do
pushd $d > /dev/null
for f in `find . -maxdepth 1 -type f \( -iname "*.iso" -o -iname "*.bin" -o -iname "*.img" \) -printf "%f\n"`
do
	if [ ! -f ${f}.md5 ] ; then
		echo "# generating $f.md5"
		md5sum $f > $f.md5
		cat $f.md5
	fi
done
popd > /dev/null
done
popd > /dev/null

read -n 1 -p "Press any key to continue..."
