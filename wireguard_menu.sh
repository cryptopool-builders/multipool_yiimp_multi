source /etc/functions.sh
cd $HOME/multipool/yiimp_multi

RESULT=$(dialog --stdout --title "Ultimate Crypto-Server Setup Installer" --menu "Choose one" -1 60 5 \
1 "Install Wireguard on DB Server or DB-Stratum Server" \
2 "Install Wireguard on Web Server" \
3 "Install Wireguard on Stratum Server" \
4 "Install Wireguard on Daemon Server" \
5 Exit)
if [ $RESULT = ]
then
exit ;
fi

if [ $RESULT = 1 ]
then
clear;
echo 'server_type='db'
DBInternalIP='10.0.0.2'
' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard.conf >/dev/null 2>&1;
cd $HOME/multipool/yiimp_multi
source wireguard.sh;
exit ;
fi

if [ $RESULT = 2 ]
then
clear;
read -e -p "Please enter the DB servers PUBLIC IP : " DBServerIP;
read -e -p "Please enter the DB public key that was displayed : " DBPublicKey;
echo 'server_type='web'
WebInternalIP='10.0.0.3'
DBInternalIP='10.0.0.2'
DBServerIP='"${DBServerIP}"'
DBPublicKey='"${DBPublicKey}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard.conf >/dev/null 2>&1;
cd $HOME/multipool/yiimp_multi
source wireguard.sh;
exit ;
fi

if [ $RESULT = 3 ]
then
clear;
read -e -p "Please enter the DB servers PUBLIC IP : " DBServerIP;
read -e -p "Please enter the DB public key that was displayed : " DBPublicKey;
echo 'server_type='stratum'
StratumInternalIP='10.0.0.4'
DBInternalIP='10.0.0.2'
DBServerIP='"${DBServerIP}"'
DBPublicKey='"${DBPublicKey}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard.conf >/dev/null 2>&1;
cd $HOME/multipool/yiimp_multi
source wireguard.sh;
exit ;
fi

if [ $RESULT = 4 ]
then
clear;
read -e -p "Please enter the DB servers PUBLIC IP : " DBServerIP;
read -e -p "Please enter the DB public key that was displayed : " DBPublicKey;
echo 'server_type='daemon'
DaemonInternalIP='10.0.0.5'
DBInternalIP='10.0.0.2'
DBServerIP='"${DBServerIP}"'
DBPublicKey='"${DBPublicKey}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard.conf >/dev/null 2>&1;
cd $HOME/multipool/yiimp_multi
source wireguard.sh;
exit ;
fi

if [ $RESULT = 5 ]
then
clear;
exit;
fi
cd $HOME/multipool/yiimp_multi
