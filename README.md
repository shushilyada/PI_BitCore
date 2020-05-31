# PI_BitCore
## BitCore for Raspberry Pi 4 (2GB / 4GB or 8GB RAM Version only) with Desktop RPD and remonte SSH/RDP control.

Needs:

+ ISO Raspbian Lite (https://www.raspberrypi.org/downloads/raspbian/)
+ Login as ROOT (start Raspberry Pi and login as 'pi' user... password is 'raspberry'... 'sudo su root')

You can execute the following install script. Just copy/paste and hit return.
```
wget -qO - https://raw.githubusercontent.com/SpecTurrican/PI_BitCore/master/setup.sh | bash
```
The installation goes into the background. You can follow the installation with :
```
sudo tail -f /root/PI_BitCore/logfiles/start.log  # 1. Phase "Prepar the system"

or

sudo tail -f /root/PI_BitCore/logfiles/make.log   # 2. Phase "Compiling"
```
The installation takes about 3 hours.
The Raspberry Pi is restarted 2 times during the installation.
After the installation the following user and password is valid :
```
bitcore
```
Please change your password !!!

You can with RDP (on Windows "mstsc") or via HDMI start the BitCore QT on the Desktop.

In the File "info.txt" on your Desktop is the Masternode Key and External IP.

You need only the console ?

Start the service with:
```
sudo systemctl enable bitcore.service
```

If everything worked out, you can retrieve the status with the following command :
```
bitcore-cli -getinfo             # general information
bitcore-cli masternode status   # is the masternode running ?
bitcore-cli masternode count    # how much mastenode ?
bitcore-cli mnsync status       # returns the sync status
bitcore-cli help                # list of commands
```
## Configfile
The configfile for bitcore is stored in:
```
/home/bitcore/.bitcore/bitcore.conf
```
Settings during installation:
```
rpcuser=bitcorepixxxxxxxxx                 # x=random
rpcpassword=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # x=random
rpcallowip=127.0.0.1
port=8555
rpcport=8560
server=1
listen=1
daemon=1
maxconnections=64
logtimestamps=1
txindex=1
externalip="Your IPv4 adress":8555
masternodeaddr=127.0.0.1:8555
masternode=1
masternodeprivkey="Your Masternode Key"

#############
# NODE LIST #
#############
addnode=add a node from https://chainz.cryptoid.info/btx/api.dws?q=nodes list
...
```
## Security
- You have a Firewall or Router ? Please open the Port 8555 for your raspberry pi. Thanks!
- fail2ban is configured with 24 hours banntime. (https://www.fail2ban.org/wiki/index.php/Main_Page)
- ufw service open ports is 22 (SSH), 3389 (RDP) and 8555 (BitCore). (https://help.ubuntu.com/community/UFW)
## Infos about BitCore
[Homepage](https://bitcore.cc/) | [Source GitHub](https://github.com/LIMXTEC/BitCore) | [Blockchainexplorer](https://chainz.cryptoid.info/btx/) | [Telegram](https://t.me/bitcore_cc) | [bitcointalk.org](https://bitcointalk.org/index.php?topic=1883902.0)

## Have fun and thanks for your support :-)
BTX donate to :
```
2Q79SCjani8SKKarSrh5Dk4CXPfcYbDknU
```
