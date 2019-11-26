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
WebUser=${WebUser}
WebPass="${WebPass}"
dir=$HOME

# The server hostname.
WebServer=${WebInternalIP}

# The scripts to run on the remote server.
script_create_user=${dir}'/multipool/yiimp_multi/create_user_remote.sh'
script_system_web=${dir}'/multipool/yiimp_multi/remote_system_web_server.sh'
script_self_ssl=${dir}'/multipool/yiimp_multi/self_ssl.sh'
script_web_web=${dir}'/multipool/yiimp_multi/remote_web_web_server.sh'
script_nginx_web=${dir}'/multipool/yiimp_multi/nginx_upgrade.sh'
script_clean_web=${dir}'/multipool/yiimp_multi/server_cleanup.sh'
script_sendmail_web=${dir}'/multipool/yiimp_multi/send_mail.sh'
script_motd_web=${dir}'/multipool/yiimp_multi/motd.sh'
script_harden_web=${dir}'/multipool/yiimp_multi/server_harden.sh'
script_ssh=${dir}'/multipool/yiimp_multi/ssh.sh'

# Additional files that need to be copied to the remote server
functioncopy=${dir}'/multipool/yiimp_multi/required_remote_files/functions.sh'
conf=${STORAGE_ROOT}'/yiimp/.yiimp.conf'
screens=${dir}'/multipool/yiimp_multi/ubuntu/screens'
header=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/00-header'
sysinfo=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/10-sysinfo'
footer=${dir}'/multipool/yiimp_multi/ubuntu/etc/update-motd.d/90-footer'
first_boot=${dir}'/multipool/yiimp_multi/first_boot.sh'
nginx_conf=${dir}'/multipool/yiimp_multi/nginx_confs/nginx.conf'
nginx_general=${dir}'/multipool/yiimp_multi/nginx_confs/general.conf'
nginx_letsencrypt=${dir}'/multipool/yiimp_multi/nginx_confs/letsencrypt.conf'
nginx_php=${dir}'/multipool/yiimp_multi/nginx_confs/php_fastcgi.conf'
nginx_security=${dir}'/multipool/yiimp_multi/nginx_confs/security.conf'
nginx_domain_nonssl=${dir}'/multipool/yiimp_multi/nginx_domain_nonssl.sh'
nginx_domain_ssl=${dir}'/multipool/yiimp_multi/nginx_domain_ssl.sh'
nginx_subdomain_nonssl=${dir}'/multipool/yiimp_multi/nginx_subdomain_nonssl.sh'
nginx_subdomain_ssl=${dir}'/multipool/yiimp_multi/nginx_subdomain_ssl.sh'
yiimp_conf=${dir}'/multipool/yiimp_multi/yiimp_confs/yiimpserverconfig.sh'
yiimp_blocks=${dir}'/multipool/yiimp_multi/yiimp_confs/blocks.sh'
yiimp_keys=${dir}'/multipool/yiimp_multi/yiimp_confs/keys.sh'
yiimp_loop2=${dir}'/multipool/yiimp_multi/yiimp_confs/loop2.sh'
yiimp_main=${dir}'/multipool/yiimp_multi/yiimp_confs/main.sh'

# Desired location of the scripts on the remote server.
remote_create_user_path='/tmp/create_user_remote.sh'
remote_system_web_path='/tmp/remote_system_web_server.sh'
remote_self_ssl_path='/tmp/self_ssl.sh'
remote_web_web_path='/tmp/remote_web_web_server.sh'
remote_nginx_web_path='/tmp/nginx_upgrade.sh'
remote_clean_web_path='/tmp/server_cleanup.sh'
remote_sendmail_web_path='/tmp/send_mail.sh'
remote_motd_web_path='/tmp/motd.sh'
remote_harden_web_path='/tmp/server_harden.sh'
remote_ssh_path='/tmp/ssh.sh'

#----------------------------------------------------------------------
# Create a temp script to echo the SSH password, used by SSH_ASKPASS
#----------------------------------------------------------------------

SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/usr/bin/env bash
echo '${WebPass}'
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
B64_system=`base64 --wrap=0 ${script_system_web}`
B64_ssl=`base64 --wrap=0 ${script_self_ssl}`
B64_mail=`base64 --wrap=0 ${script_sendmail_web}`
B64_web=`base64 --wrap=0 ${script_web_web}`
B64_nginx=`base64 --wrap=0 ${script_nginx_web}`
B64_clean=`base64 --wrap=0 ${script_clean_web}`
B64_motd=`base64 --wrap=0 ${script_motd_web}`
B64_harden=`base64 --wrap=0 ${script_harden_web}`
B64_ssh=`base64 --wrap=0 ${script_ssh}`

# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.

system_user="base64 -d - > ${remote_create_user_path} <<< ${B64_user};"
system_user="${system_user} chmod u+x ${remote_create_user_path};"
system_user="${system_user} sh -c 'nohup ${remote_create_user_path}'"

system_web="base64 -d - > ${remote_system_web_path} <<< ${B64_system};"
system_web="${system_web} chmod u+x ${remote_system_web_path};"
system_web="${system_web} sh -c 'nohup ${remote_system_web_path}'"

system_ssl="base64 -d - > ${remote_self_ssl_path} <<< ${B64_ssl};"
system_ssl="${system_ssl} chmod u+x ${remote_self_ssl_path};"
system_ssl="${system_ssl} sh -c 'nohup ${remote_self_ssl_path}'"

web_web="base64 -d - > ${remote_web_web_path} <<< ${B64_web};"
web_web="${web_web} chmod u+x ${remote_web_web_path};"
web_web="${web_web} sh -c 'nohup ${remote_web_web_path}'"

nginx_web="base64 -d - > ${remote_nginx_web_path} <<< ${B64_nginx};"
nginx_web="${nginx_web} chmod u+x ${remote_nginx_web_path};"
nginx_web="${nginx_web} sh -c 'nohup ${remote_nginx_web_path}'"

clean_web="base64 -d - > ${remote_clean_web_path} <<< ${B64_clean};"
clean_web="${clean_web} chmod u+x ${remote_clean_web_path};"
clean_web="${clean_web} sh -c 'nohup ${remote_clean_web_path}'"

motd_web="base64 -d - > ${remote_motd_web_path} <<< ${B64_motd};"
motd_web="${motd_web} chmod u+x ${remote_motd_web_path};"
motd_web="${motd_web} sh -c 'nohup ${remote_motd_web_path}'"

harden_web="base64 -d - > ${remote_harden_web_path} <<< ${B64_harden};"
harden_web="${harden_web} chmod u+x ${remote_harden_web_path};"
harden_web="${harden_web} sh -c 'nohup ${remote_harden_web_path}'"

system_mail="base64 -d - > ${remote_sendmail_web_path} <<< ${B64_mail};"
system_mail="${system_mail} chmod u+x ${remote_sendmail_web_path};"
system_mail="${system_mail} sh -c 'nohup ${remote_sendmail_web_path}'"

ssh="base64 -d - > ${remote_ssh_path} <<< ${B64_ssh};"
ssh="${ssh} chmod u+x ${remote_ssh_path};"
ssh="${ssh} sh -c 'nohup ${remote_ssh_path} > /dev/null 2>&1 &'"

# Log in to the remote server and run the above commands.

# Copy needed files to remote server
cat $conf | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/functions.sh'
cat $conf | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/.yiimp.conf'
cat $screens | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/screens'
cat $header | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/00-header'
cat $sysinfo | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/10-sysinfo'
cat $footer | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/90-footer'
cat $first_boot | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/first_boot.sh'
cat $nginx_conf | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/nginx.conf'
cat $nginx_general | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/general.conf'
cat $nginx_letsencrypt | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/letsencrypt.conf'
cat $nginx_php | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/php_fastcgi.conf'
cat $nginx_security | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/security.conf'
cat $nginx_domain_nonssl | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/nginx_domain_nonssl.sh'
cat $nginx_domain_ssl | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/nginx_domain_ssl.sh'
cat $nginx_subdomain_nonssl | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/nginx_subdomain_nonssl.sh'
cat $nginx_subdomain_ssl | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/nginx_subdomain_ssl.sh'
cat $yiimp_conf | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/yiimpserverconfig.sh'
cat $yiimp_blocks | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/blocks.sh'
cat $yiimp_keys | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/keys.sh'
cat $yiimp_loop2 | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/loop2.sh'
cat $yiimp_main | setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} 'cat > /tmp/main.sh'

# Execute scripts on remote server
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${system_user}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${system_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${system_ssl}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${web_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${nginx_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${clean_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${system_mail}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${motd_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${harden_web}"
setsid ssh ${SSH_OPTIONS} ${WebUser}@${WebServer} "${ssh}"

cd $HOME/multipool/yiimp_multi
