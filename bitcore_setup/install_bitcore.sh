#!/bin/bash

# BASICS
SCRIPT_VERSION="18052020"
COIN_NAME="BitCore"
COIN=$(echo ${COIN_NAME} | tr '[:upper:]' '[:lower:]')
COIN_PORT="8555"
COIN_RPCPORT="8556"
COIN_DOWNLOAD="https://github.com/LIMXTEC/${COIN_NAME}"
COIN_BLOCKCHAIN_VERSION="z_bootstrap"
COIN_BLOCKCHAIN="https://github.com/LIMXTEC/${COIN_NAME}/releases/download/0.90.9.1/${COIN_BLOCKCHAIN_VERSION}.zip"
COIND="/usr/local/bin/${COIN}d"
COIN_CLI="/usr/local/bin/${COIN}-cli"
COIN_BLOCKEXPLORER="https://chainz.cryptoid.info/btx/api.dws?q=getblockcount"
COIN_NODE="https://chainz.cryptoid.info/btx/api.dws?q=nodes"

# DIRS
ROOT="/root/"
HOME="/home/${COIN}/"
COIN_ROOT="${ROOT}.${COIN}"
COIN_HOME="${HOME}.${COIN}"
INSTALL_DIR="${ROOT}PI_${COIN_NAME}/"
COIN_INSTALL="${ROOT}${COIN}"
BDB_PREFIX="${COIN_INSTALL}/db4"

# DB
DB_VERSION="4.8.30"
DB_FILE="db-${DB_VERSION}.NC.tar.gz"
DB_DOWNLOAD="http://download.oracle.com/berkeley-db/${DB_FILE}"

# LIBRARIES and DEV_TOOLS
LIBRARIES="libssl1.0-dev libboost-all-dev libevent-dev libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 libqrencode-dev libprotobuf-dev"
DEV_TOOLS="build-essential libtool autotools-dev autoconf cmake pkg-config bsdmainutils git jq unzip fail2ban ufw python3 pkg-config autotools-dev qttools5-dev qttools5-dev-tools protobuf-compiler"

# Wallet RPC user and password
rrpcuser="${COIN}pi$(shuf -i 100000000-199999999 -n 1)"
rrpcpassword="$(shuf -i 1000000000-3999999999 -n 1)$(shuf -i 1000000000-3999999999 -n 1)$(shuf -i 1000000000-3999999999 -n 1)"

# User for System
ssuser="${COIN}"
sspassword="${COIN}"

# Install Script
SCRIPT_DIR="${INSTALL_DIR}${COIN}_setup/"
SCRIPT_NAME="install_${COIN}.sh"

# Logfile
LOG_DIR="${INSTALL_DIR}logfiles/"
LOG_FILE="make.log"

# System Settings
checkForRaspbian=$(cat /proc/cpuinfo | grep 'Revision')
CPU_CORE=$(cat /proc/cpuinfo | grep processor | wc -l)
RPI_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')


start () {

	#
	# Welcome

	echo "*** Welcome to the ${COIN_NAME} World ***"
	echo ""
	echo ""
	echo "Please wait... now configuration the system!"

	# Put here for startup config
	/usr/bin/touch /boot/ssh
	sleep 5


}


app_install () {

	#
	# Install Tools

	apt-get update && apt-get upgrade -y
	apt-get install -y ${LIBRARIES} ${DEV_TOOLS}


}


manage_swap () {

	# On a Raspberry Pi, the default swap is 100MB. This is a little restrictive, so we are
	# expanding it to a full 2GB of swap. or disable when RPI4 4GB Version

	if [ "RPI_RAM" < "3072" ]; then
	sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
	fi
	if [ "RPI_RAM" > "3072" ]; then
	swap_off
	fi


}


reduce_gpu_mem () {

	#
	# On the Pi, the default amount of gpu memory is set to be used with the GUI build. Instead
	# we are going to set the amount of gpu memmory to a minimum due to the use of the Command
	# Line Interface (CLI) that we are using in this build. This means we don't have a GUI here,
	# we only use the CLI. So no need to allocate GPU ram to something that isn't being used. Let's
	# assign the param below to the minimum value in the /boot/config.txt file.

	if [ ! -z "$checkForRaspbian" ]; then

		# First, lets not assume that an entry doesn't already exist, so let's purge and preexisting
		# gpu_mem variables from the respective file.

		sed -i '/gpu_mem/d' /boot/config.txt

		# Now, let's append the variable and value to the end of the file.

		echo "gpu_mem=16" >> /boot/config.txt

		echo "GPU memory was reduced to 16MB on reboot."

	fi


}


