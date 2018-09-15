#!/bin/bash
source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

# NGINX upgrade
echo Upgrading NGINX...
hide_output sudo wget https://nginx.org/keys/nginx_signing.key
hide_output sudo apt-key add nginx_signing.key
sudo rm -r nginx_signing.key
echo 'deb https://nginx.org/packages/mainline/ubuntu/ xenial nginx
deb-src https://nginx.org/packages/mainline/ubuntu/ xenial nginx
' | sudo -E tee /etc/apt/sources.list.d/nginx.list >/dev/null 2>&1

hide_output sudo apt-get update
apt_install nginx

sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
sudo cp -r /tmp/nginx.conf /etc/nginx/

restart_service nginx
restart_service php7.2-fpm
