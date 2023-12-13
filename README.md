# puppet-test-harness

This is a small test harness that allows testing of new puppet modules.

It consists of two "nodes" a puppet server called `puppet` and an example node `eximage` that is to be
managed by puppet.

# Quick Start Guide

Checkout this repository then copy the contents of the `xms-puppet` repository
into the `puppet` subdirectory:

```
git clone https://github.com/jpwhite4/puppet-test-harness.git
cd puppet-test-harness/puppet
git clone git@tools-int-01.ccr.xdmod.org:UBCCR/xms-puppet.git
cd ..
```

Then use `docker-compose` to build the images:
```
docker-compose up
```

# Puppet Setup

The containers are setup with puppet almost identically to the real cloud.

First login to the puppet server
```
ssh -p 6222 rocky@localhost
```
Inside the `puppet` container, edit the site manifest:
```
sudo vi /etc/puppetlabs/code/environments/production/manifests/sites.pp
```
For example, add the node `eximage` to the manifest with the accounts class you would
add the following:
```
node 'eximage' {
    include accounts
}
```
Then login to `eximage`. This can be done either with either
```
ssh eximage
```
from inside the container or
```
ssh -p 6223 rocky@localhost
```
from outside.

On `eximage`, start the puppet agent to create the certificate:
```
sudo /opt/puppetlabs/bin/puppet agent -t
```
Then back to the puppet server run the following command:
```
sudo /opt/puppetlabs/bin/puppetserver ca list
```
The new VM should be included in the list. Sign the certificate:
```
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname eximage
```

Back on `eximage`, run the puppet agent again to apply the changes:
```
sudo /opt/puppetlabs/bin/puppet agent -t
```

# Notes

If you make a change to any of the docker files and scripts then run the
```
docker-compose build
```
command to rebuild the images.
