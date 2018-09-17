#!/bin/bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

echo "Starting Remote Stratum Server Build..."
clear
source /etc/functions.sh
source /etc/multipool.conf
if [[ ! -e '$STORAGE_ROOT/yiimp/' ]]; then
sudo mkdir -p $STORAGE_ROOT/yiimp/
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
else
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
fi
# Check swap
echo Checking if swap space is needed and if so creating...
SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)
if
[ -z "$SWAP_MOUNTED" ] &&
[ -z "$SWAP_IN_FSTAB" ] &&
[ ! -e /swapfile ] &&
[ -z "$ROOT_IS_BTRFS" ] &&
[ $TOTAL_PHYSICAL_MEM -lt 1900000 ] &&
[ $AVAILABLE_DISK_SPACE -gt 5242880 ]
then
echo "Adding a swap file to the system..."

# Allocate and activate the swap file. Allocate in 1KB chuncks
# doing it in one go, could fail on low memory systems
dd if=/dev/zero of=/swapfile bs=1024 count=$[1024*1024] status=none
if [ -e /swapfile ]; then
chmod 600 /swapfile
hide_output mkswap /swapfile
swapon /swapfile
fi

# Check if swap is mounted then activate on boot
if swapon -s | grep -q "\/swapfile"; then
echo "/swapfile  none swap sw 0  0" >> /etc/fstab
else
echo "ERROR: Swap allocation failed"
fi
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
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.evowise.com/mariadb/repo/10.3/ubuntu xenial main';

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

apt_install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev \
libldap2-dev libidn11-dev gnutls-dev librtmp-dev build-essential libtool  \
autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils \
git pwgen mariadb-client fail2ban;
wait $!

echo Downloading selected YiiMP Repo...
hide_output sudo git clone $YiiMPRepo $STORAGE_ROOT/yiimp/yiimp_setup/yiimp;

exit 0
