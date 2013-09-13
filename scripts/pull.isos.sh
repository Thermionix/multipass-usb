#!/bin/sh

#loop cat pull.isos.list $iso_regex $iso_addr $md5_addr

#cur_iso = ls -l ../iso/ | egrep $iso_regex

#if $iso_addr .contains sourceforge.net
ISO_REGEX="pmagic_(.*?).iso"
PROJECTNAME=partedmagic

PROJECTJSON="http://sourceforge.net/api/project/name/$PROJECTNAME/json"
PROJECTID=`curl -s $PROJECTJSON|
python -c "import json; import sys;print((json.load(sys.stdin))['Project']['id'])"`
echo "# SourceForge Project: $PROJECTNAME Id: $PROJECTID"
PROJECTRSS="http://sourceforge.net/api/file/index/project-id/$PROJECTID/mtime/desc/limit/20/rss"
echo "# RSS: $PROJECTRSS"
LATESTISO=`curl -s $PROJECTRSS | grep "<title>" | egrep -m 1 -o "$ISO_REGEX"`
echo "# Latest ISO match: $LATESTISO"
echo "wget http://downloads.sourceforge.net/$PROJECTNAME/$LATESTISO"

# /(\/project\/showfiles.php\?group_id=\d+)/

#      <link>http://sourceforge.net/projects/partedmagic/files/Stable/Parted%20Magic%202013_06_15/pmagic_2013_06_15.iso/download</link>


#cat $cur_iso.md5sum
# compare with
#curl $md5_addr

#if diff
	#rm $cur_iso
	#rm $cur_iso.md5sum

	#new_iso = wget_name
	#wget $ftp_addr ../iso/$new_iso
	#wget $md5_addr | grep $new_iso | ../iso/$new_iso.md5sum

	# md5sum $new_iso 
		# check against 
	# cat $new_iso.md5sum
	#if failed_checksum #ask download again?

	#sed 's/cur_iso/new_iso/' ../boot/grub/grub.cfg
#fi


#  curl -L -v  $url -o $outputfile 2>> logfile.txt
#  # use $(..) instead of backticks.
#  calculated_md5=$(/sbin/md5 "$file" | /usr/bin/cut -f 2 -d "=")
  # compare md5
#  case "$calculated_md5" in "$md5" )
#      echo "md5 ok"
#      echo "do something else here";;
#  esac
