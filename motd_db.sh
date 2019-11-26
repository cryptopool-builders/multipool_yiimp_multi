#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

if [ -d "$HOME/multipool/yiimp_multi" ]; then
  cd $HOME/multipool/yiimp_multi
else
  cd $HOME
fi

apt_install lsb-release figlet update-motd \
landscape-common update-notifier-common
wait $!
cd $HOME/multipool/yiimp_multi/ubuntu/etc/update-motd.d/db
sudo rm -r /etc/update-motd.d/
sudo mkdir /etc/update-motd.d/
sudo touch /etc/update-motd.d/00-header ; sudo touch /etc/update-motd.d/10-sysinfo ; sudo touch /etc/update-motd.d/90-footer
sudo chmod +x /etc/update-motd.d/*
sudo cp -r 00-header 10-sysinfo 90-footer /etc/update-motd.d/
echo '
clear
run-parts /etc/update-motd.d/ | sudo tee /etc/motd
' | sudo -E tee /usr/bin/motd >/dev/null 2>&1

sudo chmod +x /usr/bin/motd

if [ -d "$HOME/multipool/yiimp_multi" ]; then
  cd $HOME/multipool/yiimp_multi
else
  cd $HOME
fi
