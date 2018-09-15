source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

echo Installing MariaDB...
MARIADB_VERSION='10.3'
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client

echo Creating DB users for YiiMP...
Q1="CREATE DATABASE IF NOT EXISTS yiimpfrontend;"
Q2="GRANT ALL ON *.* TO 'panel'@'$WebInternalIP' IDENTIFIED BY '$PanelUserDBPassword';"
Q3="GRANT ALL ON *.* TO 'stratum'@'localhost' IDENTIFIED BY '$StratumUserDBPassword';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo Creating my.cnf...
echo '[clienthost1]
user=panel
password='"${PanelUserDBPassword}"'
database=yiimpfrontend
host='"${WebInternalIP}"'
[clienthost2]
user=stratum
password='"${StratumUserDBPassword}"'
database=yiimpfrontend
host=localhost
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf
echo Passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf

echo Importing YiiMP Default database values...
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql
# import sql dump
sudo zcat 2016-04-03-yaamp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend
# oh the humanity!
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-04-24-market_history.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-04-27-settings.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-05-11-coins.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-05-15-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-05-23-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-06-01-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-06-04-bench_chips.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2016-11-23-coins.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-02-05-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-03-31-earnings_index.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-05-accounts_case_swaptime.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-06-payouts_coinid_memo.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-09-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-10-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2017-11-segwit.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2018-01-stratums_ports.sql
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2018-02-coins_getinfo.sql

echo Database build complete...

echo Building blocknotify and stratum...
sudo mkdir -p $STORAGE_ROOT/yiimp/site/stratum
sudo mkdir -p $STORAGE_ROOT/yiimp/starts
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify
blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
hide_output sudo make
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/iniparser
hide_output sudo make
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/Makefile
hide_output sudo make

echo Building stratum folder structure and copying files...
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo cp -a config.sample/. $STORAGE_ROOT/yiimp/site/stratum/config
sudo cp -r stratum $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r run.sh $STORAGE_ROOT/yiimp/site/stratum
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify/blocknotify $STORAGE_ROOT/yiimp/site/stratum

sudo rm -r $STORAGE_ROOT/yiimp/site/stratum/config/run.sh

echo '#!/bin/bash
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

echo '#!/bin/bash
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
cd '""''"${STORAGE_ROOT}"''""'/yiimp/site/stratum/config/ && ./run.sh $*
' | sudo -E tee $STORAGE_ROOT/yiimp/site/stratum/run.sh >/dev/null 2>&1
sudo chmod +x $STORAGE_ROOT/yiimp/site/stratum/run.sh

echo Updating stratum config files with database connection info...
cd $STORAGE_ROOT/yiimp/site/stratum/config
sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
sudo sed -i 's/server = yaamp.com/server = '$StratumURL'/g' *.conf
sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
sudo sed -i 's/database = yaamp/database = yiimpfrontend/g' *.conf
sudo sed -i 's/username = root/username = stratum/g' *.conf
sudo sed -i 's/password = patofpaq/password = '$StratumUserDBPassword'/g' *.conf

echo Stratum build complete...

cd $HOME/multipool/yiimp_multi
