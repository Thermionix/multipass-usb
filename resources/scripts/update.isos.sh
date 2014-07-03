#!/bin/bash
ISO_PATH_GRUB=/bootisos/
ISO_PATH_REL=../..$ISO_PATH_GRUB
SOURCES_PATH=../iso_sources/

function check_utilities {
	command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
	command -v wget > /dev/null || { echo "## please install wget" ; exit 1 ; }
	command -v md5sum > /dev/null || { echo "## please install coreutils" ; exit 1 ; }
	# TODO : check python
}

function check_isopath {
	mkdir -p $ISO_PATH_REL
}

function pull_sourceforge {
	if [ -z "$SOURCEFORGE_REGEX" ]; then
		echo "# SOURCEFORGE_REGEX Not Defined!"
	else
		PROJECTNAME=`echo $REMOTE_URL | grep -oiPh 'projects/(.*?)/' |cut -f2 -d/`

		PROJECTJSON="http://sourceforge.net/api/project/name/$PROJECTNAME/json"
		PROJECTID=`curl -s $PROJECTJSON|python -c "import json; import sys;print((json.load(sys.stdin))['Project']['id'])"`
		echo "# SourceForge Project: $PROJECTNAME Id: $PROJECTID"

		PROJECTRSS="http://sourceforge.net/api/file/index/project-id/$PROJECTID/mtime/desc/limit/500/rss"

		echo "# scanning : $PROJECTRSS"
		echo "# with : $SOURCEFORGE_REGEX"
		LATEST_ISO=`curl --max-time 30 -s $PROJECTRSS | grep "<title>" | grep -m 1 -oiP "$SOURCEFORGE_REGEX"`
		LATEST_REMOTE="http://downloads.sourceforge.net/$PROJECTNAME/$LATEST_ISO"
	fi
}

function pull_ftp {
	LATEST_ISO=`curl -s --disable-epsv --max-time 30 --list-only "$REMOTE_URL" | grep -m 1 -oiP "$FILE_REGEX"`

	LATEST_REMOTE="${REMOTE_URL%/}/$LATEST_ISO"
}

function pull_http {
	LATEST_ISO=$(basename $REMOTE_URL)
	# TODO : possible to check not 404?
	# TODO : check LATEST_ISO with $FILE_REGEX
	LATEST_REMOTE=$REMOTE_URL
}

function pull_md5 {
	# TODO : magic here to get MD5sum from sourceforge
	# /(\/project\/showfiles.php\?group_id=\d+)/
	#LATEST_MD5=""

	if [ ! -z $REMOTE_MD5 ] ; then
		if echo "$REMOTE_MD5" | grep -qiP "^." ; then
			echo "# Remote MD5 is an extension, prefixing with ISO name"
			REMOTE_MD5=$LATEST_ISO$REMOTE_MD5
		fi

		echo "# Attempting to get MD5 checksum from $REMOTE_URL$REMOTE_MD5"

		LATEST_MD5=`curl -s --disable-epsv --max-time 30 "$REMOTE_URL$REMOTE_MD5" | grep -m 1 $LATEST_ISO | cut -d " " -f 1`
		echo "# Remote MD5: $LATEST_MD5"
	fi
}

function confirm {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

function download_remote_iso {
	if confirm "download $LATEST_ISO? [y/N]" ; then
		pull_md5

		pushd $ISO_PATH_REL
			if [ ! -z $CURRENT_ISO_NAME ]; then
				# TODO : confirm remove old files
				rm $CURRENT_ISO_NAME
				# TODO : check if md5 file exists
				rm $CURRENT_ISO_NAME.md5
			fi

			wget $LATEST_REMOTE

			if [ $? -ne 0 ] ; then
				echo "# Download error, exiting"
				exit
			fi

			if [ -f $LATEST_ISO ] ; then
				echo "# generating $LATEST_ISO.md5"
				md5sum $LATEST_ISO > $LATEST_ISO.md5
			fi

			if [ -f $LATEST_ISO.md5 ] ; then
				if [ -z $LATEST_MD5 ] ; then
					echo "# no remote md5sum, unable to verify ISO"
				else
					if [ `cat $LATEST_ISO.md5 | cut -d " " -f 1` != $LATEST_MD5 ] ; then
						echo "# MD5 CHECKSUM COMPARISON FAILED, exiting"
						echo "# You should delete this ISO and re-download"
						# TODO : offer redownload?
						exit
					fi
				fi
			fi
			generate_grub_cfg
			if [ ! -z "$CURRENT_ISO_NAME" ]; then
				echo "# Updated $CURRENT_ISO_NAME to $LATEST_ISO"
			fi
		popd
	fi
}

function check_local {
	echo "# Checking $ISO_PATH_REL using $FILE_REGEX"
	CURRENT_ISO_NAME=`ls -t $ISO_PATH_REL | grep -m 1 -oiP "$FILE_REGEX"`
	if [ -z "$CURRENT_ISO_NAME" ]; then
		echo "# Could not match local ISO!"
	else
		echo "# Local ISO matched: $CURRENT_ISO_NAME"
	fi
}

function generate_grub_cfg {
	if [ ! -z "$GRUB_FILE" && ! -z "$GRUB_CONTENTS" ] ; then
		echo "# generating $GRUB_FILE"

		echo "$GRUB_CONTENTS" | sed -e "s|_iso_name_|$LATEST_ISO|" -e "s|_iso_path_|$ISO_PATH_GRUB$LATEST_ISO|"  > $GRUB_FILE

		echo "# please double-check $GRUB_FILE"
	fi
}

function check_remote {
	if `echo "$REMOTE_URL" | grep -qi "sourceforge.net"` ; then
		pull_sourceforge
	elif `echo $REMOTE_URL | grep -qiP "^ftp://"` ; then
		pull_ftp
	else
		pull_http
	fi
	
	if [ -z $LATEST_ISO ] ; then
		echo "# Could not locate remote ISO information"
	else
		echo "# Latest Remote ISO: $LATEST_ISO"

		check_local

		if [ "$LATEST_ISO" == "$CURRENT_ISO_NAME" ] ; then
			echo "# Remote & Local ISO filenames match, skipping"
		else
			echo "# Preparing to download $LATEST_ISO"
			echo "# From: $LATEST_REMOTE"
			download_remote_iso
		fi
	fi
}

function read_source {
	source $1
	echo "#####################################"
	if [ -z $SKIP ]; then
		if [ -n $REMOTE_URL ] ; then
			echo "# updating iso using values from: $f"

			if [ -z "$FILE_REGEX" ]; then
				echo "# FILE_REGEX not defined"
			else
				check_remote
			fi
		fi
	else
		echo "# skipping $1"
	fi
}

function load_sources {
	for f in `find $SOURCES_PATH -type f -name "*.conf" -printf "%f\n"`
	do
		# TODO : localize variables to each iteration?
		read_source $SOURCES_PATH$f

		unset REMOTE_URL FILE_REGEX REMOTE_MD5 SOURCEFORGE_REGEX GRUB_FILE GRUB_CONTENTS SKIP CURRENT_ISO_NAME LATEST_ISO LATEST_REMOTE LATEST_MD5
	done
}

check_utilities
check_isopath
load_sources
