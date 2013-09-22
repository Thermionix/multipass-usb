#!/bin/bash

pushd ../iso/

for f in `find . -type f \( -name "*.iso" -o -name "*.bin" -o -name "*.img" \) -printf "%f\n"`
do
	if [ -f ${f}.md5 ]
	then
		md5sum -c $f.md5
	else
		echo "generating $f.md5"
		md5sum $f > $f.md5
	fi
done

popd
