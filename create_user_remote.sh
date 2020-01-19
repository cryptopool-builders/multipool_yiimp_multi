#!/usr/bin/env bash


#####################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

# Need this in case user has a provider that offers private IP's and doesnt re-run the multipool installer after user creation
# Make sure our functions are loaded
if [ -f /etc/functions.sh ]; then
  source /etc/functions.sh
else
  sudo cp -r /tmp/functions.sh /etc/
  source /etc/functions.sh
fi

echo -e " Begin remote server creations, installer may look hung...$COL_RESET"

# Get logged in user name
whoami=`whoami`
echo -e " Modifying existing user $whoami for multipool support."
sudo usermod -aG sudo ${whoami}

echo '# yiimp
# It needs passwordless sudo functionality.
'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

if [ ! -f /usr/bin/dialog ] || [ ! -f /usr/bin/python3 ] || [ ! -f /usr/bin/pip3 ] || [ ! -f /usr/bin/acl ] || [ ! -f /usr/bin/nano ] || [ ! -f /usr/bin/git ] ; then
sudo apt-get -q -q update
apt_get_quiet install dialog python3 python3-pip acl nano apt-transport-https git curl || exit 1
fi

if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/' `" == "Ubuntu 18.04 LTS" ]; then
  DISTRO=18
  sudo chmod g-w /etc /etc/default /usr
else [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/16\.04\.[0-9]/16.04/' `" != "Ubuntu 16.04 LTS" ];
  DISTRO=16
fi

TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
  if [ $TOTAL_PHYSICAL_MEM -lt 2000000 ]; then
    if [ ! -d /vagrant ]; then
      TOTAL_PHYSICAL_MEM=$(expr \( \( $TOTAL_PHYSICAL_MEM \* 1024 \) / 1000 \) / 1000)
      echo "Your Crypto-Pool Server needs more memory (RAM) to function properly."
      echo "Please provision a machine with at least 2 GB, 6 GB recommended."
      echo "This machine has $TOTAL_PHYSICAL_MEM MB memory."
      exit
    fi
  fi
if [ $TOTAL_PHYSICAL_MEM -lt 2000000 ]; then
  echo "WARNING: Your Crypto-Pool Server has less than 4 GB of memory."
  echo " It might run unreliably when under heavy load."
fi

# Check swap
echo -e " Checking if swap space is needed and if so creating...$COL_RESET"
  SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
  SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
  ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
  TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
  AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)
if
  [ -z "$SWAP_MOUNTED" ] &&
  [ -z "$SWAP_IN_FSTAB" ] &&
  [ ! -e /swapfile ] &&
  [ -z "$ROOT_IS_BTRFS" ] &&
  [ $TOTAL_PHYSICAL_MEM -lt 19000000 ] &&
  [ $AVAILABLE_DISK_SPACE -gt 5242880 ]
then
echo "Adding a swap file to the system..."
  dd if=/dev/zero of=/swapfile bs=2048 count=$[1024*1024] status=none
    if [ -e /swapfile ]; then
      chmod 600 /swapfile
      hide_output mkswap /swapfile
      swapon /swapfile
    fi
    if swapon -s | grep -q "\/swapfile"; then
      echo "/swapfile  none swap sw 0  0" >> /etc/fstab
    else
      echo "ERROR: Swap allocation failed"
    fi
fi
echo -e "$GREEN Done...$COL_RESET"

ARCHITECTURE=$(uname -m)
  if [ "$ARCHITECTURE" != "x86_64" ]; then
    if [ -z "$ARM" ]; then
      echo "Ultimate Crypto-Server Setup Installer only supports x86_64 and will not work on any other architecture, like ARM or 32 bit OS."
      echo "Your architecture is $ARCHITECTURE"
      exit
    fi
fi

echo -e " Setting up some needed global variables...$COL_RESET"
# Setting Public IP for this server both IPv4 and IPv6
if [ -z "$PUBLIC_IP" ]; then
  GUESSED_IP=$(get_publicip_from_web_service 4)
  if [[ -z "$DEFAULT_PUBLIC_IP" && ! -z "$GUESSED_IP" ]]; then
    PUBLIC_IP=$GUESSED_IP
  elif [ "$DEFAULT_PUBLIC_IP" == "$GUESSED_IP" ]; then
    PUBLIC_IP=$GUESSED_IP
fi
if [ -z "$PUBLIC_IP" ]; then
  input_box "Public IP Address" \
  "Enter the public IP address of this machine, as given to you by your ISP.
  \n\nPublic IP address:" \
  $DEFAULT_PUBLIC_IP \
  PUBLIC_IP
  if [ -z "$PUBLIC_IP" ]; then
    exit
  fi
  fi
fi

if [ -z "$PUBLIC_IPV6" ]; then
  GUESSED_IP=$(get_publicip_from_web_service 6)
  MATCHED=0
  if [[ -z "$DEFAULT_PUBLIC_IPV6" && ! -z "$GUESSED_IP" ]]; then
    PUBLIC_IPV6=$GUESSED_IP
  elif [[ "$DEFAULT_PUBLIC_IPV6" == "$GUESSED_IP" ]]; then
    PUBLIC_IPV6=$GUESSED_IP
    MATCHED=1
fi
if [[ -z "$PUBLIC_IPV6" && $MATCHED == 0 ]]; then
  input_box "IPv6 Address (Optional)" \
  "Enter the public IPv6 address of this machine, as given to you by your ISP.
  \n\nLeave blank if the machine does not have an IPv6 address.
  \n\nPublic IPv6 address:" \
  $DEFAULT_PUBLIC_IPV6 \
  PUBLIC_IPV6
  if [ ! $PUBLIC_IPV6_EXITCODE ]; then
    exit
  fi
  fi
fi

# Setting the needed variables.
if [ "$PUBLIC_IP" = "auto" ]; then
  PUBLIC_IP=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi
if [ "$PUBLIC_IPV6" = "auto" ]; then
  PUBLIC_IPV6=$(get_publicip_from_web_service 6 || get_default_privateip 6)
fi

# Set STORAGE_USER and STORAGE_ROOT to default values (crypto-data and /home/crypto-data), unless
# we've already got those values from a previous run.
if [ -z "$STORAGE_USER" ]; then
  STORAGE_USER=$([[ -z "$DEFAULT_STORAGE_USER" ]] && echo "crypto-data" || echo "$DEFAULT_STORAGE_USER")
fi
if [ -z "$STORAGE_ROOT" ]; then
  STORAGE_ROOT=$([[ -z "$DEFAULT_STORAGE_ROOT" ]] && echo "/home/$STORAGE_USER" || echo "$DEFAULT_STORAGE_ROOT")
fi

# Create the STORAGE_USER and STORAGE_ROOT directory if they don't already exist.
if ! id -u $STORAGE_USER >/dev/null 2>&1; then
  sudo useradd -m $STORAGE_USER
fi
if [ ! -d $STORAGE_ROOT ]; then
  sudo mkdir -p $STORAGE_ROOT
fi

# Save the global options in /etc/multipool.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PUBLIC_IP='"${PUBLIC_IP}"'
DISTRO='"${DISTRO}"'
PUBLIC_IPV6='"${PUBLIC_IPV6}"'' | sudo -E tee /etc/multipool.conf >/dev/null 2>&1
echo -e "$GREEN Done...$COL_RESET"
