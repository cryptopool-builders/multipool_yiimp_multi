#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh

RESULT=$(dialog --stdout --title "Ultimate Crypto-Server Setup Installer" --menu "Choose one" -1 60 4 \
1 "Install Wireguard all servers" \
2 "YiiMP DB-Stratum, Web, Daemon" \
3 "YiiMP DB, Web, Stratum, Daemon" \
4 Exit)
if [ $RESULT = ]
then
exit ;
fi


if [ $RESULT = 1 ]
then
clear;
cd $HOME/multipool/yiimp_multi
source wireguard_menu.sh;
fi

if [ $RESULT = 2 ]
then
clear;
cd $HOME/multipool/yiimp_multi
source install_combo.sh;
fi

if [ $RESULT = 3 ]
then
clear;
cd $HOME/multipool/yiimp_multi
source install_multi.sh;
fi

if [ $RESULT = 4 ]
then
clear;
exit;
fi
