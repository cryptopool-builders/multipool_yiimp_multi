#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

if [ -f "$STORAGE_ROOT/yiimp/.wireguard_public.conf" ]; then
  source "$STORAGE_ROOT/yiimp/.wireguard_public.conf"
else
  wireguard='false'
fi

# Get the IP addresses of the local network interface(s).
if [ -z "${NewStratumInternalIP:-}" ]; then
DEFAULT_NewStratumInternalIP='10.0.0.x'
input_box "Stratum Server Private IP" \
"Enter the private IP address of the Stratum Server, as given to you by your provider.
\n\nIf you do not have one from your provider enter the IP you assigned with Wireguard.
\n\nPrivate IP address:" \
$DEFAULT_NewStratumInternalIP \
NewStratumInternalIP

if [ -z "$NewStratumInternalIP" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "${NewStratumUser:-}" ]; then
DEFAULT_NewStratumUser='yiimpadmin'
input_box "Stratum Server User Name" \
"Enter the user name of the Stratum Server.
\n\nThis is required for setup to complete.
\n\nStratum Server User Name:" \
$DEFAULT_NewStratumUser \
NewStratumUser

if [ -z "$NewStratumUser" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "${NewStratumPass:-}" ]; then
DEFAULT_NewStratumPass='password'
input_box "Stratum Server User Password" \
"Enter the user password of the Stratum Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nStratum Server User Password:" \
$DEFAULT_NewStratumPass \
NewStratumPass

if [ -z "$NewStratumPass" ]; then
user hit ESC/cancel
exit
fi
fi

if [[ ("$UsingDomain" == "yes") ]]; then
if [ -z "${NewStratumURL:-}" ]; then
DEFAULT_NewStratumURL=stratum.$DomainName
input_box "Stratum URL" \
"Enter your stratum URL. It is recommended to use another subdomain such as stratum.$DomainName
\n\nDo not add www. to the domain name.
\n\nStratum URL:" \
$DEFAULT_NewStratumURL \
NewStratumURL

if [ -z "$NewStratumURL" ]; then
# user hit ESC/cancel
exit
fi
fi

else
NewStratumURL=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi

if [ -z "${blckntifypass:-}" ]; then
DEFAULT_blckntifypass=blocknotifypassword
input_box "Blocknotify Password" \
"Enter the existing blocknotify password from the first stratum server.
\n\nTo get this log in to your first stratum server and type:
\n\ncat /home/crypto-data/yiimp/site/stratum/config/a5a.conf
\n\nThe blocknotify password is the first password in the TCP section.
\n\nRemember to shift + right click to paste!
\n\nBlocknotify Password:" \
$DEFAULT_blckntifypass \
blckntifypass

if [ -z "$blckntifypass" ]; then
# user hit ESC/cancel
exit
fi
fi

dialog --title "Use AutoExchange" \
--yesno "Would you like the stratum to be built with autoexchange enabled?" 7 60
response=$?
case $response in
   0) AutoExchange=yes;;
   1) AutoExchange=no;;
   255) echo "[ESC] key pressed.";;
esac

#Generate random conf file name, random StratumDBUser and StratumDBPassword
# To increase security we are now randonly generating the yiimpfrontend DB name, panel, and stratum user names. So each installation is more secure.
# We do it here to save the variables in the global .yiimp.conf file
generate=$(openssl rand -base64 9 | tr -d "=+/")
StratumDBUser=Stratum$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')
StratumUserDBPassword=$(openssl rand -base64 29 | tr -d "=+/")

# Save the global options in $STORAGE_ROOT/yiimp/.yiimp.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'

UsingDomain='"${UsingDomain}"'
DomainName='"${DomainName}"'
StratumURL='"${NewStratumURL}"'
AutoExchange='"${AutoExchange}"'
blckntifypass='"${blckntifypass}"'

DBInternalIP='"${DBInternalIP}"'
StratumUser='"${NewStratumUser}"'
StratumPass='"'"''"${NewStratumPass}"''"'"'
StratumInternalIP='"${NewStratumInternalIP}"'

YiiMPDBName='"${YiiMPDBName}"'
DBRootPassword='"'"''"${DBRootPassword}"''"'"'
StratumDBUser='"'"''"${StratumDBUser}"''"'"'
StratumUserDBPassword='"'"''"${StratumUserDBPassword}"''"'"'

wireguard='"'"''"${wireguard}"''"'"'

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
