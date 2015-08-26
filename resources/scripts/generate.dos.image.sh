#!/bin/bash
set -e

command -v biosdisk > /dev/null || { echo "## please install biosdisk (aur pkg biosdisk-git)" ; exit 1 ; }

usage() {
cat <<'END_HEREDOC'
Usage:
./generate.dos.image.sh -n "dell.bios.O755-A22.freedos.img" -f http://downloads.dell.com/FOLDER01133147M/1/O755-A22.exe

-n <name for image>
-f <file or url>
-o <Option to be passed to BIOS executable file at runtime>

The filename can be a file local to the system, or it can be an ftp  or
http  URL to a raw BIOS file or BIOS floppy image. For example, passing
"http://somedomain.com/700m_A00.exe"                                 or
"ftp://ftp.dell.com/bios/700m_A00.exe" to biosdisk will work correctly.
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

echo "Generation $NAME from $FILE"

ISO_PATH_GRUB=/bootisos/
ISO_PATH_REL=../..$ISO_PATH_GRUB

OUTPUT_FILE=$ISO_PATH_REL$NAME

#sudo biosdisk mkimage [-o option] [-i destination] /path/to/.exe

sudo biosdisk mkimage -i $OUTPUT_FILE $FILE
sudo chown `whoami`:`id -g -n` $OUTPUT_FILE

GRUB_CONTENTS=$(cat <<'END_HEREDOC'
menuentry "_file_name_" {
	set file_path="_file_path_"
	linux16 /boot/grub/memdisk
	initrd16 $file_path
}
END_HEREDOC
)

GRUB_FILE=$OUTPUT_FILE.grub.cfg
if [ -f $OUTPUT_FILE ] ; then
	echo "# generating $GRUB_FILE"

	echo "$GRUB_CONTENTS" | \
		sed -e "s#_file_name_#$NAME#" \
		-e "s#_file_path_#$ISO_PATH_GRUB$NAME#" \
		 > $GRUB_FILE
fi

