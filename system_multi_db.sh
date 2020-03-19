#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

clear
source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

# Set timezone
echo -e " Setting TimeZone to UTC...$COL_RESET"
if [ ! -f /etc/timezone ]; then
	echo "Setting timezone to UTC."
	echo "Etc/UTC" > sudo /etc/timezone
	restart_service rsyslog
fi
echo -e "$GREEN Done...$COL_RESET"

# Add repository
echo -e " Adding the required repsoitories...$COL_RESET"
if [ ! -f /usr/bin/add-apt-repository ]; then
	echo "Installing add-apt-repository..."
	hide_output sudo apt-get -y update
	apt_install software-properties-common
fi
echo -e "$GREEN Done...$COL_RESET"

# MariaDB
echo -e " Installing MariaDB Repository...$COL_RESET"
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
if [[ ("$DISTRO" == "16") ]]; then
  sudo add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://mirror.one.com/mariadb/repo/10.4/ubuntu xenial main' >/dev/null 2>&1
else
  sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.one.com/mariadb/repo/10.4/ubuntu bionic main' >/dev/null 2>&1
fi
echo -e "$GREEN Done...$COL_RESET"

# Upgrade System Files
echo -e " Updating system packages...$COL_RESET"
hide_output sudo apt-get update
echo -e "$GREEN Done...$COL_RESET"

echo -e " Upgrading system packages...$COL_RESET"
if [ ! -f /boot/grub/menu.lst ]; then
	apt_get_quiet upgrade
else
	sudo rm /boot/grub/menu.lst
	hide_output sudo update-grub-legacy-ec2 -y
	apt_get_quiet upgrade
fi
echo -e "$GREEN Done...$COL_RESET"

echo -e " Running Dist-Upgrade...$COL_RESET"
apt_get_quiet dist-upgrade
echo -e "$GREEN Done...$COL_RESET"

echo -e " Running Autoremove...$COL_RESET"
apt_get_quiet autoremove
echo -e "$GREEN Done...$COL_RESET"

echo -e " Installing Base system packages...$COL_RESET"
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip ntpdate \
unattended-upgrades cron ntp fail2ban screen
echo -e "$GREEN Done...$COL_RESET"

# ### Seed /dev/urandom
echo -e " Initializing system random number generator...$COL_RESET"
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r
echo -e "$GREEN Done...$COL_RESET"

echo -e " Installing YiiMP Required system packages...$COL_RESET"
if [ -f /usr/sbin/apache2 ]; then
	echo Removing apache...
	hide_output apt-get -y purge apache2 apache2-*
	hide_output apt-get -y --purge autoremove
fi
hide_output sudo apt-get update
echo -e "$GREEN Done...$COL_RESET"

echo -e " Downloading CryptoPool.builders YiiMP Repo...$COL_RESET"
hide_output sudo git clone $YiiMPRepo $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
if [[ ("$CoinPort" == "y" || "$CoinPort" == "Y" || "$CoinPort" == "yes" || "$CoinPort" == "Yes" || "$CoinPort" == "YES") ]]; then
	cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
	sudo git fetch
	sudo git checkout multi-port
fi
echo -e "$GREEN Done...$COL_RESET"

cd $HOME/multipool/yiimp_multi
