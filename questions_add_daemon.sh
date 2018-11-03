#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

# Get the IP addresses of the local network interface(s).
if [ -z "$NewDaemonInternalIP" ]; then
DEFAULT_NewDaemonInternalIP='10.0.0.x'
input_box "Daemon Server Private IP" \
"Enter the private IP address of the Daemon Server, as given to you by your provider.
\n\nIf you do not have one from your provider enter the IP you assigned with Wireguard.
\n\nPrivate IP address:" \
$DEFAULT_NewDaemonInternalIP \
NewDaemonInternalIP

if [ -z "$NewDaemonInternalIP" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "$NewDaemonUser" ]; then
DEFAULT_NewDaemonUser='yiimpadmin'
input_box "Daemon Server User Name" \
"Enter the user name of the Daemon Server.
\n\nThis is required for setup to complete.
\n\nDaemon Server User Name:" \
$DEFAULT_NewDaemonUser \
NewDaemonUser

if [ -z "$NewDaemonUser" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "$NewDaemonPass" ]; then
DEFAULT_NewDaemonPass='password'
input_box "Daemon Server User Password" \
"Enter the user password of the Daemon Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nDaemon Server User Password:" \
$DEFAULT_NewDaemonPass \
NewDaemonPass

if [ -z "$NewDaemonPass" ]; then
user hit ESC/cancel
exit
fi
fi

#Generate random conf file name, random StratumDBUser and StratumDBPassword
generate=$(openssl rand -base64 9 | tr -d "=+/")

# Save the global options in $STORAGE_ROOT/yiimp/.yiimp.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
DaemonInternalIP='"${NewDaemonInternalIP}"'
DaemonUser='"${NewDaemonUser}"'
DaemonPass='"'"''"${NewDaemonPass}"''"'"'
# Unless you do some serious modifications this installer will not work with any other repo of yiimp!
YiiMPRepo='https://github.com/cryptopool-builders/yiimp.git'
' | sudo -E tee $STORAGE_ROOT/yiimp/.$generate.conf >/dev/null 2>&1

# Copy the new config to a static Name
if [ -f $STORAGE_ROOT/yiimp/.newconf.conf ]; then
  sudo rm -r $STORAGE_ROOT/yiimp/.newconf.conf
  sudo cp -r $STORAGE_ROOT/yiimp/.$generate.conf $STORAGE_ROOT/yiimp/.newconf.conf
else
  sudo cp -r $STORAGE_ROOT/yiimp/.$generate.conf $STORAGE_ROOT/yiimp/.newconf.conf
fi
