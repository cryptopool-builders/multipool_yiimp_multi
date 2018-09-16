#----------------------------------------------------------------------
# Set up values.
#----------------------------------------------------------------------
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
# User credentials for the remote server.
DaemonUser=$DaemonUser
DaemonPass=$DaemonPass
dir=$HOME

# The server hostname.
DaemonServer=$DaemonInternalIP
 
# The script to run on the remote server.
script_daemon=${dir}'/multipool/yiimp_multi/remote_daemon.sh'
script_ssh=${dir}'/multipool/yiimp_multi/ssh.sh'

# Additional files that need to be copied to the remote server
conf=${STORAGE_ROOT}'/yiimp/.yiimp.conf'
screens=${dir}'/multipool/yiimp_multi/ubuntu/screens'
header=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/00-header'
sysinfo=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/10-sysinfo'
footer=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/90-footer'

# Desired location of the script on the remote server.
remote_daemon_path='/tmp/remote_daemon.sh'
remote_ssh_path='/tmp/ssh.sh'
 
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
B64_daemon=`base64 --wrap=0 ${script_daemon}`
B64_ssh=`base64 --wrap=0 ${script_ssh}`
 
# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.
daemon="base64 -d - > ${remote_daemon_path} <<< ${B64_daemon};"
daemon="${daemon} chmod u+x ${remote_daemon_path};"
daemon="${daemon} sh -c 'nohup ${remote_daemon_path}'"

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_ssh};"
ssh="${ssh} chmod u+x ${remote_ssh_path};"
ssh="${ssh} sh -c 'nohup ${remote_ssh_path} > /dev/null 2>&1 &'"
 
# Log in to the remote server and run the above command.

# Copy needed files to remote server
cat $conf | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/.yiimp.conf'
cat $screens | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/screens'
cat $header | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/00-header'
cat $sysinfo | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/10-sysinfo'
cat $footer | setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} 'cat > /tmp/90-footer'

# Execute scripts on remote server
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${daemon}"
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${ssh}"
