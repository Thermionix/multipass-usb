#!/bin/bash

set -e

SCRIPTDIR="$PWD"
OUTDIR=../../_ISO/bios/

pushd $OUTDIR > /dev/null

while IFS="," read NAME  URL  AUTORUN
do
	if [ ! -f $NAME ] ; then
		echo "# Building $NAME"
		# TODO : if ! -z $AUTORUN don't pass it
		bash $SCRIPTDIR/generate.dos.image.sh -n "$NAME" -f "$URL" -x "$AUTORUN"
	fi
    echo $NAME
done < $SCRIPTDIR/images.list

popd > /dev/null
