#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source $STORAGE_ROOT/yiimp/.wireguard.conf
source /etc/multipool.conf

sudo add-apt-repository ppa:wireguard/wireguard -y
sudo apt-get update -y
sudo apt-get install wireguard-dkms wireguard-tools -y

(umask 077 && printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null)
wg genkey | sudo tee -a /etc/wireguard/wg0.conf | wg pubkey | sudo tee /etc/wireguard/publickey

if [[ ("$server_type" == "db") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  dbpublic=${PUBLIC_IP}
  mypublic="$(sudo cat /etc/wireguard/publickey)"

  echo 'Public Ip: '"${dbpublic}"'
  Public Key: '"${mypublic}"'
  wireguard='true'
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo Please begin the Wireguard installation on your other servers...
  echo
  echo The public IP of this box is,  $dbpublic
  echo
  echo The Public key of this box is, $mypublic
  echo

elif [[ ("$server_type" == "dbshared") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  dbpublic=${PUBLIC_IP}
  mypublic="$(sudo cat /etc/wireguard/publickey)"

  echo 'Public Ip: '"${dbpublic}"'
  Public Key: '"${mypublic}"'
  wireguard='true'
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo Please begin the Wireguard installation on your other servers...
  echo
  echo The public IP of this box is,  $dbpublic
  echo
  echo The Public key of this box is, $mypublic
  echo

elif [[ ("$server_type" == "web") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${WebInternalIP}/32" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "[Peer]" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "PublicKey = ${DBPublicKey}" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Endpoint = ${DBServerIP}:6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  hide_output sudo systemctl start wg-quick@wg0
  hide_output sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  webinternal=${WebInternalIP}
  webpublic=${PUBLIC_IP}
  clear

  echo 'sudo wg set wg0 peer '"${mypublic}"' endpoint '"${webpublic}"':6121 allowed-ips '"${webinternal}"'/32
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_command.conf >/dev/null 2>&1;
  echo 'wireguard=true
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo "Copy this command and run it on the DB Server, Stratum Server, and Daemon Server"
  echo
  echo "sudo wg set wg0 peer ${mypublic} endpoint ${webpublic}:6121 allowed-ips ${webinternal}/32"
  echo
  echo

elif [[ ("$server_type" == "stratum") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${StratumInternalIP}/32" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "[Peer]" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "PublicKey = ${DBPublicKey}" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Endpoint = ${DBServerIP}:6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  stratinternal=${StratumInternalIP}
  stratpublic=${PUBLIC_IP}
  clear

  echo 'sudo wg set wg0 peer '"${mypublic}"' endpoint '"${stratpublic}"':6121 allowed-ips '"${stratinternal}"'/32
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_command.conf >/dev/null 2>&1;
  echo 'wireguard=true
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo "Copy this command and run it on the DB Server, Web Server, and Daemon Server"
  echo
  echo "sudo wg set wg0 peer ${mypublic} endpoint ${stratpublic}:6121 allowed-ips ${stratinternal}/32"
  echo
  echo

elif [[ ("$server_type" == "additional") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${AdditionalInternalIP}/32" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "[Peer]" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "PublicKey = ${DBPublicKey}" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Endpoint = ${DBServerIP}:6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  additionalinternal=${AdditionalInternalIP}
  additionalpublic=${PUBLIC_IP}
  clear

  echo 'sudo wg set wg0 peer '"${mypublic}"' endpoint '"${additionalpublic}"':6121 allowed-ips '"${additionalinternal}"'/32
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_command.conf >/dev/null 2>&1;
  echo 'wireguard=true
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo "Copy this command and run it on the DB Server, Web Server, and Daemon Server, any other additional servers"
  echo
  echo "sudo wg set wg0 peer ${mypublic} endpoint ${additionalpublic}:6121 allowed-ips ${additionalinternal}/32"
  echo
  echo

elif [[ ("$server_type" == "daemon") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${DaemonInternalIP}/32" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "[Peer]" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "PublicKey = ${DBPublicKey}" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Endpoint = ${DBServerIP}:6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  sudo ufw allow 6121
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  daemoninternal=${DaemonInternalIP}
  daemonpublic=${PUBLIC_IP}
  clear

  echo 'sudo wg set wg0 peer '"${mypublic}"' endpoint '"${daemonpublic}"':6121 allowed-ips '"${daemoninternal}"'/32
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_command.conf >/dev/null 2>&1;
  echo 'wireguard=true
  ' | sudo -E tee $STORAGE_ROOT/yiimp/.wireguard_public.conf >/dev/null 2>&1;

  echo "Copy this command and run it on the DB Server, Web Server, and Stratum Server"
  echo
  echo "sudo wg set wg0 peer ${mypublic} endpoint ${daemonpublic}:6121 allowed-ips ${daemoninternal}/32"
  echo
  echo
fi

echo
echo "After installing Wireguard on all of your servers run, multipool from the DB server only!!"
exit 0
