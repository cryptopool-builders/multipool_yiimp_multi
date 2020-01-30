#!/usr/bin/env bash

#####################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh # load our functions
source /etc/multipool.conf

# Ensure Python reads/writes files in UTF-8. If the machine
# triggers some other locale in Python, like ASCII encoding,
# Python may not be able to read/write files. This is also
# in the management daemon startup script and the cron script.

if ! locale -a | grep en_US.utf8 > /dev/null; then
# Generate locale if not exists
hide_output locale-gen en_US.UTF-8
fi

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
export NCURSES_NO_UTF8_ACS=1

echo Creating the temporary YiiMP installation folder...
if [ ! -d $STORAGE_ROOT/yiimp/yiimp_setup ]; then
sudo mkdir -p $STORAGE_ROOT/yiimp/yiimp_setup
fi
# Start the installation.
source warning.sh
source menu.sh
cd ~
clear
echo Installation of your YiiMP multi server is now completed.
echo You *MUST* reboot this machine to finalize the system updates and folder permissions! YiiMP will not function until a reboot is performed!
echo
echo "Now that installation in completed, all further actions will be done on your web server"
echo
echo "Important! After first reboot it may take up to 1 minute for the main|loop2|blocks|debug screens to start!"
echo "After 1 minute, type motd to refresh"
echo
echo You can access your admin panel at, http://${DomainName}/site/${AdminPanel}
echo
echo By default all stratum ports are blocked by the firewall. To allow a port through, from the command prompt type sudo ufw allow port number.
echo Database user names and passwords can be found in $STORAGE_ROOT/yiimp_setup/.my.cnf
echo "-----------------------------------------------"
echo
echo Thank you for using the Ultimate Crypto-Server Setup Installer!
echo
echo To run this installer anytime simply type, multipool!
echo Donations for continued support of this script are welcomed at:
echo
echo BTC 3DvcaPT3Kio8Hgyw4ZA9y1feNnKZjH7Y21
echo BCH qrf2fhk2pfka5k649826z4683tuqehaq2sc65nfz3e
echo ETH 0x6A047e5410f433FDBF32D7fb118B6246E3b7C136
echo LTC MLS5pfgb7QMqBm3pmBvuJ7eRCRgwLV25Nz
exit 0
