#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

echo Installing MariaDB...
MARIADB_VERSION='10.4'
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client

echo Creating DB users for YiiMP...
Q1="CREATE DATABASE IF NOT EXISTS yiimpfrontend;"
Q2="GRANT ALL ON *.* TO 'panel'@'$WebInternalIP' IDENTIFIED BY '$PanelUserDBPassword';"
Q3="GRANT ALL ON *.* TO 'stratum'@'$StratumInternalIP' IDENTIFIED BY '$StratumUserDBPassword';"
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
host='"${StratumInternalIP}"'
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf
echo Passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf

echo Importing YiiMP Default database values...
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql
# import sql dump
sudo zcat 2019-11-10-yiimp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend
sudo mysql -u root -p"${DBRootPassword}" yiimpfrontend --force < 2018-09-22-workers.sql

sudo sed -i '/max_connections/c\max_connections         = 800' /etc/mysql/my.cnf
sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
sudo sed -i 's/#bind-address=0.0.0.0/bind-address='${DBInternalIP}'/g' /etc/mysql/my.cnf
restart_service mysql;

echo Database build complete...

cd $HOME/multipool/yiimp_multi
