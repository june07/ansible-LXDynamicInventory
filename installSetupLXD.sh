#!/bin/bash -x
export DEBIAN_FRONTEND=noninteractive;
CONTAINER=$1
NETWORK=$2
PASSWORD=$3
LXDSERVER=$4
sudo perl -pi -e "s/127.0.0.1 localhost/127.0.0.1 localhost $(hostname)/" /etc/hosts
if [[ $(echo $CONTAINER | grep -i server) || $(echo $CONTAINER | grep -i container) ]]; then
  sudo echo -e "Acquire::http::Proxy \"http://${LXDSERVER}:3142\";" >> /etc/apt/apt.conf;
fi

sudo apt-get --purge remove postgresql\*

if [[ $(lsb_release -c|grep -i "trusty") ]]; then
  sudo add-apt-repository -y ppa:pitti/systemd > /dev/null 2>&1
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update -qq
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -qq
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -qq -t trusty-backports lxd
else
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update -qq
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -qq
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -qq lxd
fi
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -qq python
if [[ ! $(echo $CONTAINER | grep -i container) ]]; then
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -qq apt-cacher-ng
fi

if [[ ! $(echo $CONTAINER | grep -i container) ]]; then
  if [[ $(lsb_release -c|grep -i "trusty") ]]; then
    sudo newgrp lxd << SCRIPT
      sudo service lxd stop
SCRIPT
  else
    sudo newgrp lxd << SCRIPT
      sudo systemctl stop lxd-bridge
      sudo systemctl --system daemon-reload
SCRIPT
  fi
  sudo su -c 'cat <<EOF > /etc/default/lxd-bridge
USE_LXD_BRIDGE="true"
LXD_BRIDGE="lxdbr0"
UPDATE_PROFILE="true"
LXD_CONFILE=""
LXD_DOMAIN="lxd"
LXD_IPV4_ADDR="10.202.'$NETWORK'.1"
LXD_IPV4_NETMASK="255.255.255.0"
LXD_IPV4_NETWORK="10.202.'$NETWORK'.1/24"
LXD_IPV4_DHCP_RANGE="10.202.'$NETWORK'.2,10.202.'$NETWORK'.254"
LXD_IPV4_DHCP_MAX="252"
LXD_IPV4_NAT="true"
LXD_IPV6_ADDR=""
LXD_IPV6_MASK=""
LXD_IPV6_NETWORK=""
LXD_IPV6_NAT="false"
LXD_IPV6_PROXY="false"
EOF'
  if [[ $(lsb_release -c|grep -i "trusty") ]]; then
    sudo newgrp lxd << SCRIPT
      sudo service lxd start
      lxc config set core.https_address [::]:8443
      lxc config set core.trust_password $PASSWORD
SCRIPT
  else
    sudo newgrp lxd << SCRIPT
      sudo systemctl enable lxd-bridge
      sudo systemctl start lxd-bridge
      lxc config set core.https_address [::]:8443
      lxc config set core.trust_password $PASSWORD
SCRIPT
  fi
fi

sudo newgrp lxd << SCRIPT
  sudo lxd init --auto --network-address 0.0.0.0 --network-port 8443 --trust-password=$PASSWORD
SCRIPT

