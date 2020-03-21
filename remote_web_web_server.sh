#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

echo -e " Building web file structure and copying files...$COL_RESET"

sudo mkdir -p $STORAGE_ROOT/yiimp/site/web
sudo mkdir -p $STORAGE_ROOT/yiimp/site/configuration
sudo mkdir -p $STORAGE_ROOT/yiimp/site/crons
sudo mkdir -p $STORAGE_ROOT/yiimp/site/log
sudo mkdir -p $STORAGE_ROOT/yiimp/starts

cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo sed -i 's/AdminRights/'${AdminPanel}'/' $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/web/yaamp/modules/site/SiteController.php
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/web $STORAGE_ROOT/yiimp/site/
cd $STORAGE_ROOT/yiimp/yiimp_setup/
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/bin/. /bin/
sudo mkdir -p /var/www/${DomainName}/html
sudo mkdir -p /etc/yiimp
sudo mkdir -p $STORAGE_ROOT/yiimp/site/backup/
sudo sed -i "s|ROOTDIR=/data/yiimp|ROOTDIR=${STORAGE_ROOT}/yiimp/site|g" /bin/yiimp
echo -e "$GREEN Done...$COL_RESET"

echo -e " Creating nginx web configuration files...$COL_RESET"
if [[ ("$UsingSubDomain" == "y" || "$UsingSubDomain" == "Y" || "$UsingSubDomain" == "yes" || "$UsingSubDomain" == "Yes" || "$UsingSubDomain" == "YES") ]]; then
  source /tmp/nginx_subdomain_nonssl.sh;
    if [[ ("$InstallSSL" == "y" || "$InstallSSL" == "Y" || "$InstallSSL" == "yes" || "$InstallSSL" == "Yes" || "$InstallSSL" == "YES") ]]; then
      source /tmp/nginx_subdomain_ssl.sh;
    fi
      else
        source /tmp/nginx_domain_nonssl.sh;
    if [[ ("$InstallSSL" == "y" || "$InstallSSL" == "Y" || "$InstallSSL" == "yes" || "$InstallSSL" == "Yes" || "$InstallSSL" == "YES") ]]; then
      source /tmp/nginx_domain_ssl.sh;
    fi
fi
echo -e "$GREEN Done...$COL_RESET"

echo -e " Creating YiiMP configuration files...$COL_RESET"
sudo chmod u+x /tmp/keys.sh;
source /tmp/keys.sh;
sudo chmod u+x /tmp/yiimpserverconfig.sh;
source /tmp/yiimpserverconfig.sh;
sudo chmod u+x /tmp/main.sh;
source /tmp/main.sh;
sudo chmod u+x /tmp/loop2.sh;
source /tmp/loop2.sh;
sudo chmod u+x /tmp/blocks.sh;
source /tmp/blocks.sh;
echo -e "$GREEN Done...$COL_RESET"

echo -e " Setting correct folder permissions...$COL_RESET"
whoami=`whoami`
sudo usermod -aG www-data $whoami
sudo usermod -a -G www-data $whoami
sudo usermod -a -G crypto-data $whoami
sudo usermod -a -G crypto-data www-data
sudo find $STORAGE_ROOT/yiimp/site/ -type d -exec chmod 775 {} +
sudo find $STORAGE_ROOT/yiimp/site/ -type f -exec chmod 664 {} +
sudo chgrp www-data $STORAGE_ROOT -R
sudo chmod g+w $STORAGE_ROOT -R
echo -e "$GREEN Done...$COL_RESET"

#Updating YiiMP files for cryptopool.builders build
#Set Insternal IP to .0/26
internalrpcip=$WebInternalIP
internalrpcip="${WebInternalIP::-1}"
internalrpcip="${internalrpcip::-1}"
internalrpcip=$internalrpcip.0/26

echo -e " Adding the cryptopool.builders flare to YiiMP...$COL_RESET"
sudo sed -i 's/YII MINING POOLS/'${DomainName}' Mining Pool/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/index.php
sudo sed -i 's/domain/'${DomainName}'/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/index.php
sudo sed -i 's/Notes/AddNodes/g' $STORAGE_ROOT/yiimp/site/web/yaamp/models/db_coinsModel.php
sudo sed -i "s|serverconfig.php|${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/index.php
sudo sed -i "s|serverconfig.php|${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/runconsole.php
sudo sed -i "s|serverconfig.php|${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/run.php
sudo sed -i "s|serverconfig.php|${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/yaamp/yiic.php
sudo sed -i "s|serverconfig.php|${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php

sudo sed -i '/# onlynet=ipv4/i\    echo "rpcallowip='${internalrpcip}'\\n";\n' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/coin_form.php
sudo sed -i 's/internalipsed/'${DaemonInternalIP}'/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/coin_form.php

sudo sed -i "s|/root/backup|${STORAGE_ROOT}/yiimp/site/backup|g" $STORAGE_ROOT/yiimp/site/web/yaamp/core/backend/system.php
sudo sed -i 's/service $webserver start/sudo service $webserver start/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php
sudo sed -i 's/service nginx stop/sudo service nginx stop/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php

echo -e "$GREEN Web structure completed...$COL_RESET"
exit 0
