#!/bin/bash
ISO_PATH=../bootisos/
SOURCES_PATH=./sources/

function check_utilities {
	command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
	command -v wget > /dev/null || { echo "## please install wget" ; exit 1 ; }
	command -v md5sum > /dev/null || { echo "## please install coreutils" ; exit 1 ; }
	# TODO : check python
}

function pull_sourceforge {
	PROJECTNAME=`echo $REMOTE_URL | grep -oPh 'projects/(.*?)/' |cut -f2 -d/`
	echo "# Projectname $PROJECTNAME"

	PROJECTJSON="http://sourceforge.net/api/project/name/$PROJECTNAME/json"
	PROJECTID=`curl -s $PROJECTJSON|

	python -c "import json; import sys;print((json.load(sys.stdin))['Project']['id'])"`
	echo "# SourceForge Project: $PROJECTNAME Id: $PROJECTID"

	PROJECTRSS="http://sourceforge.net/api/file/index/project-id/$PROJECTID/mtime/desc/limit/500/rss"
	echo "# RSS: $PROJECTRSS"

	LATEST_ISO=`curl --max-time 30 -s $PROJECTRSS | grep "<title>" | grep -m 1 -oP "$REMOTE_REGEX"`
	LATEST_REMOTE="http://downloads.sourceforge.net/$PROJECTNAME/$LATEST_ISO"
}

function pull_ftp {
	if ! `echo $REMOTE_URL | grep -q -P "^ftp://"` ; then
		echo "# $REMOTE_URL not FTP"
		exit
	fi

	LATEST_ISO=`curl -s --disable-epsv --max-time 30 --list-only "$REMOTE_URL" | grep -m 1 -oP "$REMOTE_REGEX"`

	LATEST_REMOTE="${REMOTE_URL%/}/$LATEST_ISO"
}

function pull_md5 {
	## Insert magic here to get MD5sum from sourceforge
	# /(\/project\/showfiles.php\?group_id=\d+)/
	#LATEST_MD5=""

	if [ ! -z $REMOTE_MD5 ] ; then
		if echo "$REMOTE_MD5" | grep -qP "^." ; then
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

		pushd $ISO_PATH
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
			echo "REPLACED $CURRENT_ISO_NAME WITH $LATEST_ISO"
			update_source_grub
		popd
	fi
}

function check_local {
	echo "# Checking $ISO_PATH using $LOCAL_REGEX"
	CURRENT_ISO_NAME=`ls -t $ISO_PATH | grep -m 1 -oP "$LOCAL_REGEX"`
	if [ -z "$CURRENT_ISO_NAME" ]; then
		echo "# Could not match local ISO!"
	else
		echo "# Local ISO matched: $CURRENT_ISO_NAME"
	fi
}

function update_source_grub {
	if [ ! -z "$GRUB_CFG" ] ; then
		if [ -z "$CURRENT_ISO_NAME" ]; then
			echo "# attempting to replace filename using regex in grub.cfg"
			# generate patch?
			#sed -i -e "s|$LOCAL_REGEX|$LATEST_ISO|" $GRUB_CFG
		else
			echo "# updating grub.cfg"
			sed -i -e "s/$CURRENT_ISO_NAME/$LATEST_ISO/" $GRUB_CFG
		fi
	fi
}

function check_remote {
	if `echo "$REMOTE_URL" | grep -q "sourceforge.net"` ; then
		pull_sourceforge
	else
		pull_ftp
	fi

	if [ -z $LATEST_ISO ] ; then
		echo "# Could not locate remote ISO information"
		# TODO : Break ?
	else
		echo "# Latest Remote ISO: $LATEST_ISO"

		check_local

		if [ "$LATEST_ISO" == "$CURRENT_ISO_NAME" ] ; then
			echo "# Remote & Local ISO filenames match, aborting"
			# TODO : Break?
		else
			echo "# Preparing to download $LATEST_ISO"
			echo "# From: $LATEST_REMOTE"
			download_remote_iso
		fi
	fi
}

function read_source {
	# TODO : Yes/No on update via REMOTE_URL ?
	# TODO : Read in IGNORE=True ?
	source $1
	if [ -n $REMOTE_URL ] ; then
		echo "#####################################"
		echo "# updating iso using values from: $f"

		if [ -z "$REMOTE_REGEX" ]; then
			echo "# REMOTE_REGEX not defined"
			exit 1
		fi
		if [ -z "$LOCAL_REGEX" ]; then
			#echo "# Using REMOTE_REGEX as LOCAL_REGEX"
			LOCAL_REGEX=$REMOTE_REGEX
		fi

		check_remote
	fi
}

function load_sources {
	for f in `find $SOURCES_PATH -type f -name "*.txt" -printf "%f\n"`
	do
		read_source $SOURCES_PATH$f
		unset REMOTE_URL REMOTE_REGEX REMOTE_MD5 LOCAL_REGEX GRUB_CFG CURRENT_ISO_NAME LATEST_ISO LATEST_REMOTE LATEST_MD5
	done
}

check_utilities
load_sources
