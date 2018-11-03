#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd $HOME/multipool/yiimp_multi

# Begin Installation
source questions_add_daemon.sh
source setsid_add_daemon_server.sh

cd ~
clear
echo Installation of your YiiMP additional daemon server is now completed.
exit 0
