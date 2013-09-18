#!/bin/sh

#loop cat pull.isos.list $iso_regex $iso_addr $md5_addr

#cur_iso = ls -l ../iso/ | egrep $iso_regex

#if $iso_addr .contains sourceforge.net
ISO_REGEX="pmagic_(.*?).iso"
PROJECTNAME=partedmagic

PROJECTJSON="http://sourceforge.net/api/project/name/$PROJECTNAME/json"
PROJECTID=`curl -s $PROJECTJSON|
python -c "import json; import sys;print((json.load(sys.stdin))['Project']['id'])"`
echo "# SourceForge Project: $PROJECTNAME Id: $PROJECTID"
PROJECTRSS="http://sourceforge.net/api/file/index/project-id/$PROJECTID/mtime/desc/limit/20/rss"
echo "# RSS: $PROJECTRSS"
LATESTISO=`curl -s $PROJECTRSS | grep "<title>" | egrep -m 1 -o "$ISO_REGEX"`
echo "# Latest ISO match: $LATESTISO"

## if [ $LATESTISO != $CURRENTISO ] ; then
read -e -n1 -p "download $LATESTISO [Y/n]: " OPTION
if [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then
	#rm $cur_iso
	#rm $cur_iso.md5sum

	echo "## Downloading $LATESTISO"

	# if is sourceforge project
		echo "wget http://downloads.sourceforge.net/$PROJECTNAME/$LATESTISO"
		## Insert magic here to get MD5sum from sourceforge
		# /(\/project\/showfiles.php\?group_id=\d+)/
	# else
		#wget $ftp_addr ../iso/$new_iso
		#wget $md5_addr | grep $new_iso | ../iso/$new_iso.md5sum
	#fi
	#newmd5=$(/sbin/md5 "$LATESTISO" | /usr/bin/cut -f 2 -d "=")

	# md5sum $new_iso
	#if failed_checksum #ask download again?

	#sed 's/cur_iso/new_iso/' ../boot/grub/grub.cfg

fi

