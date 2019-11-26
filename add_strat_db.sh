#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.newconf.conf

if [ -d "$HOME/multipool/yiimp_multi" ]; then
  cd $HOME/multipool/yiimp_multi
else
  cd $HOME
fi

echo -e " Creating new stratum user for YiiMP...$COL_RESET"
  Q1="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'${StratumInternalIP}' IDENTIFIED BY '${StratumUserDBPassword}';"
  Q2="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo Creating my.$generate.cnf...
echo '[clienthost1]
user='"${StratumDBUser}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${StratumInternalIP}"'
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.$generate.cnf >/dev/null 2>&1
sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.$generate.cnf

echo -e "$GREEN DB users and passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf$COL_RESET"
echo
echo -e "$GREEN New user created...$COL_RESET"
