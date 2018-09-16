#####################################################
# Code from https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
# Updated by cryptopool.builders for crypto use...
#####################################################

#----------------------------------------------------------------------
# Set up values.
#----------------------------------------------------------------------

source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

# User credentials for the remote server.
StratumUser=$StratumUser
StratumPass=$StratumPass
dir=$HOME

# The server hostname.
StratumServer=$StratumInternalIP

# The script to run on the remote server.
script_system_stratum=${dir}'/multipool/yiimp_multi/remote_system_stratum_server.sh'
script_stratum=${dir}'/multipool/yiimp_multi/remote_stratum.sh'
script_ssh=${dir}'/multipool/yiimp_multi/ssh.sh'

# Additional files that need to be copied to the remote server
conf=${STORAGE_ROOT}'/yiimp/.yiimp.conf'
screens=${dir}'/multipool/yiimp_multi/ubuntu/stratum/screens'
header=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/stratum/00-header'
sysinfo=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/stratum/10-sysinfo'
footer=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/stratum/90-footer'

# Desired location of the script on the remote server.
remote_system_stratum_path='/tmp/remote_system_stratum_server.sh'
remote_stratum_path='/tmp/remote_stratum.sh'
remote_ssh_path='/tmp/ssh.sh'

#----------------------------------------------------------------------
# Create a temp script to echo the SSH password, used by SSH_ASKPASS
#----------------------------------------------------------------------

SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${StratumPass}"
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
B64_system=`base64 --wrap=0 ${script_system_stratum}`
B64_stratum=`base64 --wrap=0 ${script_stratum}`
B64_ssh=`base64 --wrap=0 ${script_ssh}`

# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.

system_stratum="base64 -d - > ${remote_system_stratum_path} <<< ${B64_system};"
system_stratum="${system_stratum} chmod u+x ${remote_system_stratum_path};"
system_stratum="${system_stratum} sh -c 'nohup ${remote_system_stratum_path}'"

stratum="base64 -d - > ${remote_stratum_path} <<< ${B64_stratum};"
stratum="${stratum} chmod u+x ${remote_stratum_path};"
stratum="${stratum} sh -c 'nohup ${remote_stratum_path}'"

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_ssh};"
ssh="${ssh} chmod u+x ${remote_ssh_path};"
ssh="${ssh} sh -c 'nohup ${remote_ssh_path} > /dev/null 2>&1 &'"

# Log in to the remote server and run the above command.

# Copy needed files to remote server
cat $conf | setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} 'cat > /tmp/.yiimp.conf'
cat $screens | setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} 'cat > /tmp/screens'
cat $header | setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} 'cat > /tmp/00-header'
cat $sysinfo | setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} 'cat > /tmp/10-sysinfo'
cat $footer | setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} 'cat > /tmp/90-footer'

# Execute scripts on remote server
setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} "${system_stratum}"
setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} "${stratum}"
setsid ssh ${SSH_OPTIONS} ${StratumUser}@${StratumServer} "${ssh}"
