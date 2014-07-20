#!/bin/bash
ISO_PATH_GRUB=/bootisos/
ISO_PATH_REL=../..$ISO_PATH_GRUB
SOURCES_PATH=../iso_sources/
REGEN_CFG=false

function check_utilities {
	command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
	command -v wget > /dev/null || { echo "## please install wget" ; exit 1 ; }
	command -v md5sum > /dev/null || { echo "## please install coreutils" ; exit 1 ; }
	command -v xml_grep > /dev/null || { echo "## please install xml_grep" ; exit 1 ; }
}

function check_isopath {
	mkdir -p $ISO_PATH_REL
}

function pull_sourceforge {
	PROJECTNAME=`echo $REMOTE_URL | grep -oiPh 'projects/(.*?)/' |cut -f2 -d/`

	if [ ! -z $SOURCEFORGE_PATH ]; then
		PROJECTRSSPATH="?path=$SOURCEFORGE_PATH"
	fi

	PROJECTRSS="https://sourceforge.net/projects/$PROJECTNAME/rss$PROJECTRSSPATH"
	SOURCEFORGE_REGEX="${FILE_REGEX//$}"

	echo "# scanning : $PROJECTRSS"

	SOURCEFORGE_OUTPUT=(`curl -L --max-time 30 -s $PROJECTRSS \
		| xml_grep --root "/rss/channel/item/title" \
		--root "/rss/channel/item/media:content" \
		--text_only \
		| grep -m 1 -iP -A 1 "$SOURCEFORGE_REGEX"`)

	LATEST_ISO=${SOURCEFORGE_OUTPUT[0]##*/}
	LATEST_MD5=${SOURCEFORGE_OUTPUT[1]}

	unset SOURCEFORGE_OUTPUT PROJECTRSSPATH

	echo "# Found $LATEST_ISO md5: $LATEST_MD5"

	LATEST_REMOTE="http://downloads.sourceforge.net/$PROJECTNAME/$LATEST_ISO"
}

function pull_ftp {
	LATEST_ISO=`curl -s --disable-epsv --max-time 30 --list-only "$REMOTE_URL" | grep -m 1 -oiP "$FILE_REGEX"`

	LATEST_REMOTE="${REMOTE_URL%/}/$LATEST_ISO"
}

function pull_http {
	LATEST_ISO=$(basename $REMOTE_URL)
	# TODO : possible to check not 404?
	# TODO : check LATEST_ISO with $FILE_REGEX ? except if REMOTE_COMPRESSED
	LATEST_REMOTE=$REMOTE_URL
}

function pull_md5 {
	if [ ! -z $REMOTE_MD5 ] ; then
		if echo "$REMOTE_MD5" | grep -qiP "^\." ; then
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

function extract_compressed {
	if [ -f $LATEST_ISO ] ; then
		case $LATEST_ISO in
		*.tar.bz2)   tar xvjf $LATEST_ISO ;;
		*.tar.gz)    tar xvzf $LATEST_ISO ;;
		*.bz2)       bunzip2 $LATEST_ISO ;;
		*.rar)       unrar x $LATEST_ISO ;;
		*.gz)        gunzip $LATEST_ISO ;;
		*.tar)       tar xvf $LATEST_ISO ;;
		*.tbz2)      tar xvjf $LATEST_ISO ;;
		*.tgz)       tar xvzf $LATEST_ISO ;;
		*.zip)       unzip $LATEST_ISO ;;
		*.Z)         uncompress $LATEST_ISO ;;
		*.7z)        7z x $LATEST_ISO ;;
		*)           return ;;
		esac
		echo "# Extracted $LATEST_ISO"
		check_local
		if [ -f $CURRENT_ISO_NAME ] ; then
			if confirm "remove $LATEST_ISO? [y/N]" ; then
				rm $LATEST_ISO
			fi
			LATEST_ISO=$CURRENT_ISO_NAME
		fi
     fi
}

