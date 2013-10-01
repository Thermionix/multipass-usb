#!/bin/bash
iso_path=../iso/

for f in `find $iso_path -type f -name "*.grub.cfg" -printf "%f\n"`
do
	GRUB_CFG=$iso_path$f
	if grep -s "update-enabled true" $grubcfg > /dev/null ; then
		echo "updating $f"
		variableList="--outdir $iso_path"
		for variableName in remote-url remote-regex remote-md5 local-regex; do
			variableValue=`grep "^#$variableName" $GRUB_CFG | cut -f2 -d" "`
			if [ "$variableValue" != "" ] ; then
				variableList+=" --$variableName $variableValue"
			fi
		done
		bash pull.iso.sh $variableList
		exit 0

		#grep output "successfuly replaced oldfile with newfile
		if [ ! -z "$GRUB_CFG" ] ; then
			if [ -z "$CURRENTISO" ]; then
				echo "# attempting to replace filename using regex in grub.cfg"
				sed -i -e "s|$LOCAL_REGEX|$LATESTISO|" $GRUB_CFG
			else
				echo "# updating grub.cfg"
				sed -i -e "s/$CURRENTISO/$LATESTISO/" $GRUB_CFG
			fi
		fi
	fi
done

bash gen.grub.cfg.sh
