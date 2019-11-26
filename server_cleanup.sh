#!/usr/bin/env bash

#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

echo -e " Installing cron screens to crontab...$COL_RESET"
(crontab -l 2>/dev/null; echo "@reboot sleep 20 && /home/crypto-data/yiimp/starts/screens.start.sh") | crontab -
(crontab -l 2>/dev/null; echo "@reboot source /etc/functions.sh") | crontab -
(crontab -l 2>/dev/null; echo "@reboot source /etc/multipool.conf") | crontab -
sudo cp -r /tmp/first_boot.sh $STORAGE_ROOT/yiimp/
echo -e "$GREEN Done...$COL_RESET"

echo -e " Creating YiiMP Screens startup script...$COL_RESET"
echo '#!/usr/bin/env bash
source /etc/multipool.conf
# Ugly way to remove junk coins from initial YiiMP database on first boot
source $STORAGE_ROOT/yiimp/.yiimp.conf
if [[ ! -e '$STORAGE_ROOT/yiimp/first_boot.sh' ]]; then
echo
else
source $STORAGE_ROOT/yiimp/first_boot.sh
fi
################################################################################
# Author: cryptopool.builders
#
#
# Program: yiimp screen startup script
#
# BTC Donation: 12Pt3vQhQpXvyzBd5qcoL17ouhNFyihyz5
#
################################################################################
sudo chmod 777 $STORAGE_ROOT/yiimp/site/log/.
sudo chmod 777 $STORAGE_ROOT/yiimp/site/log/debug.log
LOG_DIR=$STORAGE_ROOT/yiimp/site/log
CRONS=$STORAGE_ROOT/yiimp/site/crons
screen -dmS main bash $CRONS/main.sh
screen -dmS loop2 bash $CRONS/loop2.sh
screen -dmS blocks bash $CRONS/blocks.sh
screen -dmS debug tail -f $LOG_DIR/debug.log
' | sudo -E tee $STORAGE_ROOT/yiimp/starts/screens.start.sh >/dev/null 2>&1
sudo chmod +x $STORAGE_ROOT/yiimp/starts/screens.start.sh

echo '
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
LOG_DIR=$STORAGE_ROOT/yiimp/site/log
CRONS=$STORAGE_ROOT/yiimp/site/crons
' | sudo -E tee $STORAGE_ROOT/yiimp/.prescreens.start.conf >/dev/null 2>&1

echo "source /etc/multipool.conf" | hide_output tee -a ~/.bashrc
echo "source $STORAGE_ROOT/yiimp/.prescreens.start.conf" | hide_output tee -a ~/.bashrc
echo -e "$GREEN Done...$COL_RESET"
exit 0
