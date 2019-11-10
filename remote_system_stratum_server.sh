#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################
source /etc/functions.sh
source /etc/multipool.conf
echo "Starting Remote Stratum Server Build..."
if [[ ! -e '$STORAGE_ROOT/yiimp/' ]]; then
sudo mkdir -p $STORAGE_ROOT/yiimp/
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
else
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
fi

# Set timezone
echo Setting TimeZone to UTC...
if [ ! -f /etc/timezone ]; then
echo "Setting timezone to UTC."
echo "Etc/UTC" > sudo /etc/timezone
restart_service rsyslog
fi

# Add repository
echo Adding the required repsoitories...
if [ ! -f /usr/bin/add-apt-repository ]; then
echo "Installing add-apt-repository..."
hide_output sudo apt-get -y update;
apt_install software-properties-common;
fi

# MariaDB
echo Installing MariaDB Repository...
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
if [[ ("$DISTRO" == "16") ]]; then
sudo add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://mirror.timeweb.ru/mariadb/repo/10.4/ubuntu xenial main'
else
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.timeweb.ru/mariadb/repo/10.4/ubuntu bionic main'
fi
wait $!

# Upgrade System Files
echo Updating system packages...
hide_output sudo apt-get update;
wait $!

echo Upgrading system packages...
if [ ! -f /boot/grub/menu.lst ]; then
apt_get_quiet upgrade;
wait $!

else
sudo rm /boot/grub/menu.lst
hide_output sudo update-grub-legacy-ec2 -y;
wait $!

apt_get_quiet upgrade;
wait $!
fi

echo Running Dist-Upgrade...
apt_get_quiet dist-upgrade;
wait $!

echo Running Autoremove...
apt_get_quiet autoremove;
wait $!

echo Installing Base system packages...
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip \
unattended-upgrades cron ntp fail2ban screen;
wait $!

# ### Seed /dev/urandom
echo Initializing system random number generator...
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r

echo Installing YiiMP Required system packages...
if [ -f /usr/sbin/apache2 ]; then
echo Removing apache...
hide_output apt-get -y purge apache2 apache2-*;
wait $!

hide_output apt-get -y --purge autoremove;
wait $!
fi

hide_output sudo apt-get update;
wait $!

if [[ ("$DISTRO" == "16") ]]; then
apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev \
libldap2-dev libidn11-dev gnutls-dev librtmp-dev build-essential libtool  \
autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libssl-dev \
git pwgen mariadb-client fail2ban;
wait $!
else
apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev \
libldap2-dev libidn11-dev gnutls-dev librtmp-dev build-essential libtool  \
autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libssl-dev \
git pwgen mariadb-client fail2ban libpsl-dev libnghttp2-dev;
wait $!
fi
echo Downloading selected YiiMP Repo...
hide_output sudo git clone $YiiMPRepo $STORAGE_ROOT/yiimp/yiimp_setup/yiimp;
if [[ ("$CoinPort" == "y" || "$CoinPort" == "Y" || "$CoinPort" == "yes" || "$CoinPort" == "Yes" || "$CoinPort" == "YES") ]]; then
	cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
	sudo git fetch
	sudo git checkout multi-port
fi

exit 0
