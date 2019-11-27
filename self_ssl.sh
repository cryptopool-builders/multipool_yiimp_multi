#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

# Installs self signed SSL
echo -e "Creating initial SSL certificate...$COL_RESET"

# Install openssl.
apt_install openssl;
wait $!

# Create a directory to store TLS-related things like "SSL" certificates.
sudo mkdir -p $STORAGE_ROOT/ssl;

# Generate a new private key.
	# Set the umask so the key file is never world-readable.
	hide_output sudo openssl genrsa -out $STORAGE_ROOT/ssl/ssl_private_key.pem 2048;
    wait $!

	# Generate a certificate signing request.
	CSR=$STORAGE_ROOT/ssl/ssl_cert_sign_req-$$.csr;
	hide_output sudo openssl req -new -key $STORAGE_ROOT/ssl/ssl_private_key.pem -out $CSR -sha256 -subj "/CN=$PRIMARY_HOSTNAME";
  wait $!

	# Generate the self-signed certificate.
	CERT=$STORAGE_ROOT/ssl/$PRIMARY_HOSTNAME-selfsigned-$(date --rfc-3339=date | sed s/-//g).pem;
	hide_output sudo openssl x509 -req -days 365 -in $CSR -signkey $STORAGE_ROOT/ssl/ssl_private_key.pem -out $CERT;
  wait $!

	# Delete the certificate signing request because it has no other purpose.
  sudo rm -f $CSR;
  wait $!

	# Symlink the certificate into the system certificate path, so system services
	# can find it.
  sudo ln -s $CERT $STORAGE_ROOT/ssl/ssl_certificate.pem;
  wait $!

# Generate some Diffie-Hellman cipher bits.
# openssl's default bit length for this is 1024 bits, but we'll create
# 2048 bits of bits per the latest recommendations.
hide_output sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048;
wait $!
sudo chmod 077 $STORAGE_ROOT/ssl/ssl_private_key.pem
echo -e "$GREEN Initial Self Signed SSL Generation completed...$COL_RESET"
