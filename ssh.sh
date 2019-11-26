#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################


source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf


echo -e " Initializing UFW Firewall...$COL_RESET"
if [ -z "${DISABLE_FIREWALL:-}" ]; then
	# Install `ufw` which provides a simple firewall configuration.
	apt_install ufw;
  wait $!

	# Allow incoming connections to SSH.
	ufw_allow ssh;
  wait $!
	ufw_allow http;
  wait $!
	ufw_allow https;
  wait $!
  ufw_allow mysql;
  wait $!
	# ssh might be running on an alternate port. Use sshd -T to dump sshd's #NODOC
	# settings, find the port it is supposedly running on, and open that port #NODOC
	# too. #NODOC
	SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //") #NODOC
	if [ ! -z "$SSH_PORT" ]; then
	if [ "$SSH_PORT" != "22" ]; then

	echo Opening alternate SSH port $SSH_PORT. #NODOC
	ufw_allow $SSH_PORT;
  wait $!
	ufw_allow http;
  wait $!
	ufw_allow https;
  wait $!
  ufw_allow mysql;
  wait $!

	fi
	fi

sudo ufw --force enable;
wait $!
fi #NODOC

echo -e "$GREEN Done...$COL_RESET"

# Installation of remote server completed.... Force rebot server...
sudo reboot
