#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

install_packages(){
  echo; echo "[Install packages]"
  INSTALLED=0
  for PACKAGE in podman; do
    if [ `rpm -qa | egrep -c "^${PACKAGE}-"` = "0" ]; then
      echo "  - Installing $PACKAGE"
      sudo rpm-ostree install $PACKAGE
      INSTALLED=$((INSTALLED+1))
    fi
  done
  if [ "$INSTALLED" = "0" ]; then
    echo "  - No package to install"
  else
    echo "  - Rebooting"
    sudo reboot
  fi
}

install_packages
