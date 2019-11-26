#!/usr/bin/env bash

#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

echo -e " Building stratum server...$COL_RESET"

sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf

sudo mkdir -p $STORAGE_ROOT/yiimp/site/stratum
sudo mkdir -p $STORAGE_ROOT/yiimp/starts

echo -e " Building stratum folder structure and copying files...$COL_RESET"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/iniparser
hide_output sudo make
wait $!
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
if [[ ("$AutoExchange" == "y" || "$AutoExchange" == "Y" || "$AutoExchange" == "yes" || "$AutoExchange" == "Yes" || "$AutoExchange" == "YES") ]]; then
sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/Makefile
fi
hide_output sudo make
wait $!
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo cp -a config.sample/. $STORAGE_ROOT/yiimp/site/stratum/config
sudo cp -r stratum $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r run.sh $STORAGE_ROOT/yiimp/site/stratum
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp

sudo rm -r $STORAGE_ROOT/yiimp/site/stratum/config/run.sh
echo '#!/usr/bin/env bash
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
ulimit -n 10240
ulimit -u 10240
cd '""''"${STORAGE_ROOT}"''""'/yiimp/site/stratum
while true; do
./stratum config/$1
sleep 2
done
exec bash' | sudo -E tee $STORAGE_ROOT/yiimp/site/stratum/config/run.sh >/dev/null 2>&1
sudo chmod +x $STORAGE_ROOT/yiimp/site/stratum/config/run.sh

sudo rm -r $STORAGE_ROOT/yiimp/site/stratum/run.sh
echo '#!/usr/bin/env bash
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
cd '""''"${STORAGE_ROOT}"''""'/yiimp/site/stratum/config/ && ./run.sh $*
' | sudo -E tee $STORAGE_ROOT/yiimp/site/stratum/run.sh >/dev/null 2>&1
sudo chmod +x $STORAGE_ROOT/yiimp/site/stratum/run.sh
echo -e "$GREEN Done...$COL_RESET"

echo -e " Updating stratum config files with database connection info...$COL_RESET"
cd $STORAGE_ROOT/yiimp/site/stratum/config
sudo sed -i 's/password = tu8tu5/password = '${blckntifypass}'/g' *.conf
sudo sed -i 's/server = yaamp.com/server = '${StratumURL}'/g' *.conf
sudo sed -i 's/host = yaampdb/host = '${DBInternalIP}'/g' *.conf
sudo sed -i 's/database = yaamp/database = '${YiiMPDBName}'/g' *.conf
sudo sed -i 's/username = root/username = '${StratumDBUser}'/g' *.conf
sudo sed -i 's/password = patofpaq/password = '${StratumUserDBPassword}'/g' *.conf

#set permissions
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/yiimp/site/stratum/
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/yiimp/site/stratum/config

echo -e "$GREEN Stratum server build completed...$COL_RESET"
exit 0
