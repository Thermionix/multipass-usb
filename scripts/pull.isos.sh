#!/bin/sh

# Supports retrieving/updating an ISO image from sourceforge or ftp server

#usage
# --remote-url ""
# --remote-regex ""
# --local-regex ""
# --remote-md5 "" *optional*
# --outdir ../iso/ *optional*

while [[ $1 = -* ]]; do
    arg=$1; shift

    case $arg in
        --remote-url)
            REMOTE_URL="$2"
            shift
            ;;
        --outdir)
            ISODIR="$2"
            shift
            ;;
        --update-grub)
            UPDATEGRUB=TRUE
            ;;
    esac
done

if [ -z "$ISODIR" ]; then
	ISODIR=../iso/
fi

if [ -z "$REMOTE_URL" ]; then
	exit
fi

echo "###### pull.iso.sh url: $REMOTE_URL"

if [ -z "$REMOTE_REGEX" ]; then
	echo "# REMOTE_REGEX not defined"
	exit
fi
if [ -z "$CURRENT_REGEX" ]; then
	echo "# Using REMOTE_REGEX as CURRENT_REGEX"
	CURRENT_REGEX=$REMOTE_REGEX
fi

CURRENTISO=`ls $ISODIR | grep -m 1 -oP "$CURRENT_REGEX"`
if [ -z "$CURRENTISO" ]; then
	echo "# Could not find current iso (Using $CURRENT_REGEX)"
	read -e -n1 -p "Continue [y/N]: " OPTION
	if [ "$OPTION" == "n" ] || [ "$OPTION" == "" ]; then
		exit
	fi
fi

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
	FTPCHECK=`echo $REMOTE_URL | grep -P "^ftp://"`
	if [ $? -ne 0 ] ; then
		echo "# $REMOTE_URL not FTP"
		exit
	fi
	LATESTISO=`curl --connect-timeout 10 --list-only "$REMOTE_URL" | grep -m 1 -oP "$REMOTE_REGEX"`
	##wget $md5_addr | grep $new_iso | $ISODIR$new_iso.md5sum
fi

echo "# Latest ISO match: $LATESTISO"
echo "# Current ISO match: $CURRENTISO"
exit

if [ "$LATESTISO" != "$CURRENTISO" ] ; then
	echo "# Unable to match ISO filename to latest available"
	read -e -n1 -p "download $LATESTISO [Y/n]: " OPTION
	if [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then

		#pushd $ISODIR
			#rm $CURRENTISO
			#rm $CURRENTISO.md5sum

			echo "## Downloading $LATEST_REMOTE"

			#wget $LATEST_URL

			#newmd5=$(/sbin/md5 "$LATESTISO" | /usr/bin/cut -f 2 -d "=")
		#popd

		#if [ -z $md5sum ] ; then
			#echo "md5sum is undefined, unable to verify ISO"
		#else
			#if failed_checksum #ask download again?
			
			#fi
		#fi

		#if [ $UPDATEGRUB == true ] ; then
		#if $CURRENTISO undefined
			#try regex sed over grub.cfg?
		#else
			#sed "s/$CURRENTISO/$LATESTISO/" ../boot/grub/grub.cfg
		#fi
		#fi
	fi
fi

