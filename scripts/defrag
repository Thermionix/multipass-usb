#!/bin/bash
# defrag v0.08 by Con Kolivas <kernel@kolivas.org
# Braindead fs-agnostic defrag to rewrite files in order largest to smallest
# Run this in the directory you want all the files and subdirectories to be
# reordered. It will only affect one partition. It works best when run twice.
# Are you really crazy enough to be using this? It might blow your data
# into tiny little useless chunks.


trap 'abort' 1 2 15

renice 19 $$ > /dev/null

abort()
{
	echo -e "\nAborting"
	rm -f tmpfile dirlist
	exit 1
}

fail()
{
	echo -e "\nFailed"
	abort
}

declare -i filesize=0
declare -i numfiles=0

#The maximum size of a file we can easily cache in ram
declare -i maxsize=$((`awk '/MemTotal/ {print $2}' /proc/meminfo`*1024))
(( maxsize-= `awk '/Mapped/ {print $2}' /proc/meminfo` ))
(( maxsize/= 2))

if [[ -a tmpfile || -a dirlist  ]] ; then
	echo dirlist or tmpfile exists
	exit 1
fi

# Sort in the following order:
# 1) Depth of directory
# 2) Size of directory descending
# 3) Filesize descending
# I made this crap up. It's completely unvalidated.

echo "Creating list of files..."

#stupid script to find max directory depth
find -xdev -type d -printf "%d\n" | sort -n | uniq > dirlist

#sort directories in descending size order
cat dirlist | while read d;
do
	find -xdev -type d -mindepth $d -maxdepth $d -printf "\"%p\"\n" | \
		xargs du -bS --max-depth=0 | \
		sort -k 1,1nr -k 2 |\
		cut -f2 >> tmpfile
	if (( $? )) ; then
		fail
	fi

done

rm -f dirlist

#sort files in descending size order
cat tmpfile | while read d;
do
	find "$d" -xdev -type f -maxdepth 1 -printf "%s\t%p\n" | \
		sort -k 1,1nr | \
		cut -f2 >> dirlist
	if (( $? )) ; then
		fail
	fi
done

rm -f tmpfile

numfiles=`wc -l dirlist | awk '{print $1}'`

echo -e "$numfiles files will be reordered\n"

#copy to temp file, check the file hasn't changed and then overwrite original
cat dirlist | while read i;
do
	(( --numfiles ))
	if [[ ! -f $i ]]; then
		continue
	fi

	#We could be this paranoid but it would slow it down 1000 times
	#if [[ `lsof -f -- "$i"` ]]; then
	#	echo -e "\n File $i open! Skipping"
	#	continue
	#fi

	filesize=`find "$i" -printf "%s"`
	# read the file first to cache it in ram if possible
	if (( filesize < maxsize ))
	then
		echo -e "\r $numfiles files left                                                            \c"
		cat "$i" > /dev/null
	else
		echo -e "\r $numfiles files left - Reordering large file sized $filesize ...                \c"
	fi

	datestamp=`find "$i" -printf "%s"`
	cp -a -f "$i" tmpfile
	if (( $? )) ; then
		fail
	fi
	# check the file hasn't been altered since we copied it
	if [[ `find "$i" -printf "%s"` != $datestamp ]] ; then
		continue
	fi

	mv -f tmpfile "$i"
	if (( $? )) ; then
		fail
	fi
done

echo -e "\nSucceeded"

rm -f dirlist