function download_remote_iso {
	if confirm "download $LATEST_ISO? [y/N]" ; then
		pull_md5

		if [ ! -z $CURRENT_ISO_NAME ]; then
			if confirm "remove $CURRENT_ISO_NAME? [y/N]" ; then
				rm $CURRENT_ISO_NAME

				if [ -f $CURRENT_ISO_NAME.md5 ] ; then
					rm $CURRENT_ISO_NAME.md5
				fi

				if [ -f $CURRENT_ISO_NAME.grub.cfg ] ; then
					rm $CURRENT_ISO_NAME.grub.cfg
				fi
			fi
		fi

		wget $LATEST_REMOTE

		if [ $? -ne 0 ] ; then
			echo "# Download error, exiting"
			exit
		fi

		if $REMOTE_COMPRESSED ; then
			extract_compressed
		fi

		if [ -f $LATEST_ISO ] ; then
			echo "# generating $LATEST_ISO.md5"
			md5sum $LATEST_ISO > $LATEST_ISO.md5

			if [ -f $LATEST_ISO.md5 ] ; then
				if [ -z $LATEST_MD5 ] ; then
					echo "# no remote md5sum, unable to verify ISO"
				else
					if [ `cat $LATEST_ISO.md5 | cut -d " " -f 1` != $LATEST_MD5 ] ; then
						echo "# MD5 CHECKSUM COMPARISON FAILED, exiting"
						echo "# You should delete this ISO and re-download"
						# TODO : offer redownload?
						return
					else
						echo "# md5 checksum compared and matched!"
					fi
				fi
			fi

			generate_grub_cfg

			if [ ! -z "$CURRENT_ISO_NAME" ]; then
				echo "# Updated $CURRENT_ISO_NAME to $LATEST_ISO"
			fi
		fi
	fi
}

function check_local {
	echo "# Checking $ISO_PATH_REL using $FILE_REGEX"
	CURRENT_ISO_NAME=`ls -t . | grep -m 1 -oiP "$FILE_REGEX"`
	if [ -z "$CURRENT_ISO_NAME" ]; then
		echo "# Could not match local ISO!"
	else
		echo "# Local ISO matched: $CURRENT_ISO_NAME"
	fi
}

function generate_grub_cfg {
	if [ -n "$GRUB_CONTENTS" ] ; then
		GRUB_FILE=$LATEST_ISO.grub.cfg
		if [ -f $LATEST_ISO ] ; then
			echo "# generating $GRUB_FILE"
			echo "$GRUB_CONTENTS" | \
				sed -e "s|_iso_name_|$LATEST_ISO|" \
				-e "s|_iso_path_|$ISO_PATH_GRUB$LATEST_ISO|" \
				 > $GRUB_FILE
		else
			echo "# not generating $GRUB_FILE, $LATEST_ISO doesn't exist"
		fi
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
			if [ $REMOTE_COMPRESSED ] ; then
				if [ ! -z $CURRENT_ISO_NAME ] ; then
					echo "# Skipping: compressed remote and local exists"
					return
				fi
			fi
			echo "# Preparing to download $LATEST_ISO"
			echo "# From: $LATEST_REMOTE"
			download_remote_iso			
		fi
	fi
}

function force_regenerate_grub_cfg {
	check_local
	LATEST_ISO=$CURRENT_ISO_NAME
	generate_grub_cfg
}

function read_source {
	source $1
	echo "#####################################"
	if [ -z $SKIP ]; then
		pushd $ISO_PATH_REL > /dev/null
		if $REGEN_CFG ; then
			force_regenerate_grub_cfg
		else
			if [ -n $REMOTE_URL ] ; then
				echo "# updating iso using values from: $f"

				if [ -z "$FILE_REGEX" ]; then
					echo "# FILE_REGEX not defined"
				else
					check_remote
				fi
			fi
		fi
		popd > /dev/null
	else
		echo "# skipping $1"
	fi
}

function load_sources {
	for f in `find $SOURCES_PATH -type f -name "*.conf" -printf "%f\n"`
	do
		# TODO : localize variables to each iteration?
		read_source $SOURCES_PATH$f

		unset REMOTE_URL FILE_REGEX REMOTE_MD5 SOURCEFORGE_PATH REMOTE_COMPRESSED GRUB_FILE GRUB_CONTENTS SKIP CURRENT_ISO_NAME LATEST_ISO LATEST_REMOTE LATEST_MD5
	done
}

check_utilities
check_isopath
load_sources
echo "# Done"
