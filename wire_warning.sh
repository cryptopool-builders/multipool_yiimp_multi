#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

message_box "Ultimate Crypto-Server Setup Installer" \
"You have choosen to install Wireguard on additional server(s)!
\n\nIf you are setting up this server at a later time from your initial installation, you must log in to your DB server and type:
\n\ncat ${STORAGE_ROOT}/yiimp/.wireguard_public.conf
\n\nYou will be prompted for that information during this installation.
\n\nThe last IP that was automatically assigned is 10.0.0.5, you will need to manually adjust the IP for each new server you add.
\n\nFor example 10.0.0.6 - new server 1, 10.0.0.7 - new server 2, etc. You will need to keep track of the IPs you use!
\n\nYou must also login to each previously installed server in your cluster after this setup completes and type the following command:
\n\ncat ${STORAGE_ROOT}/yiimp/.wireguard_command.conf
\n\nThe output must be copied from those previously installed servers and ran on each new server you setup! Only run that command on the NEW servers.
\n\nThe command given at the end of this installation is the command you run on each of the previous servers.
\n\n
\n\nIf you are setting up all of your servers for the first time at the same time, you do not need to run the above commmands. Since the information is already being displayed."
