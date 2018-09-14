source $STORAGE_ROOT/yiimp/.wireguard.conf

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
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  echo Copy this and paste this key when prompted, $mypublic

elif [[ ("$server_type" == "dbshared") ]]; then
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  clear
  mypublic="$(sudo cat /etc/wireguard/publickey)"
  echo Copy this and paste this key when prompted, $mypublic

elif [[ ("$server_type" == "web") ]]; then
  source $STORAGE_ROOT/yiimp/.yiimp.conf
  echo "ListenPort = 6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "SaveConfig = true" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Address = ${WebInternalIP}/32" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "[Peer]" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "PublicKey = ${DBPublicKey}" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "AllowedIPs = ${DBInternalIP}/24" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  echo "Endpoint = ${DBServerIP}:6121" | hide_output sudo tee -a /etc/wireguard/wg0.conf
  cd $HOME
  sudo systemctl start wg-quick@wg0
  sudo systemctl enable wg-quick@wg0
  clear
  webinternal=$WebInternalIP
  webpublic=$WebServerIP
echo "Copy this command and run it on the DB Server, Stratum Server, and Daemon Server"
echo "sudo wg set wg0 peer ${mypublic} endpoint ${webpublic}:6121 allowed-ips ${webinternal}/32"

elif [[ ("$server_type" == "stratum") ]]; then
  source $STORAGE_ROOT/yiimp/.yiimp.conf
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
  clear
  stratinternal=$StratumInternalIP
  stratpublic=$StratumServerIP
echo "Copy this command and run it on the DB Server, Web Server, and Daemon Server"
echo "sudo wg set wg0 peer ${mypublic} endpoint ${stratpublic}:6121 allowed-ips ${stratinternal}/32"

elif [[ ("$server_type" == "daemon") ]]; then
  source $STORAGE_ROOT/yiimp/.yiimp.conf
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
  clear
  daemoninternal=$DaemonInternalIP
  daemonpublic=$DaemonServerIP
echo "Copy this command and run it on the DB Server, Web Server, and Stratum Server"
echo "sudo wg set wg0 peer ${mypublic} endpoint ${daemonpublic}:6121 allowed-ips ${daemoninternal}/32"
fi

exit 0
