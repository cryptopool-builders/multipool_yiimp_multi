#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

# Get the IP addresses of the local network interface(s).
if [ -z "$StratumInternalIP" ]; then
DEFAULT_StratumInternalIP='10.0.0.x'
input_box "Stratum Server Private IP" \
"Enter the private IP address of the Stratum Server, as given to you by your provider.
\n\nIf you do not have one from your provider enter the IP you assigned with Wireguard.
\n\nPrivate IP address:" \
$DEFAULT_StratumInternalIP \
StratumInternalIP

if [ -z "$StratumInternalIP" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "$StratumUser" ]; then
DEFAULT_StratumUser='yiimpadmin'
input_box "Stratum Server User Name" \
"Enter the user name of the Stratum Server.
\n\nThis is required for setup to complete.
\n\nStratum Server User Name:" \
$DEFAULT_StratumUser \
StratumUser

if [ -z "$StratumUser" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "$StratumPass" ]; then
DEFAULT_StratumPass='password'
input_box "Stratum Server User Password" \
"Enter the user password of the Stratum Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nStratum Server User Password:" \
$DEFAULT_StratumPass \
StratumPass

if [ -z "$StratumPass" ]; then
user hit ESC/cancel
exit
fi
fi

if [ -z "$StratumURL" ]; then
DEFAULT_StratumURL=stratum.$DomainName
input_box "Stratum URL" \
"Enter your stratum URL. It is recommended to use another subdomain such as stratum.$DomainName
\n\nDo not add www. to the domain name.
\n\nStratum URL:" \
$DEFAULT_StratumURL \
StratumURL

if [ -z "$StratumURL" ]; then
# user hit ESC/cancel
exit
fi
fi

#Generate random conf file name, random StratumDBUser and StratumDBPassword
generate=$(openssl rand -base64 9 | tr -d "=+/")
StratumDBUser=$(openssl rand -base64 9 | tr -d "=+/")
StratumUserDBPassword=$(openssl rand -base64 29 | tr -d "=+/")

# Save the global options in $STORAGE_ROOT/yiimp/.yiimp.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
DomainName='"${DomainName}"'
StratumURL='"${StratumURL}"'
DBRootPassword='"'"''"${DBRootPassword}"''"'"'
StratumDBUser='"'"''"${StratumDBUser}"''"'"'
StratumUserDBPassword='"'"''"${StratumUserDBPassword}"''"'"'
StratumInternalIP='"${StratumInternalIP}"'
StratumUser='"${StratumUser}"'
StratumPass='"'"''"${StratumPass}"''"'"'
# Unless you do some serious modifications this installer will not work with any other repo of yiimp!
YiiMPRepo='https://github.com/cryptopool-builders/yiimp.git'
' | sudo -E tee $STORAGE_ROOT/yiimp/.$generate.conf >/dev/null 2>&1

newconf=$STORAGE_ROOT/yiimp/.$generate.conf
