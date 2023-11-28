#!/bin/bash
set -e

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

source /build/base.config

echo "Admin user  = $ADMIN_USER"
GOSU_VERSION=${GOSU_VERSION:-1.12}

#------------------------
# Install base packages
#------------------------
log_info "Installing base packages.."
dnf install -y \
    openssh-server \
    openssh-clients \
    sudo \
    epel-release \
    wget \
    vim \
    authconfig \
    openssl \
    bash-completion \
    passwd

#------------------------
# Generate ssh host keys
#------------------------
log_info "Generating ssh host keys.."
ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
chgrp ssh_keys /etc/ssh/ssh_host_rsa_key
chgrp ssh_keys /etc/ssh/ssh_host_ecdsa_key
chgrp ssh_keys /etc/ssh/ssh_host_ed25519_key

rm -f /var/run/nologin

#------------------------
# Setup user accounts
#------------------------

useradd -ms /bin/bash $ADMIN_USER
echo $ADMIN_PASSWD | passwd --stdin $ADMIN_USER
idnumber=`id -u $ADMIN_USER`
install -d -o $idnumber -g $idnumber -m 0700 /home/$ADMIN_USER/.ssh
ssh-keygen -b 2048 -t rsa -f /home/$ADMIN_USER/.ssh/id_rsa -q -N ""
install -o $idnumber -g $idnumber -m 0600 /home/$ADMIN_USER/.ssh/id_rsa.pub /home/$ADMIN_USER/.ssh/authorized_keys
cat > /home/$ADMIN_USER/.ssh/config <<EOF
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile /dev/null
EOF
chown -R $idnumber:$idnumber /home/$ADMIN_USER

sudo tee /etc/sudoers.d/90-$ADMIN_USER <<EOF
# User rules for $ADMIN_USER
$ADMIN_USER ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/90-$ADMIN_USER

#------------------------
# Install gosu
#------------------------
log_info "Installing gosu.."
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"
chmod +x /usr/local/bin/gosu
gosu nobody true

log_info "Creating self-signed ssl certs.."
# Generate CA
openssl genrsa -out /etc/pki/tls/ca.key 4096
openssl req -new -x509 -days 3650 -sha256 -key /etc/pki/tls/ca.key -extensions v3_ca -out /etc/pki/tls/ca.crt -subj "/CN=fake-ca"
# Generate certificate request
openssl genrsa -out /etc/pki/tls/private/localhost.key 2048
openssl req -new -sha256 -key /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.csr -subj "/C=US/ST=NY/O=HPC Tutorial/CN=localhost"
# Config for signing cert
cat > /etc/pki/tls/localhost.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:localhost
extendedKeyUsage = serverAuth
EOF
# Sign cert request and generate cert
openssl x509 -req -CA /etc/pki/tls/ca.crt -CAkey /etc/pki/tls/ca.key -CAcreateserial \
  -in /etc/pki/tls/certs/localhost.csr -out /etc/pki/tls/certs/localhost.crt \
  -days 365 -sha256 -extfile /etc/pki/tls/localhost.ext
# Add CA to trust store
cp /etc/pki/tls/ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

yum install -y https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
yum install -y puppet-agent

yum clean all
rm -rf /var/cache/yum
