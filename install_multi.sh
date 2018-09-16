#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd $HOME/multipool/yiimp_multi

# Begin Installation
source questions_multi.sh
source system_multi_db.sh
source db_multi.sh
source setsid_web_server.sh
source setsid_stratum_server.sh
source setsid_daemon_server.sh
source server_harden.sh
source motd_db.sh
