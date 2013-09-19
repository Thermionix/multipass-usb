#!/bin/sh

function usage() {
	echo "### pull.iso.sh usage"
	echo "# Supports retrieving/updating an ISO from sourceforge or ftp server"
	echo "# --remote-url <url to download from>"
	echo "#     e.g. http://sourceforge.net/projects/projectx/"
	echo "#          ftp://ftp.example.net/linux/archlinux/iso/latest/"
	echo "# --remote-regex <regex>"
	echo "#     e.g. /gparted-live-stable(.*?)/\K(gparted-live(.*?)amd64.iso)"
	echo "#       matches a particular group in sourceforge (live-stable)"
	echo "#       it's important that the regex match only returns the filename"
	echo "#       i.e. only the portion after \K relates to the filename"
	echo "# --local-regex <regex> *optional*"
	echo "#       if the above remote regex contains extra matching, i.e. related to sourceforge"
	echo "#       and won't be able to match the file in the local directory"
	echo "#       we specify an extra pattern to match the local file"
	echo "#       if not specified we'll use the remote pattern to try locate the local file"
	echo "# --remote-md5 <filename> *optional*"
	echo "#       filename in FTP directory containing md5sum for the ISO"
	echo "# --outdir directory *optional*"
	echo "#       directory containing ISOs, defaults to ../iso/"
	exit
}

while [[ $1 = -* ]]; do
    arg=$1; shift

    case $arg in
        --remote-url)
            REMOTE_URL="$1"
            shift
            ;;
        --remote-regex)
            REMOTE_REGEX="$1"
            shift
            ;;
        --local-regex)
            LOCAL_REGEX="$1"
            shift
            ;;
        --outdir)
            ISODIR="$1"
            shift
            ;;
        --update-grub)
            UPDATEGRUB=TRUE
            ;;
		--help)
			usage
			;;
    esac
done

if [ -z "$ISODIR" ]; then
	ISODIR=../iso/
fi

if [ -z "$REMOTE_URL" ]; then
	echo "# --remote-url not defined"
	usage
fi

echo "## begin pull.iso.sh url: $REMOTE_URL"

if [ -z "$REMOTE_REGEX" ]; then
	echo "# --remote-regex not defined"
	usage
fi
if [ -z "$LOCAL_REGEX" ]; then
	echo "# Using --remote-regex as --local-regex"
	LOCAL_REGEX=$REMOTE_REGEX
fi

CURRENTISO=`ls $ISODIR | grep -m 1 -oP "$LOCAL_REGEX"`
if [ -z "$CURRENTISO" ]; then
	echo "# Could not find current iso (Using $LOCAL_REGEX)"
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

