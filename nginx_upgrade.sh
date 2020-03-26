#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

cd /tmp

# NGINX upgrade
echo -e " Upgrading NGINX...$COL_RESET"

#Grab Nginx key and proper mainline package for distro
echo "deb http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list >/dev/null 2>&1

hide_output sudo wget https://nginx.org/keys/nginx_signing.key
wait $!
hide_output sudo apt-key add nginx_signing.key
wait $!
hide_output sudo apt-get update;
wait $!
apt_install nginx;
wait $!

# Make additional conf directories, move and generate needed configurations.
sudo mkdir -p /etc/nginx/cryptopool.builders
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
sudo cp -r /tmp/nginx.conf /etc/nginx/
sudo cp -r /tmp/general.conf /etc/nginx/cryptopool.builders
sudo cp -r /tmp/php_fastcgi.conf /etc/nginx/cryptopool.builders
sudo cp -r /tmp/security.conf /etc/nginx/cryptopool.builders
sudo cp -r /tmp/letsencrypt.conf /etc/nginx/cryptopool.builders

# Removing default nginx site configs.
if [ -f /etc/nginx/conf.d/default.conf ]; then
sudo rm -r /etc/nginx/conf.d/default.conf
fi
if [ -f /etc/nginx/sites-available/default ]; then
sudo rm -r /etc/nginx/sites-available/default
fi
if [ -f /etc/nginx/sites-enabled/default ]; then
sudo rm -r /etc/nginx/sites-enabled/default
fi

restart_service nginx;
wait $!
restart_service php7.3-fpm;
wait $!
echo -e "$GREEN Done...$COL_RESET"
