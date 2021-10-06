#!/bin/bash
set -e

if [ "$1" = "serve" ]
then

    mkdir -p /etc/puppetlabs/puppet
    cat >/etc/puppetlabs/puppet/puppet.conf << EOF
[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = \$vardir/ssl

[agent]
pluginsync      = true
report          = true
ignoreschedules = true
ca_server       = puppet
certname        = $HOSTNAME
environment     = production
server          = puppet
EOF
elif [ "$1" = "puppetserver" ]
then
    echo "---> Starting puppetserver ..."
    /opt/puppetlabs/server/apps/puppetserver/bin/puppetserver start &
fi

echo "---> Starting sshd ..."
/usr/sbin/sshd -D -e

exec "$@"
