#!/bin/bash

# if [ -e $1 ]
#md5sum $1 > $1.md5
# fi

cd ../iso/

for f in `find . -type f -not -name "*.md5" -printf "%f\n"`
do
	if [ -f ${f}.md5 ]
	then
		md5sum -c $f.md5
		#| grep FAILED$ > failed_hashes
		#diff <( cat $f.md5 ) <( md5sum $f )
	else
		md5sum $f > $f.md5
	fi
done

