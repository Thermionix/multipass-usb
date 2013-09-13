#!/bin/bash

pushd ../tables/

tablesXP=tables_xp_free_small.zip
wget -O $tablesXP http://downloads.sourceforge.net/ophcrack/$tablesXP &&
unzip $tablesXP -d `basename $tablesXP .zip`

tablesVISTA=tables_vista_free.zip
wget -O $tablesVISTA http://downloads.sourceforge.net/ophcrack/tables_vista_free.zip &&
unzip $tablesVISTA -d `basename $tablesVISTA .zip`

popd
