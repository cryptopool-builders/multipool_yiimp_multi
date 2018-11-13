#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh

RESULT=$(dialog --stdout --title "Ultimate Crypto-Server Setup Installer v1.06" --menu "Choose one" -1 60 6 \
1 "Install Wireguard all servers" \
2 "YiiMP, DB-Stratum, Web, Daemon" \
3 "YiiMP, DB, Web, Stratum, Daemon" \
4 "YiiMP Additional Stratum Server(s)" \
5 "YiiMP Additional Daemon Server(s)" \
6 Exit)
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
cd $HOME/multipool/yiimp_multi
source install_add_strat.sh;
fi

if [ $RESULT = 5 ]
then
clear;
cd $HOME/multipool/yiimp_multi
source install_add_daemon.sh;
fi

if [ $RESULT = 6 ]
then
clear;
exit;
fi
