#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################
source /etc/functions.sh
source /etc/multipool.conf

echo -e " Building stratum server...$COL_RESET"

if [[ ! -e '$STORAGE_ROOT/yiimp/' ]]; then
sudo mkdir -p $STORAGE_ROOT/yiimp/
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
else
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
fi

# Set timezone
echo -e " Setting TimeZone to UTC...$COL_RESET"
if [ ! -f /etc/timezone ]; then
echo "Setting timezone to UTC."
echo "Etc/UTC" > sudo /etc/timezone
restart_service rsyslog
fi

# Add repository
echo -e " Adding the required repsoitories...$COL_RESET"
if [ ! -f /usr/bin/add-apt-repository ]; then
echo "Installing add-apt-repository..."
hide_output sudo apt-get -y update;
apt_install software-properties-common;
fi

# MariaDB
echo -e " Installing MariaDB Repository...$COL_RESET"
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
if [[ ("$DISTRO" == "16") ]]; then
  sudo add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://mirror.one.com/mariadb/repo/10.4/ubuntu xenial main' >/dev/null 2>&1;
else
  sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.one.com/mariadb/repo/10.4/ubuntu bionic main' >/dev/null 2>&1;
fi
wait $!

# Upgrade System Files
echo -e " Updating system packages...$COL_RESET"
hide_output sudo apt-get update;
wait $!

echo -e " Upgrading system packages...$COL_RESET"
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

echo -e " Running Dist-Upgrade...$COL_RESET"
apt_get_quiet dist-upgrade;
wait $!

echo -e " Running Autoremove...$COL_RESET"
apt_get_quiet autoremove;
wait $!

echo -e " Installing Base system packages...$COL_RESET"
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip \
unattended-upgrades cron ntp fail2ban screen;
wait $!

# ### Seed /dev/urandom
echo -e " Initializing system random number generator...$COL_RESET"
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r

echo -e " Installing YiiMP Required system packages...$COL_RESET"
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
autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils \
git pwgen mariadb-client fail2ban gnupg2 ca-certificates lsb-release libsodium-dev \
libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev;
wait $!
else
apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev \
libldap2-dev libidn11-dev gnutls-dev librtmp-dev build-essential libtool  \
autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils \
git pwgen mariadb-client fail2ban libpsl-dev libnghttp2-dev gnupg2 ca-certificates lsb-release libsodium-dev \
libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev;
wait $!
fi
echo -e " Downloading CryptoPool.builders YiiMP Repo...$COL_RESET"
hide_output sudo git clone $YiiMPRepo $STORAGE_ROOT/yiimp/yiimp_setup/yiimp;
wait $!
if [[ ("$CoinPort" == "y" || "$CoinPort" == "Y" || "$CoinPort" == "yes" || "$CoinPort" == "Yes" || "$CoinPort" == "YES") ]]; then
	cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
	sudo git fetch
	sudo git checkout multi-port
  wait $!
fi
echo -e "$GREEN Stratum server build completed...$COL_RESET"
exit 0
