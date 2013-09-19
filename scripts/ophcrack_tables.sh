#!/bin/bash

function download_table() {
	tablename=$1
	pushd ../tables/
	wget -O $tablename http://downloads.sourceforge.net/ophcrack/$tablename &&
	unzip $tablename -d `basename $tablename .zip`
	popd
}

download_table tables_xp_free_small.zip

download_table tables_vista_free.zip

