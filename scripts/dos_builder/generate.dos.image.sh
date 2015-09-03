#!/bin/bash
set -e

command -v wget > /dev/null || { echo "## please install wget" ; exit 1 ; }
command -v md5sum > /dev/null || { echo "## please install coreutils" ; exit 1 ; }
command -v unzip > /dev/null || { echo "## please install unzip" ; exit 1 ; }
command -v mkisofs > /dev/null || { echo "## please install mkisofs (pkg cdrtools)" ; exit 1 ; }
# unix2dos
# 7z
# tar

usage() {
cat <<'END_HEREDOC'
Usage:
./generate.dos.image.sh -n "dell.bios.O755-A22.freedos.iso" -f http://downloads.dell.com/FOLDER01133147M/1/O755-A22.exe

-n <name for image>
-f <file or url>
-x <exe to run in autoexec>

The filename can be a file local to the system, or it can be an ftp  or
http  URL to a raw BIOS file or BIOS floppy image. For example, passing
"http://somedomain.com/700m_A00.exe" or
"ftp://ftp.dell.com/bios/700m_A00.exe" will work.
END_HEREDOC

exit 1; }

while getopts ":n:f:" o; do
    case "${o}" in
        n)
            NAME=${OPTARG}
            ;;
        f)
            FILE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${NAME}" ] || [ -z "${FILE}" ]; then
    usage
fi

function check_base_img() {
	echo "# Checking $FDOEMCD exists"

	if [ ! -f $FDOEMCD ] ; then
		wget -O $FDOEMCD http://www.fdos.org/bootdisks/ISO/FDOEMCD.builder.zip
	fi
}

function extract_base_img() {
	unzip $FDOEMCD 'FDOEMCD/CDROOT/*' -d $WORKDIR
}

function write_autoexec() {
if [ ! -z $autorun_arg ] ; then
cat <<-'EOF' | tee AUTORUN.BAT
@ECHO OFF
CLS
$autorun_arg
EOF
unix2dos AUTORUN.BAT
fi
}

function gen_iso() {

#pushd $CDROOT/.. > /dev/null

mkisofs \
-b isolinux/isolinux.bin \
-no-emul-boot \
-boot-load-size 4 \
-boot-info-table \
-N \
-J \
-r \
-c boot.catalog \
-hide-joliet boot.catalog \
-hide boot.catalog \
-o "$NAME" \
"$CDROOT"

}

function check_file() {
	if $(echo $FILE | grep -qiP "^ftp://|^http://|^https://") ; then
		FILE_URL=$FILE
		FILE=$(basename $FILE)
	fi

	if [ ! -f $FILE ] ; then
		if [ -z $FILE_URL ] ; then
			echo "# Getting remote file"
			# wget $FILE_URL
		else
			echo "# $FILE missing!"
			exit 1
		fi		
	fi
}

function check_compressed_file() {
	FILE_PATH="${OUTDIR%%/}/$FILE"
	if [ -f $FILE_PATH ] ; then
	case $FILE_PATH in
	*.tar.bz2)   tar xvjf $FILE_PATH ;;
	*.tar.gz)    tar xvzf $FILE_PATH ;;
	*.bz2)       bunzip2 $FILE_PATH ;;
	*.rar)       unrar x $FILE_PATH ;;
	*.gz)        gunzip $FILE_PATH ;;
	*.tar)       tar xvf $FILE_PATH ;;
	*.tbz2)      tar xvjf $FILE_PATH ;;
	*.tgz)       tar xvzf $FILE_PATH ;;
	*.zip)       unzip $FILE_PATH ;;
	*.7z)        7z x $FILE_PATH ;;
	*)           cp $FILE_PATH . ;;
	esac
	fi
}

echo "Generating $NAME from $FILE"
FDOEMCD="FDOEMCD.builder.zip"
WORKDIR=`mktemp -d`
OUTDIR="$PWD"
CDROOT="${WORKDIR%%/}/FDOEMCD/CDROOT"
pushd $OUTDIR > /dev/null
check_base_img
check_file
extract_base_img
pushd $CDROOT > /dev/null
check_compressed_file
write_autoexec
popd > /dev/null
gen_iso
rm -r $WORKDIR
md5sum $NAME > $NAME.md5
popd > /dev/null

## test iso
# qemu-system-i386 -localtime -boot d -cdrom $NAME

