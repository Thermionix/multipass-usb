#!/bin/sh

ISODIR=../iso/

#loop cat pull.isos.list $iso_regex $iso_addr $md5_addr

REMOTE_REGEX='/gparted-live-stable(.*?)/\K(gparted-live(.*?)amd64.iso)'
REMOTE_URL="http://sourceforge.net/projects/gparted/"
CURRENT_REGEX="gparted-live(.*?)amd64.iso"
CURRENTISO=`ls $ISODIR | egrep -m 1 -o "$CURRENT_REGEX"`

SOURCEFORGE_CHECK=`echo "$REMOTE_URL" | grep "sourceforge.net"`
if [ $? -eq 0 ]; then
	PROJECTNAME=`echo $REMOTE_URL | grep -oPh 'projects/(.*?)/' |cut -f2 -d/`
	echo "# Projectname $PROJECTNAME"
	PROJECTJSON="http://sourceforge.net/api/project/name/$PROJECTNAME/json"
	PROJECTID=`curl -s $PROJECTJSON|
	python -c "import json; import sys;print((json.load(sys.stdin))['Project']['id'])"`
	echo "# SourceForge Project: $PROJECTNAME Id: $PROJECTID"
	PROJECTRSS="http://sourceforge.net/api/file/index/project-id/$PROJECTID/mtime/desc/limit/250/rss"
	echo "# RSS: $PROJECTRSS"
	LATESTISO=`curl -s $PROJECTRSS | grep "<title>" | grep -m 1 -oP "$REMOTE_REGEX"`
	LATEST_REMOTE="http://downloads.sourceforge.net/$PROJECTNAME/$LATESTISO"
	## Insert magic here to get MD5sum from sourceforge
	# /(\/project\/showfiles.php\?group_id=\d+)/
	#LATEST_MD5=""
else
	echo "standard project"

	##wget $md5_addr | grep $new_iso | $ISODIR$new_iso.md5sum
fi

echo "# Latest ISO match: $LATESTISO"
echo "# Current ISO match: $CURRENTISO"
exit

if [ $LATESTISO != $CURRENTISO ] ; then
	echo "# ISO matches are different"
	read -e -n1 -p "download $LATESTISO [Y/n]: " OPTION
	if [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then
		#rm $ISODIR$CURRENTISO
		#rm $ISODIR$CURRENTISO.md5sum

		echo "## Downloading $LATEST_REMOTE"
		#pushd $ISODIR
			#wget $LATEST_URL

			#newmd5=$(/sbin/md5 "$LATESTISO" | /usr/bin/cut -f 2 -d "=")
		#popd

		#if failed_checksum #ask download again?

		#sed 's/cur_iso/new_iso/' ../boot/grub/grub.cfg
	fi
fi

