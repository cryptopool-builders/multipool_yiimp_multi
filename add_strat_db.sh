#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.newconf.conf


echo Creating New DB users for YiiMP...
Q1="GRANT ALL ON *.* TO '$StratumDBUser'@'$StratumInternalIP' IDENTIFIED BY '$StratumUserDBPassword';"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo Creating my.$generate.cnf...
echo '[clienthost1]
user='"${StratumDBUser}"'
password='"${PanelUserDBPassword}"'
database=yiimpfrontend
host='"${StratumInternalIP}"'
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.$generate.cnf >/dev/null 2>&1

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.$generate.cnf
echo Passwords can be found in $STORAGE_ROOT/yiimp/.my.$generate.cnf

echo Database build complete...
