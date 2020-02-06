#!/usr/bin/env bash

#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

echo -e " Building stratum server...$COL_RESET"

sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf

# copy addport to /usr/bin
sudo chmod +x /tmp/addport
sudo chmod +x /tmp/addport_multi
sudo cp -r /tmp/addport /usr/bin
sudo cp -r /tmp/addport_multi /usr/bin

# make needed directories
sudo mkdir -p $STORAGE_ROOT/yiimp/site/stratum
sudo mkdir -p $STORAGE_ROOT/yiimp/starts

# build blocknotify and stratum
echo -e " Building blocknotify and stratum...$COL_RESET"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify
blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo sed -i 's/tu8tu5/'${blckntifypass}'/' blocknotify.cpp
hide_output sudo make
wait $!
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/iniparser
hide_output sudo make
wait $!
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
if [[ ("$AutoExchange" == "y" || "$AutoExchange" == "Y" || "$AutoExchange" == "yes" || "$AutoExchange" == "Yes" || "$AutoExchange" == "YES") ]]; then
  sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum/Makefile
fi
hide_output sudo make
wait $!
echo -e " Building stratum folder structure and copying files...$COL_RESET"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo cp -a config.sample/. $STORAGE_ROOT/yiimp/site/stratum/config
sudo cp -r stratum $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r run.sh $STORAGE_ROOT/yiimp/site/stratum
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify/blocknotify $STORAGE_ROOT/yiimp/site/stratum
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/blocknotify/blocknotify /usr/bin

# create run files
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

# sed the config files with the needed updated information
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

# copy blocknotify to daemon servers
# set daemon user and password
DaemonUser=${DaemonUser}
DaemonPass="${DaemonPass}"
DaemonServer=${DaemonInternalIP}

# set script paths
script_blocknotify="${STORAGE_ROOT}/yiimp/site/stratum/blocknotify"

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

echo -e "$GREEN Stratum server build complete...$COL_RESET"
exit 0
