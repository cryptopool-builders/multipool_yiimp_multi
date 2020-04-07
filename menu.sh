#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh

RESULT=$(dialog --stdout --nocancel --default-item 1 --title "Ultimate Crypto-Server Setup Installer v1.52" --menu "Choose one" -1 63 10 \
' ' "- Required if your Host does Not provide Private IPs -" \
1 "Install Wireguard Network" \
' ' "- Three Server Configuration -" \
2 "YiiMP - DB-Stratum, Web, Daemon" \
' ' "- Four Server Configuration -" \
3 "YiiMP - DB, Web, Stratum, Daemon" \
' ' "- Add Additional Servers -" \
4 "YiiMP - Additional Stratum Server(s)" \
5 "YiiMP - Additional Daemon Server(s)" \
6 Exit)
if [ $RESULT = ]
then
bash $(basename $0) && exit;
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
