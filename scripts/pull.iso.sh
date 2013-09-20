#!/bin/sh

bash dependencies.sh curl wget coreutils

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
	echo "#       if begins with a . we will append the remote filename to it"
	echo "# --outdir <directory> *optional*"
	echo "#       directory containing ISOs, defaults to ../iso/"
	echo "# --grub-cfg <grub.cfg> *optional*"
	echo "#     e.g. ../boot/grub/grub.cfg"
	echo "#       if specified will try update ISO filename in grub.cfg"
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
        --remote-md5)
            REMOTE_MD5="$1"
            shift
            ;;
        --outdir)
            ISODIR="$1"
            shift
            ;;
        --grub-cfg)
            GRUB_CFG="$1"
			shift
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
	echo "# Could not match local iso using $LOCAL_REGEX"
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
	LATESTISO=`curl --max-time 30 -s $PROJECTRSS | grep "<title>" | grep -m 1 -oP "$REMOTE_REGEX"`
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
	LATESTISO=`curl -s --disable-epsv --max-time 30 --list-only "$REMOTE_URL" | grep -m 1 -oP "$REMOTE_REGEX"`

	LATEST_REMOTE="${REMOTE_URL%/}/$LATESTISO"

	if [ ! -z $REMOTE_MD5 ] ; then
		if echo "$REMOTE_MD5" | grep -qP "^." ; then
			REMOTE_MD5=$LATESTISO$REMOTE_MD5
		fi

		LATEST_MD5=`curl -s --disable-epsv --max-time 30 "$REMOTE_URL$REMOTE_MD5" | grep -m 1 $LATESTISO | cut -d " " -f 1`
		echo "# Remote MD5: $LATEST_MD5"
	fi
fi

if [ "$LATESTISO" == "" ] ; then
	echo "# Unable to determine latest remote filename, exiting"
	exit
else
	echo "# Remote ISO match: $LATESTISO"
fi

if [ ! -z $CURRENTISO ]; then
	echo "# Local ISO match: $CURRENTISO"
fi

if [ "$LATESTISO" == "$CURRENTISO" ] ; then
	echo "# Remote & Local ISO filenames match, exiting"
	exit
else
	if [ -z $CURRENTISO ]; then
		echo "# Local Filename was not matched"
	else
		echo "# Remote & Local Filenames different"
	fi

	read -e -n1 -p "download $LATESTISO [Y/n]: " OPTION
	if [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then

		pushd $ISODIR
			if [ ! -z $CURRENTISO ]; then
				rm $CURRENTISO
				rm $CURRENTISO.md5sum
			fi

			wget $LATEST_REMOTE

			if [ $? -ne 0 ] ; then
				echo "# Download error, exiting"
				exit
			fi

			if [ -f $LATESTISO ] ; then
				echo "# generating $LATESTISO.md5"
				md5sum $LATESTISO | cut -d " " -f 1 > $LATESTISO.md5
			fi

			if [ -f $LATESTISO.md5 ] ; then
				if [ -z $LATEST_MD5 ] ; then
					echo "# no remote md5sum, unable to verify ISO"
				else
					if [ `cat $LATESTISO.md5` != $LATEST_MD5 ] ; then
						echo "# MD5 CHECKSUM COMPARISON FAILED, exiting"
						exit
					fi
				fi
			fi
		popd

		if [ ! -z "$GRUB_CFG" ] ; then
			if [ -z "$CURRENTISO" ]; then
				echo "# attempting to replace filename using regex in grub.cfg"
				sed -i -e "s|$LOCAL_REGEX|$LATESTISO|" $GRUB_CFG
			else
				echo "# updating grub.cfg"
				sed -i -e "s/$CURRENTISO/$LATESTISO/" $GRUB_CFG
			fi
		fi
	fi
fi

