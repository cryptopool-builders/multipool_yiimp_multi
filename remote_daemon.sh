#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

echo -e " Building daemon server...$COL_RESET"

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
wait $!

echo -e " Installing BitCoin PPA...$COL_RESET"
if [ ! -f /etc/apt/sources.list.d/bitcoin.list ]; then
  hide_output sudo add-apt-repository -y ppa:bitcoin/bitcoin
fi

echo -e " Installing additional system files required for daemons...$COL_RESET"
hide_output sudo apt-get update;
wait $!
apt_install build-essential libtool autotools-dev \
automake pkg-config libssl-dev libevent-dev bsdmainutils git libboost-all-dev libminiupnpc-dev \
libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev \
protobuf-compiler libqrencode-dev libzmq3-dev libgmp-dev \
python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip mariadb-client \
unattended-upgrades cron ntp fail2ban screen automake cmake libpsl-dev libnghttp2-dev gnupg2 ca-certificates lsb-release;
wait $!

sudo mkdir -p $STORAGE_ROOT/yiimp/yiimp_setup/tmp
cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp

echo -e " Building Berkeley 4.8, this may take several minutes...$COL_RESET"
  sudo mkdir -p $STORAGE_ROOT/berkeley/db4/;
  hide_output sudo wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz';
  wait $!
  hide_output sudo tar -xzvf db-4.8.30.NC.tar.gz;
  wait $!
  cd db-4.8.30.NC/build_unix/
  hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$STORAGE_ROOT/berkeley/db4/;
  wait $!
  hide_output sudo make install;
  wait $!
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp;
  sudo rm -r db-4.8.30.NC.tar.gz db-4.8.30.NC;
echo -e "$GREEN Berkeley 4.8 Completed...$COL_RESET"

echo -e " Building Berkeley 5.1, this may take several minutes...$COL_RESET"
  sudo mkdir -p $STORAGE_ROOT/berkeley/db5/;
  hide_output sudo wget 'http://download.oracle.com/berkeley-db/db-5.1.29.tar.gz';
  wait $!
  hide_output sudo tar -xzvf db-5.1.29.tar.gz;
  wait $!
  cd db-5.1.29/build_unix/
  hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$STORAGE_ROOT/berkeley/db5/;
  wait $!
  hide_output sudo make install;
  wait $!
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  sudo rm -r db-5.1.29.tar.gz db-5.1.29
echo -e "$GREEN Berkeley 5.1 Completed...$COL_RESET"

echo -e " Building Berkeley 5.3, this may take several minutes...$COL_RESET"
  sudo mkdir -p $STORAGE_ROOT/berkeley/db5.3/
  hide_output sudo wget 'http://anduin.linuxfromscratch.org/BLFS/bdb/db-5.3.28.tar.gz';
  wait $!
  hide_output sudo tar -xzvf db-5.3.28.tar.gz;
  wait $!
  cd db-5.3.28/build_unix/
  hide_output sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$STORAGE_ROOT/berkeley/db5.3/;
  wait $!
  hide_output sudo make install;
  wait $!
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  sudo rm -r db-5.3.28.tar.gz db-5.3.28
echo -e "$GREEN Berkeley 5.3 Completed...$COL_RESET"

echo -e "Building OpenSSL 1.0.2g, this may take several minutes...$COL_RESET"
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  hide_output sudo wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2g.tar.gz --no-check-certificate;
  wait $!
  hide_output sudo tar -xf openssl-1.0.2g.tar.gz;
  wait $!
  cd openssl-1.0.2g
  hide_output sudo ./config --prefix=${STORAGE_ROOT}/openssl --openssldir=${STORAGE_ROOT}/openssl shared zlib;
  wait $!
  hide_output sudo make;
  wait $!
  hide_output sudo make install;
  wait $!
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  sudo rm -r openssl-1.0.2g.tar.gz openssl-1.0.2g
echo -e "$GREEN OpenSSL 1.0.2g Completed...$COL_RESET"

echo -e " Building bls-signatures, this may take several minutes...$COL_RESET"
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  hide_output sudo wget 'https://github.com/codablock/bls-signatures/archive/v20181101.zip';
  wait $!
  hide_output sudo unzip v20181101.zip;
  wait $!
  cd bls-signatures-20181101
  hide_output sudo cmake .;
  wait $!
  hide_output sudo make install;
  wait $!
  cd $STORAGE_ROOT/yiimp/yiimp_setup/tmp
  sudo rm -r v20181101.zip bls-signatures-20181101
echo -e "$GREEN bls-signatures Completed...$COL_RESET"

sudo cp -r /tmp/blocknotify /usr/bin
sudo chmod +x /usr/bin/blocknotify

echo '#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################
#!/bin/bash
blocknotify '""''"${StratumInternalIP}"''""':$1 $2 $3' | sudo -E tee /usr/bin/blocknotify.sh >/dev/null 2>&1
sudo chmod +x /usr/bin/blocknotify.sh

echo -e "$GREEN Daemon server build completed...$COL_RESET"
exit 0
