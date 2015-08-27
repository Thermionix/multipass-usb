#!/bin/bash
set -e

ROOT_PATH=".."
ISO_PATH=/bootisos/
RELATIVE_ISO_PATH="$ROOT_PATH$ISO_PATH"
TEMPLATES_PATH="$ROOT_PATH/scripts/grub_templates/"

function detect_drive_label {
	echo "# Detecting Drive Label"
	DRIVE_LABEL=$(mount | grep ${PWD%/*/*} | cut -f1 -d ' ' | xargs sudo blkid -s LABEL -o value)
	[ ! -z $DRIVE_LABEL ] || { echo "## unable to detect drive label" ; exit 1 ; }
}

function check_regen_cfg {
	REGEN_CFG=false
	if whiptail --defaultno --yesno "only regenerate .cfg files in $ISO_PATH_REL?\n(will not download anything)" 15 60 ; then
		REGEN_CFG=true
	fi
}

function check_utilities {
	command -v curl > /dev/null || { echo "## please install curl" ; exit 1 ; }
	command -v wget > /dev/null || { echo "## please install wget" ; exit 1 ; }
	command -v md5sum > /dev/null || { echo "## please install coreutils" ; exit 1 ; }
	command -v xml_grep > /dev/null || { echo "## please install xml_grep (pkg perl-xml-twig)" ; exit 1 ; }
	command -v whiptail > /dev/null || { echo "## whiptail (pkg libnewt) required for this script" ; exit 1 ; }
	command -v isoinfo > /dev/null || { echo "## isoinfo (pkg cdrkit) required for this script" ; exit 1 ; }
}

function check_isopath {
	mkdir -p $RELATIVE_ISO_PATH
}


function extract_compressed {
	if [ -f $LATEST_REMOTE_FILE ] ; then
		case $LATEST_REMOTE_FILE in
		*.tar.bz2)   tar xvjf $LATEST_REMOTE_FILE ;;
		*.tar.gz)    tar xvzf $LATEST_REMOTE_FILE ;;
		*.bz2)       bunzip2 $LATEST_REMOTE_FILE ;;
		*.rar)       unrar x $LATEST_REMOTE_FILE ;;
		*.gz)        gunzip $LATEST_REMOTE_FILE ;;
		*.tar)       tar xvf $LATEST_REMOTE_FILE ;;
		*.tbz2)      tar xvjf $LATEST_REMOTE_FILE ;;
		*.tgz)       tar xvzf $LATEST_REMOTE_FILE ;;
		*.zip)       unzip $LATEST_REMOTE_FILE ;;
		*.Z)         uncompress $LATEST_REMOTE_FILE ;;
		*.7z)        7z x $LATEST_REMOTE_FILE ;;
		*)           return ;;
		esac
		echo "# Extracted $LATEST_REMOTE_FILE"
		check_local
		if [ -f $CURRENT_ISO_NAME ] ; then
			if confirm "remove $LATEST_REMOTE_FILE? [y/N]" ; then
				rm $LATEST_REMOTE_FILE
			fi
			LATEST_REMOTE_FILE=$CURRENT_ISO_NAME
		fi
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

function pull_sourceforge {
	PROJECTNAME=$(echo $source_url | grep -oiPh 'projects/(.*?)/' |cut -f2 -d/)

	SOURCEFORGE_PATH=$(echo $source_url | grep -oiPh "projects/(.*?)/(.*?)/" |cut -f3 -d/)
	if [ ! -z $SOURCEFORGE_PATH ]; then
		PROJECTRSSPATH="?path=/$SOURCEFORGE_PATH/"
	fi

	PROJECTRSS="https://sourceforge.net/projects/$PROJECTNAME/rss$PROJECTRSSPATH"
	SOURCEFORGE_REGEX="${FILE_REGEX//$}"

	echo "# scanning : $PROJECTRSS"

	SOURCEFORGE_OUTPUT=($(curl -L --max-time 30 -s $PROJECTRSS \
		| xml_grep --root "/rss/channel/item/title" \
		--root "/rss/channel/item/media:content" \
		--text_only \
		| grep -m 1 -iP -A 1 "$SOURCEFORGE_REGEX"))

	LATEST_REMOTE_FILE=${SOURCEFORGE_OUTPUT[0]##*/}
	LATEST_MD5=${SOURCEFORGE_OUTPUT[1]}

	echo "# Found $LATEST_REMOTE_FILE md5: $LATEST_MD5"

	LATEST_REMOTE="http://downloads.sourceforge.net/$PROJECTNAME/$LATEST_REMOTE_FILE"
}

function pull_ftp {
	SOURCE_FOLDER=`dirname $source_url`"/"
	echo "# checking $SOURCE_FOLDER"
	LATEST_REMOTE_FILE=$(curl -s --disable-epsv --max-time 30 --list-only "$SOURCE_FOLDER" | grep -m 1 -oiP "$FILE_REGEX")
	LATEST_REMOTE="${SOURCE_FOLDER%/}/$LATEST_REMOTE_FILE"
}

function pull_http {
	LATEST_REMOTE_FILE=$(basename $source_url)
	# TODO : possible to check not 404?
	# TODO : check LATEST_REMOTE_FILE with $FILE_REGEX ? except if REMOTE_COMPRESSED
	LATEST_REMOTE=$source_url
}

function pull_md5 {
	if [ ! -z $source_md5 ] ; then
		if echo "$source_md5" | grep -qiP "^\." ; then
			echo "# Remote MD5 is an extension, prefixing with ISO name"
			source_md5=$LATEST_REMOTE_FILE$source_md5
		fi

		SOURCE_FOLDER=`dirname $source_url`"/"

		echo "# Attempting to get MD5 checksum from $SOURCE_FOLDER$source_md5"

		LATEST_MD5=$(curl -s --disable-epsv --max-time 30 "$SOURCE_FOLDER$source_md5" | grep -m 1 $LATEST_REMOTE_FILE | cut -d " " -f 1)
		echo "# Remote MD5: $LATEST_MD5"
	fi
}

function download_remote_iso {
	if confirm "download $LATEST_REMOTE_FILE? [y/N]" ; then
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

		if [ -f $LATEST_REMOTE_FILE ] ; then
			echo "# generating $LATEST_REMOTE_FILE.md5"
			md5sum $LATEST_REMOTE_FILE > $LATEST_REMOTE_FILE.md5

			if [ -f $LATEST_REMOTE_FILE.md5 ] ; then
				if [ -z $LATEST_MD5 ] ; then
					echo "# no remote md5sum, unable to verify ISO"
				else
					if [ $(cat $LATEST_REMOTE_FILE.md5 | cut -d " " -f 1) != $LATEST_MD5 ] ; then
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
				echo "# Updated $CURRENT_ISO_NAME to $LATEST_REMOTE_FILE"
			fi
		fi
	fi
}

function check_local {
	echo "# Checking $ISO_PATH using $FILE_REGEX"
	CURRENT_ISO_NAME=$(ls -t . | grep -m 1 -oiP "$FILE_REGEX")
	if [ -z "$CURRENT_ISO_NAME" ]; then
		echo "# Could not match local ISO!"
	else
		echo "# Local ISO matched: $CURRENT_ISO_NAME"
	fi
}

function compare_to_local {
	check_local

	if [ "$LATEST_REMOTE_FILE" == "$CURRENT_ISO_NAME" ] ; then
		echo "# Remote & Local ISO filenames match, skipping"
	else
		if [ $REMOTE_COMPRESSED ] ; then
			if [ ! -z $CURRENT_ISO_NAME ] ; then
				echo "# Skipping: compressed remote and local exists"
				return
			fi
		fi
		echo "# Preparing to download $LATEST_REMOTE_FILE"
		echo "# From: $LATEST_REMOTE"
		download_remote_iso			
	fi
}

function check_remote {
	if $(echo "$source_url" | grep -qi "sourceforge.net") ; then
		pull_sourceforge
	elif $(echo $source_url | grep -qiP "^ftp://") ; then
		pull_ftp
	else
		pull_http
	fi
	
	if [ -z $LATEST_REMOTE_FILE ] ; then
		echo "# Could not locate remote ISO information"
	else
		echo "# Latest Remote ISO: $LATEST_REMOTE_FILE"

		compare_to_local
	fi
}

function generate_grub_cfg {
	if [ -n "$grub_contents" ] ; then
		GRUB_FILE=$LATEST_ISO.grub.cfg
		if [ -f $LATEST_ISO ] ; then
			echo "# generating $GRUB_FILE"
			ISO_LABEL=`isoinfo -d -i $LATEST_ISO | grep "Volume id" | awk '{print $3}'`
			echo "$grub_contents" | \
				sed -e "s#\(_iso_name_\|_file_name_\)#$LATEST_ISO#" \
				-e "s#\(_iso_path_\|_file_path_\)#$ISO_PATH$LATEST_ISO#" \
				-e "s|_drive_label_|$DRIVE_LABEL|" \
				-e "s|_iso_label_|$ISO_LABEL|" \
				 > $GRUB_FILE
		else
			echo "# not generating $GRUB_FILE, $LATEST_ISO doesn't exist"
		fi
	fi
}

function regenerate_grub_cfg {
	check_local
	if [ ! -z $CURRENT_ISO_NAME ] ; then
		LATEST_ISO=$CURRENT_ISO_NAME
		generate_grub_cfg
	fi
}

function read_template {
(
	pushd $TEMPLATES_PATH > /dev/null
	source $f
	popd > /dev/null

	pushd $RELATIVE_ISO_PATH > /dev/null
	echo "#####################################"
	if [ -z $source_skip ]; then
		if [ -n $source_url ] ; then
			FILE_REGEX=`basename $source_url`
			if [ -z "$FILE_REGEX" ]; then
				echo "# FILE_REGEX not defined"
			else
				if $REGEN_CFG ; then
					echo "# updating grub cfg using : $f"
					regenerate_grub_cfg
				else
					echo "# updating iso using values from : $f"
					check_remote
				fi
			fi
		fi
	else
		echo "# skipping $f"
	fi
	popd > /dev/null
)
}

function load_templates {
	for f in $(find $TEMPLATES_PATH -type f -name "*.source" -printf "%f\n")
	do
		read_template
	done
}

check_utilities
check_regen_cfg
detect_drive_label
check_isopath
load_templates
echo "# Done"

