#----------------------------------------------------------------------
# Set up values.
#----------------------------------------------------------------------
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
# User credentials for the remote server.
WebUser=$WebUser
WebPass=$WebPass
 
# The server hostname.
WebServer=$WebInternalIP
 
# The scripts to run on the remote server.
script_system_web='$HOME/multipool/yiimp_multi/remote_system_web_server.sh'
script_web_web='$HOME/multipool/yiimp_multi/remote_web_web_server.sh'
script_nginx_web='$HOME/multipool/yiimp_multi/nginx_upgrade.sh'
script_clean_web='$HOME/multipool/yiimp_multi/server_cleanup.sh'
script_motd_web='$HOME/multipool/yiimp_multi/motd.sh'
script_harden_web='$HOME/multipool/yiimp_multi/server_harden.sh'
script_ssh='$HOME/multipool/yiimp_multi/ssh.sh'
# Additional files that need to be copied to the remote server
conf='$STORAGE_ROOT/yiimp/.yiimp.conf'
screens='$HOME/multipool/yiimp_multi/ubuntu/screens'
00-header='$HOME/multipool/yiimp_multi/ubuntu/etc/update-motd.d/00-header'
10-sysinfo='$HOME/multipool/yiimp_multi/ubuntu/etc/update-motd.d/10-sysinfo'
90-footer='$HOME/multipool/yiimp_multi/ubuntu/etc/update-motd.d/90-footer'

# Desired location of the scripts on the remote server.
remote_system_web_path='/tmp/remote_system_web_server.sh'
remote_web_web_path='/tmp/remote_web_web_server.sh'
remote_nginx_web_path='/tmp/nginx_upgrade.sh'
remote_clean_web_path='/tmp/server_cleanup.sh'
remote_motd_web_path='/tmp/motd.sh'
remote_harden_web_path='/tmp/server_harden.sh'
remote_ssh_path='/tmp/ssh.sh'

# Desired location of additional files
remot_conf_path='/tmp'
remot_screens_path='/tmp'
remot_00-header_path='/tmp'
remot_10-sysinfo_path='/tmp'
remot_90-footer_path='/tmp'
 
#----------------------------------------------------------------------
# Create a temp script to echo the SSH password, used by SSH_ASKPASS
#----------------------------------------------------------------------
 
SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${WebPass}"
EOL
chmod u+x ${SSH_ASKPASS_SCRIPT}
 
#----------------------------------------------------------------------
# Set up other items needed for OpenSSH to work.
#----------------------------------------------------------------------
 
# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
export DISPLAY=:0
 
# Tell SSH to read in the output of the provided script as the password.
# We still have to use setsid to eliminate access to a terminal and thus avoid
# it ignoring this and asking for a password.
export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}
 
# LogLevel error is to suppress the hosts warning. The others are
# necessary if working with development servers with self-signed
# certificates.
SSH_OPTIONS="-oLogLevel=error"
SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"
 
#----------------------------------------------------------------------
# Run the script on the remote server.
#----------------------------------------------------------------------
 
# Load in a base 64 encoded version of the script.
B64_SCRIPT=`base64 --wrap=0 ${script_system_web}`
B64_SCRIPT=`base64 --wrap=0 ${script_web_web}`
B64_SCRIPT=`base64 --wrap=0 ${script_ssh}`
 
# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.
system_web="base64 -d - > ${remote_system_web_path} <<< ${B64_SCRIPT};"
system_web="${CMD} chmod u+x ${remote_system_web_path};"
system_web="${CMD} sh -c 'nohup ${remote_system_web_path}'

web_web="base64 -d - > ${remote_web_web_path} <<< ${B64_SCRIPT};"
web_web="${CMD} chmod u+x ${remote_web_web_path};"
web_web="${CMD} sh -c 'nohup ${remote_web_web_path}'

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_SCRIPT};"
ssh="${CMD} chmod u+x ${remote_ssh_path};"
ssh="${CMD} sh -c 'nohup ${remote_ssh_path}'
 
# Log in to the remote server and run the above command.
# The use of setsid is a part of the machinations to stop ssh
# prompting for a password.
setsid scp ${conf} ${WebUser}@${WebServer}:${remot_conf_path}
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${system_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${web_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${ssh} > /dev/null 2>&1 &'"
