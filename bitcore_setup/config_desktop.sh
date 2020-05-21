#!/bin/bash

# BASICS
SCRIPT_VERSION="18052020"
COIN_NAME="BitCore"
COIN=$(echo ${COIN_NAME} | tr '[:upper:]' '[:lower:]')
COIND="/usr/local/bin/${COIN}d"
COIN_CLI="/usr/local/bin/${COIN}-cli"
COIN_BLOCKEXPLORER="https://chainz.cryptoid.info/btx/api.dws?q=getblockcount"
COIN_NODE="https://chainz.cryptoid.info/btx/api.dws?q=nodes"

# DIRS
HOME="/home/${COIN}/"
COIN_HOME="${HOME}.${COIN}"
INSTALL_DIR="${ROOT}PI_${COIN_NAME}/"

# User for System
ssuser="${COIN}"
sspassword="${COIN}"

# Install Script
SCRIPT_DIR="${INSTALL_DIR}${COIN}_setup/"
SCRIPT_NAME="install_${COIN}.sh"

# Logfile
LOG_DIR="${INSTALL_DIR}logfiles/"
LOG_FILE="config_desktop.log"

# System Settings
checkForRaspbian=$(cat /proc/cpuinfo | grep 'Revision')
CPU_CORE=$(cat /proc/cpuinfo | grep processor | wc -l)
RPI_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Commands
COIN_CLI_COMMAND="${COIN_CLI} -conf=${COIN_ROOT}/${COIN}.conf -datadir=${COIN_ROOT}"

#
# Copy Wallpaper and Icons for Desktop
cp /root/PI_${COIN_NAME}/${COIN}_setup/*.jpg ${COIN_HOME}
cp /root/PI_${COIN_NAME}/${COIN}_setup/${COIN}_icon.png ${COIN_HOME}
  
# Set Desktop Application

#/bin/mkdir -p ${HOME}.local/share/applications
#/bin/mkdir -p ${HOME}Desktop

  echo "
    [Desktop Entry]
    Name=${COIN_NAME} QT
    Comment=Blockchain Wallet from ${COIN_NAME}
    Exec=${COIN}-qt
    Icon=/home/${COIN}/.${COIN}/${COIN}_icon.png
    Terminal=false
    Type=Application
    Categories=Blockchain;
    Keywords=blockchain;wallet;${COIN};
  " > ${HOME}.local/share/applications/${COIN}-qt.desktop
cp ${HOME}.local/share/applications/${COIN}-qt.desktop ${HOME}Desktop/

#
# Set Desktop Wallpaper
/bin/mkdir -p ${HOME}.config/pcmanfm/LXDE-pi
	echo "
	  [*]
	  desktop_bg=#000000000000
	  desktop_shadow=#000000000000
	  desktop_fg=#d2d22e2eabab
	  desktop_font=Monospace 12
	  wallpaper=${COIN_HOME}/${COIN}_wallpaper.jpg
	  wallpaper_mode=fit
	  show_documents=0
	  show_trash=1
	  show_mounts=1
	" > ${HOME}.config/pcmanfm/LXDE-pi/desktop-items-0.conf

