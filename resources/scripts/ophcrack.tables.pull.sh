#!/bin/bash

tabledir=../../tables/
mkdir -p $tabledir

function download_table() {
	tablefile=$1
	if [ ! -f $tablefile ] ; then
		wget -O $tablefile http://downloads.sourceforge.net/ophcrack/$tablefile
	fi
	if [ -f $tablefile ] ; then
		unzip $tablefile -d `basename $tablefile .zip`
	fi
}

pushd $tabledir

download_table tables_xp_free_small.zip

download_table tables_vista_free.zip

popd