disable_bluetooth () {

	if [ ! -z "$checkForRaspbian" ]; then

		# First, lets not assume that an entry doesn't already exist, so let's purge any preexisting
		# bluetooth variables from the respective file.

		sed -i '/disable-bt/d' /boot/config.txt

		# Now, let's append the variable and value to the end of the file.

		echo "dtoverlay=disable-bt" >> /boot/config.txt

		# Next, we remove the bluetooth package that was previously installed.

		apt-get remove pi-bluetooth -y

		echo "Bluetooth was uninstalled."

	fi


}


set_network () {

	ipaddr=$(ip route get 1 | awk '{print $NF;exit}')

	hhostname="$(COIN)$(shuf -i 100000000-999999999 -n 1)"

	echo $hhostname > /etc/hostname && hostname -F /etc/hostname

	echo $ipaddr $hhostname >> /etc/hosts

	echo "Your Hostname is now : ${hhostname} "


}


set_accounts () {

	#
	# We don't always know the condition of the host OS, so let's look for several possibilities.
	# This will disable the ability to log in directly as root.

	sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

	sed -i 's/PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config

	# Set the new username and password

	adduser $ssuser --disabled-password --gecos ""

	echo "$ssuser:$sspassword" | chpasswd

	adduser $ssuser sudo

	# We only need to lock the Pi account if this is a Raspberry Pi. Otherwise, ignore this step.

	if [ ! -z "$checkForRaspbian" ]; then

		# Let's lock the pi user account, no need to delete it.

		usermod -L -e 1 pi

		echo "The 'pi' login was locked. Please log in with '$ssuser'. The password is '$sspassword'."

		sleep 5

	fi


}


prepair_system () {

	#
	# prepair the installation

	apt-get autoremove -y
	cd ${ROOT}
	git clone $COIN_DOWNLOAD $COIN_INSTALL && mkdir $BDB_PREFIX
	wget $DB_DOWNLOAD
	tar -xzvf $DB_FILE && rm $DB_FILE
	mkdir $COIN_ROOT
	wget $COIN_BLOCKCHAIN
	unzip ${COIN_BLOCKCHAIN_VERSION}.zip -d $COIN_ROOT && rm ${COIN_BLOCKCHAIN_VERSION}.zip
	chown -R root:root ${COIN_ROOT}


}


prepair_crontab () {

	#
	# prepair crontab for restart

	/usr/bin/crontab -u root -r
	/usr/bin/crontab -u root -l | { cat; echo "@reboot		${SCRIPT_DIR}${SCRIPT_NAME} >${LOG_DIR}${LOG_FILE} 2>&1"; } | crontab -


}


restart_pi () {

	#
	# restart the system

	/usr/bin/touch /boot/${COIN}setup
	echo "SCRIPTVERSION=${SCRIPT_VERSION}" >> /boot/${COIN}setup

	echo "restarting the system... "
	echo " "
	echo "!!!!!!!!!!!!!!!!!"
	echo "!!! New login !!!"
	echo "!!!!!!!!!!!!!!!!!"
	echo "User: ${ssuser}  Password: ${sspassword}"
	echo " "
	echo " "

	sleep 30

	/sbin/reboot

}


make_db () {

	#
	# make Berkeley DB

	cd ${ROOT}/db-${DB_VERSION}.NC/build_unix/
	../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BDB_PREFIX}
	if [ "$CPU_CORE" = "4" ]; then
		make -j3 && make install
	else
		make && make install
	fi


}


make_coin () {

	#
	# make the wallet (with qt)

	cd $COIN_INSTALL
	./autogen.sh
	./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" --disable-tests --disable-gui-tests --disable-bench --without-miniupnpc
	#
	# Set for RPI4 4GB Version 
	if [ "RPI_RAM" > "3072" ]; then
		make -j3 && make install
	else
	#
	# Set for RPI4 2GB Version
		make -j2 && make install
	fi


}


configure_coin_conf () {

	#
	# Set the coin config file .conf

	COIN_EXTERNALIP=$(curl -s icanhazip.com)

	echo "

	rpcuser=${rrpcuser}
	rpcpassword=${rrpcpassword}
	rpcallowip=127.0.0.1
	port=${COIN_PORT}
	rpcport=${COIN_RPCPORT}
	server=1
	listen=1
	daemon=1
	maxconnections=64
	logtimestamps=1
	txindex=1
	externalip=${COIN_EXTERNALIP}:${COIN_PORT}
	masternodeaddr=127.0.0.1:${COIN_PORT}
	masternode=0
	#masternodeprivkey=

	#############
	# NODE LIST #
	#############" > ${COIN_ROOT}/${COIN}.conf

	COIN_NODES=$(curl -s $COIN_NODE | jq '.[] | .nodes[]' |  /bin/sed 's/"//g')

		for addnode in $COIN_NODES; do
		echo "	addnode=$addnode" >> ${COIN_ROOT}/${COIN}.conf
		done


}


