#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd $HOME/multipool/yiimp_multi

# Begin Installation
source questions_add_strat.sh
source add_strat_db.sh
source setsid_add_stratum_server.sh

cd ~
clear
echo Installation of your YiiMP additional stratum server is now completed.
exit 0
