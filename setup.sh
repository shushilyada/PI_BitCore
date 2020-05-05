#!/bin/bash

if [[ $EUID -ne 0 ]]; then

	echo "This script must be run as root" 1>&2

else

COIN="BitCore"
SETUP="[A-Z]" "[a-z]"
OS=$(cat /etc/os-release | grep ID=raspbian)
GIT_URL="https://github.com/SpecTurrican/PI_${COIN}"
INSTALL_DIR="/root/PI_${COIN}/"
INSTALL_FILE="${INSTALL_DIR}${SETUP}_setup/install_${SETUP}.sh"
LOG_DIR="${INSTALL_DIR}logfiles/"
LOG_FILE="start.log"

apt-get -y install git

	if [ -n "$OS" ]; then

		cd /root/
		git clone ${GIT_URL}
		chmod 744 -R ${INSTALL_DIR}
		mkdir ${LOG_DIR}
		nohup ${INSTALL_FILE} >${LOG_DIR}${LOG_FILE} 2>&1 &
		clear
		tail -f ${LOG_DIR}${LOG_FILE}

	else

		echo "This script running only below raspian ... sorry !!!"
		echo " "
		echo "Visit https://www.raspberrypi.org/downloads/raspbian/ "

	fi

fi