config_ufw () {

	#
	# Setup for Firewall UFW
	# The default port is COIN_PORT

	/usr/sbin/ufw logging on
	/usr/sbin/ufw allow 22/tcp
	/usr/sbin/ufw limit 22/tcp
	# COIN_PORT
	/usr/sbin/ufw allow ${COIN_PORT}/tcp
	# RDP Port
	/usr/sbin/ufw allow 3389
	/usr/sbin/ufw default deny incoming
	/usr/sbin/ufw default allow outgoing
	yes | /usr/sbin/ufw enable


}


config_fail2ban () {

	#
	# The default ban time for users on port 22 (SSH) is 10 minutes. Lets make this a full 24
	# hours that we will ban the IP address of the attacker. This is the tuning of the fail2ban
	# jail that was documented earlier in this file. The number 86400 is the number of seconds in
	# a 24 hour term.


	echo "

	[sshd]
	enabled	= true
	bantime = 86400
	banaction = ufw

	[sshd-ddos]
	enabled = true
	bantime = 86400
	banaction = ufw

	" > /etc/fail2ban/jail.d/defaults-debian.conf

	# Configure the fail2ban jail and set the frequency to 20 min and 3 polls.

	echo "

	#
	# SSH
	#

	[sshd]
	port		= ssh
	logpath		= %(sshd_log)s
	maxretry = 3
	" > /etc/fail2ban/jail.local

	fail2ban-client reload


}


swap_off () {

	#
	# swap off/disable for safe your SD-Card

	IS_SWAPON=$(/sbin/swapon)
	if [ $IS_SWAPON ]; then
	/sbin/swapoff -a
	/usr/sbin/service dphys-swapfile stop
	/bin/systemctl disable dphys-swapfile
	fi


}


configure_service () {

	#
	# Set systemctl

	echo "

	[Unit]
	Description=${COIN_NAME} Service
	After=network.target
	[Service]
	User=root
	Group=root
	Type=forking
	ExecStart=${COIND} -daemon -conf=${COIN_ROOT}/${COIN}.conf -datadir=${COIN_ROOT} -walletdir=${COIN_ROOT}
	ExecStop=${COIN_CLI} -conf=${COIN_ROOT}/${COIN}.conf -datadir=${COIN_ROOT} stop 
	Restart=always
	PrivateTmp=true
	TimeoutStopSec=90s
	TimeoutStartSec=90s
	StartLimitInterval=180s
	StartLimitBurst=15
	[Install]
	WantedBy=multi-user.target

	" > /etc/systemd/system/${COIN}.service

	/bin/systemctl daemon-reload
	sleep 5
	/bin/systemctl start ${COIN}.service
	/bin/systemctl enable ${COIN}.service >/dev/null 2>&1


}


checkrunning () {

	#
	# Is the service running ?

	echo " ... waiting of ${COIN}.service ... please wait!..."
	sleep 5
	while ! ${COIN_CLI} -conf=${COIN_ROOT}/${COIN}.conf -datadir=${COIN_ROOT} -getinfo >/dev/null 2>&1; do
		sleep 5
		error=$(${COIN_CLI} -conf=${COIN_ROOT}/${COIN}.conf -datadir=${COIN_ROOT} -getinfo 2>&1 | cut -d: -f4 | tr -d "}")
		echo " ... ${COIN}.service is on : $error"
		sleep 2
	done

	echo "${COIN}.service is running !"


}


watch_synch () {

	#
	# Watch synching the blockchain

	sleep 5

	set_blockhigh=$(curl -s ${COIN_BLOCKEXPLORER})
	echo "  The current blockhigh is now : ${set_blockhigh} ..."
	echo "  -----------------------------------------"

	while true; do

	set_blockhigh=$(curl -s ${COIN_BLOCKEXPLORER})
	get_blockhigh=$(${COIN_CLI} getblockcount)

	if [ "$get_blockhigh" -lt "$set_blockhigh" ]
	then
		echo "  ... This may take a long time please wait!..."
		echo "    Block is now: $get_blockhigh / $set_blockhigh"
		sleep 10
	else
		echo "      Complete!..."
		echo "    Block is now: $get_blockhigh / $set_blockhigh"
		echo " "
		sleep 30
		break
	fi
	done


}


masternode_on () {

	#
	# We now activation the masternode and generating a masternode key

	COIN_MN_KEY=$(${COIN_CLI} masternode genkey)

	sed -i 's/masternode=0/masternode=1/' ${COIN_ROOT}/${COIN}.conf
	sed -i ''s/#masternodeprivkey=/masternodeprivkey=$COIN_MN_KEY/'' ${COIN_ROOT}/${COIN}.conf


}


