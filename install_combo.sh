# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
source /etc/multipool.conf
cd $HOME/multipool/yiimp_multi

# Begin Installation
source questions_combined.sh
source system_combo_db.sh
source db_combo.sh
source setsid_web_server.sh
source setsid_daemon_server.sh
