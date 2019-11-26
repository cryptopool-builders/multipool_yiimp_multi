#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf
cd $HOME/multipool/yiimp_multi

if [ -d "$HOME/multipool/yiimp_multi" ]; then
  cd $HOME/multipool/yiimp_multi
else
  cd $HOME
fi

echo -e " Building DB and stratum server...$COL_RESET"
echo
echo -e " Installing MariaDB 10.4...$COL_RESET"
MARIADB_VERSION='10.4'
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client
echo -e "$GREEN Done...$COL_RESET"

echo -e " Creating YiiMP DB...$COL_RESET"
Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'${WebInternalIP}' IDENTIFIED BY '${PanelUserDBPassword}';"
Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'localhost' IDENTIFIED BY '${StratumUserDBPassword}';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo '[clienthost1]
user='"${YiiMPPanelName}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${WebInternalIP}"'
[clienthost2]
user="'${StratumDBUser}'"
password='"${StratumUserDBPassword}"'
database='"${YiiMPDBName}"'
host=localhost
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf
echo -e "$GREEN DB users and passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf$COL_RESET"

cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql
# import sql dump
sudo zcat 2019-11-10-yiimp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName}
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2018-09-22-workers.sql
sudo sed -i '/max_connections/c\max_connections         = 800' /etc/mysql/my.cnf
sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
sudo sed -i 's/#bind-address=0.0.0.0/bind-address='${DBInternalIP}'/g' /etc/mysql/my.cnf
restart_service mysql;
wait $!
echo -e "$GREEN Database build complete...$COL_RESET"

echo -e " Building blocknotify and stratum...$COL_RESET"
sudo mkdir -p $STORAGE_ROOT/yiimp/site/stratum
sudo mkdir -p $STORAGE_ROOT/yiimp/starts
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify
blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo sed -i 's/tu8tu5/'${blckntifypass}'/' blocknotify.cpp
hide_output sudo make
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/iniparser
hide_output sudo make
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
if [[ ("$AutoExchange" == "y" || "$AutoExchange" == "Y" || "$AutoExchange" == "yes" || "$AutoExchange" == "Yes" || "$AutoExchange" == "YES") ]]; then
sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/Makefile
fi
hide_output sudo make
echo -e "$GREEN Done...$COL_RESET"
echo -e " Building stratum folder structure and copying files...$COL_RESET"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo cp -a config.sample/. $STORAGE_ROOT/yiimp/site/stratum/config
sudo cp -r stratum $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r run.sh $STORAGE_ROOT/yiimp/site/stratum
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify/blocknotify $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify/blocknotify /usr/bin

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
sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
sudo sed -i 's/database = yaamp/database = '${YiiMPDBName}'/g' *.conf
sudo sed -i 's/username = root/username = '${StratumDBUser}'/g' *.conf
sudo sed -i 's/password = patofpaq/password = '${StratumUserDBPassword}'/g' *.conf
#set permissions
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/yiimp/site/stratum/
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/yiimp/site/stratum/config
echo -e "$GREEN Done...$COL_RESET"

# copy blocknotify to daemon servers
# set daemon user and password
DaemonUser=${DaemonUser}
DaemonPass="${DaemonPass}"
DaemonServer=${DaemonInternalIP}

# set script paths
script_blocknotify="$STORAGE_ROOT/yiimp/site/stratum/blocknotify"

# Desired location of the scripts on the remote server.
remote_script_blocknotify_path="/tmp/blocknotify"

# set ssh Stratum
SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/usr/bin/env bash
echo '${DaemonPass}'
EOL
chmod u+x ${SSH_ASKPASS_SCRIPT}

# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
export DISPLAY=:0

# Tell SSH to read in the output of the provided script as the password.
# We still have to use setsid to eliminate access to a terminal and thus avoid
# it ignoring this and asking for a password.
export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}

# LogLevel error is to suppress the hosts warning. The others are
# necessary if working with development servers with self-signed
# certificates.
SSH_OPTIONS="-oLogLevel=error"
SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"

# Load in a base 64 encoded version of the script.
B64_blocknotify=`base64 --wrap=0 ${script_blocknotify}`

# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.
blocknotify="base64 -d - > ${remote_script_blocknotify_path} <<< ${B64_blocknotify};"
blocknotify="${blocknotify} chmod +x ${remote_script_blocknotify_path}; > /dev/null 2>&1 &"

# Execute scripts on remote server
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${blocknotify}"
echo -e "$GREEN DB and stratum server build completed...$COL_RESET"
cd $HOME/multipool/yiimp_multi
