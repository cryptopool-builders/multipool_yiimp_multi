#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

message_box "Ultimate Crypto-Server Setup Installer" \
"You have choosen to install Wireguard on additional server(s)!
\n\nBefore you can continue you must log in to your DB server to and type the following command:
\n\n
\n\ncat $STORAGE_ROOT/yiimp/.wireguard_public.conf
\n\n
\n\nYou will be prompted for this information during the install.
\n\nThe last IP that was automatically assigned is 10.0.0.5, you will need to manually adjust the IP for each new server.
\n\nFor example 10.0.0.6 - new server 1, 10.0.0.7 - new server 2, etc. You will need to keep track of the IPs you use!
\n\n
\n\nYou must also login to each additional server after setup and type the following command:
\n\n
\n\ncat $STORAGE_ROOT/yiimp/.wireguard_command.conf
\n\n
\n\nThe output must be copied from each server and ran on your new server(s)!"
