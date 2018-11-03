#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd $HOME/multipool/yiimp_multi

# Begin Installation
source questions_add_strat.sh
source setsid_add_stratum_server.sh
source add_strat_db.sh

cd ~
clear
echo Installation of your YiiMP additional stratum server is now completed.
echo You *MUST* reboot this machine to finalize the system updates and folder permissions! YiiMP will not function until a reboot is performed!
echo
