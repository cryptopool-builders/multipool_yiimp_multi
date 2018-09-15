#----------------------------------------------------------------------
# Set up values.
#----------------------------------------------------------------------
source /etc/multipool.conf
$STORAGE_ROOT/yiimp/.yiimp.conf
# User credentials for the remote server.
DaemonUser=$DaemonUser
DaemonPass=$DaemonPass
 
# The server hostname.
DaemonServer=$DaemonInternalIP
 
# The script to run on the remote server.
script_daemon='$HOME/multipool/yiimp_multi/remote_daemon.sh'
script_ssh=''$HOME/multipool/yiimp_multi/ssh.sh'
conf='$STORAGE_ROOT/yiimp/.yiimp.conf'
# Desired location of the script on the remote server.
remote_daemon_path='/tmp/remote_daemon.sh'
remote_ssh_path='/tmp/ssh.sh'
remot_conf_path='/tmp'
 
#----------------------------------------------------------------------
# Create a temp script to echo the SSH password, used by SSH_ASKPASS
#----------------------------------------------------------------------
 
SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${DaemonPass}"
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
B64_SCRIPT=`base64 --wrap=0 ${script_daemon}`
B64_SCRIPT=`base64 --wrap=0 ${script_ssh}`
 
# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.
daemon="base64 -d - > ${remote_daemon_path} <<< ${B64_SCRIPT};"
daemon="${CMD} chmod u+x ${remote_daemon_path};"
daemon="${CMD} sh -c 'nohup ${remote_daemon_path}'

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_SCRIPT};"
ssh="${CMD} chmod u+x ${remote_ssh_path};"
ssh="${CMD} sh -c 'nohup ${remote_ssh_path}'
 
# Log in to the remote server and run the above command.
# The use of setsid is a part of the machinations to stop ssh
# prompting for a password.
setsid scp ${conf} ${WebUser}@${WebServer}:${remot_conf_path}
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${daemon}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${ssh} > /dev/null 2>&1 &'"
