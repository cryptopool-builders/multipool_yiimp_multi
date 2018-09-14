source /etc/functions.sh

RESULT=$(dialog --stdout --title "Ultimate Crypto-Server Setup Installer" --menu "Choose one" -1 60 4 \
1 "Install Wireguard all servers" \
2 "YiiMP DB-Stratum Combined, Web Server, Daemon Server" \
3 "YiiMP DB Server, Web Server, Stratum Server, Daemon Server" \
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
source questions_combined.sh;
source combined.sh;
fi

if [ $RESULT = 3 ]
then
clear;
cd $HOME/multipool/yiimp_multi
source questions_singles.sh;
source singles.sh;
fi

if [ $RESULT = 4 ]
then
clear;
exit;
fi
