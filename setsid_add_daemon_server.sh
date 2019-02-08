#####################################################
# Code from https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
# Updated by cryptopool.builders for crypto use...
#####################################################

#----------------------------------------------------------------------
# Set up values.
#----------------------------------------------------------------------
clear
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.newconf.conf
# User credentials for the remote server.
DaemonUser=${DaemonUser}
DaemonPass="${DaemonPass}"
dir=$HOME

# The server hostname.
DaemonServer=${DaemonInternalIP}

# The script to run on the remote server.
script_create_user=${dir}'/multipool/yiimp_multi/create_user_remote.sh'
script_daemon=${dir}'/multipool/yiimp_multi/remote_daemon.sh'
script_motd_web=${dir}'/multipool/yiimp_multi/motd.sh'
script_harden_web=${dir}'/multipool/yiimp_multi/server_harden.sh'
script_ssh=${dir}'/multipool/yiimp_multi/ssh.sh'

# Additional files that need to be copied to the remote server
functioncopy=${dir}'/multipool/yiimp_multi/required_remote_files/functions.sh'
conf=${STORAGE_ROOT}'/yiimp/.yiimp.conf'
screens=${dir}'/multipool/yiimp_multi/ubuntu/screens'
header=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/daemon/00-header'
sysinfo=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/daemon/10-sysinfo'
footer=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/daemon/90-footer'

# Desired location of the script on the remote server.
remote_create_user_path='/tmp/create_user_remote.sh'
remote_daemon_path='/tmp/remote_daemon.sh'
remote_motd_web_path='/tmp/motd.sh'
remote_harden_web_path='/tmp/server_harden.sh'
remote_ssh_path='/tmp/ssh.sh'

#----------------------------------------------------------------------
# Create a temp script to echo the SSH password, used by SSH_ASKPASS
#----------------------------------------------------------------------

SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/usr/bin/env bash
echo '${DaemonPass}'
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

B64_user=`base64 --wrap=0 ${script_create_user}`
B64_daemon=`base64 --wrap=0 ${script_daemon}`
B64_motd=`base64 --wrap=0 ${script_motd_web}`
B64_harden=`base64 --wrap=0 ${script_harden_web}`
B64_ssh=`base64 --wrap=0 ${script_ssh}`

# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.

system_user="base64 -d - > ${remote_create_user_path} <<< ${B64_user};"
system_user="${system_user} chmod u+x ${remote_create_user_path};"
system_user="${system_user} sh -c 'nohup ${remote_create_user_path}'"

daemon="base64 -d - > ${remote_daemon_path} <<< ${B64_daemon};"
daemon="${daemon} chmod u+x ${remote_daemon_path};"
daemon="${daemon} sh -c 'nohup ${remote_daemon_path}'"

motd_web="base64 -d - > ${remote_motd_web_path} <<< ${B64_motd};"
motd_web="${motd_web} chmod u+x ${remote_motd_web_path};"
motd_web="${motd_web} sh -c 'nohup ${remote_motd_web_path}'"

harden_web="base64 -d - > ${remote_harden_web_path} <<< ${B64_harden};"
harden_web="${harden_web} chmod u+x ${remote_harden_web_path};"
harden_web="${harden_web} sh -c 'nohup ${remote_harden_web_path}'"

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_ssh};"
ssh="${ssh} chmod u+x ${remote_ssh_path};"
ssh="${ssh} sh -c 'nohup ${remote_ssh_path} > /dev/null 2>&1 &'"

# Log in to the remote server and run the above command.

# Copy needed files to remote server

cat $functioncopy | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/functions.sh'
cat $conf | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/.yiimp.conf'
cat $screens | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/screens'
cat $header | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/00-header'
cat $sysinfo | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/10-sysinfo'
cat $footer | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/90-footer'

# Execute scripts on remote server

setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${system_user}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${daemon}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${motd_web}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${harden_web}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${ssh}"
