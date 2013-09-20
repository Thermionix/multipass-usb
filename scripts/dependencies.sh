#!/bin/bash

function usage() {
	echo "### dependencies.sh <depedency1> <depedency2> <depedency3>"
	echo "# will check that the dependency is installed"
	echo "# if not offer the user the option to try install it"
}

PKGSTOINSTALL=""
while [[ ! -z $1 ]]; do
	dep=$1; shift
	echo "checking for dependency ${dep}"
	# Debian, Ubuntu etc...
	if [[ `dpkg -l | grep -w "ii\s*${dep} "` ]]; then
		continue
	# OpenSuse, Mandriva, Fedora, CentOs, ecc. (with rpm)
	elif which rpm &> /dev/null; then
		if [[ `rpm -q ${dep}` ]]; then
			continue
		fi
	# ArchLinux (with pacman)
	elif which pacman &> /dev/null; then
		if [[ `pacman -Qqe | grep "${dep}"` ]]; then
			continue
		fi
	else
		PKGSTOINSTALL=$PKGSTOINSTALL" "${dep}
	fi
done

# If some dependencies are missing, asks if user wants to install
if [ "$PKGSTOINSTALL" != "" ]; then
	echo "Missing depedencies: $PKGSTOINSTALL"
	echo -n "Some dependencies are missing. Want to install them? (Y/n): "
	read SURE
	# If user want to install missing dependencies
	if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" ]]; then
		# Debian, Ubuntu and derivatives (with apt-get)
		if which apt-get &> /dev/null; then
			apt-get install $PKGSTOINSTALL
		# OpenSuse (with zypper)
		elif which zypper &> /dev/null; then
			zypper in $PKGSTOINSTALL
		# Mandriva (with urpmi)
		elif which urpmi &> /dev/null; then
			urpmi $PKGSTOINSTALL
		# Fedora and CentOS (with yum)
		elif which yum &> /dev/null; then
			yum install $PKGSTOINSTALL
		# ArchLinux (with pacman)
		elif which pacman &> /dev/null; then
			pacman -Sy $PKGSTOINSTALL
		# Else, if no package manager has been founded
		else
			# Set $NOPKGMANAGER
			NOPKGMANAGER=TRUE
			echo "ERROR: impossible to found a package manager in your sistem. Please, install manually ${PKGSTOINSTALL}."
		fi
		# Check if installation is successful
		if [[ $? -eq 0 && ! -z $NOPKGMANAGER ]] ; then
			echo "All dependencies are satisfied."
		# Else, if installation isn't successful
		else
			echo "ERROR: impossible to install some missing dependencies. Please, install manually ${PKGSTOINSTALL}."
		fi
	# Else, if user don't want to install missing dependencies
	else
		echo "WARNING: Some dependencies may be missing. So, please, install manually ${PKGSTOINSTALL}."
	fi
fi