finish () {

	#
	# We now write this empty file to the /boot dir. This file will persist after reboot so if
	# this script were to run again, it would abort because it would know it already ran sometime
	# in the past. This is another way to prevent a loop if something bad happens during the install
	# process. At least it will fail and the machine won't be looping a reboot/install over and
	# over. This helps if we have ot debug a problem in the future.

	/usr/bin/touch /boot/ssh
	/usr/bin/touch /boot/${COIN}service

	/usr/bin/crontab -u root -r

	#
	# Move Blockchain to User
	/bin/mv ${COIN_ROOT} ${HOME}
	cp /root/PI_${COIN_NAME}/${COIN}_setup/*.jpg ${COIN_HOME}
	/bin/chown -R -f ${COIN}:${COIN} ${COIN_HOME}
	/bin/chmod 770 ${COIN_HOME} -R

	#
	# Install Raspian Desktop
	# https://www.raspberrypi.org/forums/viewtopic.php?f=66&t=133691

	apt-get install --no-install-recommends xserver-xorg -y
	apt-get install raspberrypi-ui-mods -y
	apt-get install chromium-browser -y 
	apt-get install xrdp -y

	chage -d 0 ${ssuser}

	echo " "
	echo "${COIN} is installed. Thanks for your support :-)"
	echo " "
	echo " "
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!! Please change the password !!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo " "
	echo "User: ${ssuser}  Password: ${sspassword}"
	echo "Masternode IP: ${COIN_EXTERNALIP}:${COIN_PORT}"
	echo "Masternode Key: ${COIN_MN_KEY}"
	echo " "
	echo " "
	echo "reboot in 60 sec... "

	#
	# Disable the service for running the QT Version :-)
	systemctl stop ${COIN}.service
	systemctl disable ${COIN}.service
	#
	# Prepare the service for consoles
	sed -i ''s/User=root/User=${COIN}/'' /etc/systemd/system/${COIN}.service
	sed -i ''s/Group=root/Group=${COIN}/'' /etc/systemd/system/${COIN}.service
	sed -i ''s#$COIN_ROOT#$COIN_HOME#g'' /etc/systemd/system/${COIN}.service
	#
	# Set the GPU Mem for GUI (The default is 64 MB but we have enough memory)
	sed -i 's/gpu_mem=16/gpu_mem=256/' /boot/config.txt
	# Set HDMI Mode
	echo "hdmi_enable_4kp60=1" >> /boot/config.txt
	sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/' /boot/config.txt
	sed -i 's/dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/' /boot/config.txt
	# Set resolution to 1080p 60Hz
	sed -i 's/#hdmi_group=1/hdmi_group=2/' /boot/config.txt
	sed -i 's/#hdmi_mode=1/hdmi_mode=82/' /boot/config.txt
	# Set Boot in to GUI with Login
	#sed -i 's/$/ quiet splash plymouth.ignore-serial-consoles/' /boot/cmdline.txt

	# Set Desktop Application
	cp /root/PI_${COIN_NAME}/${COIN}_setup/${COIN}_icon.png ${COIN_HOME}

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
	" > ${HOME}.local/share/applications/{COIN}-qt.desktop
	cp ${HOME}.local/share/applications/{COIN}-qt.desktop ${HOME}Desktop/
	/bin/chown -f ${COIN}:${COIN} ${HOME}.local/share/applications/${COIN}-qt.desktop
	/bin/chmod 770 ${HOME}.local/share/applications/${COIN}-qt.desktop

	# Set Desktop Wallpaper
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
	/bin/chown -f ${COIN}:${COIN} ${HOME}.config/pcmanfm/LXDE-pi/desktop-items-0.conf
	/bin/chmod 770 ${HOME}.config/pcmanfm/LXDE-pi/desktop-items-0.conf

	sleep 60s

	/sbin/reboot


}


	#
	# Is the service installed ?

if [ -f /boot/${COIN}service ]; then

	echo "Previous ${COIN_NAME} detected. Install aborted."

else

	if [ -f /boot/${COIN}setup ]; then

		make_db
		make_coin
		configure_coin_conf
		config_ufw
		config_fail2ban
		swap_off
		configure_service
		checkrunning
		watch_synch
		masternode_on
		finish

	else

	echo "Starting installation now..."
	sleep 3
	clear

	start
	app_install
	manage_swap
	reduce_gpu_mem
	disable_bluetooth
	set_network
	set_accounts
	prepair_system
	prepair_crontab
	restart_pi

	fi

fi
