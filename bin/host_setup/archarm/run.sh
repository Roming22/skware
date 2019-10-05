#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`
set -e

# Install packages
install_packages(){
  echo; echo "[Installing packages]"
	INSTALLED="0"
	for PACKAGE in docker; do
		if [[ `pacman -Q | egrep -c "^$PACKAGE "` = "0" ]]; then
			echo "  - Installing $PACKAGE ..."
			sudo pacman -S --noconfirm $PACKAGE
			INSTALLED=$((INSTALLED +1))
		fi
	done
	if [[ "$INSTALLED" = "0" ]]; then
		echo "  - No package to install"
	fi
}

install_packages
