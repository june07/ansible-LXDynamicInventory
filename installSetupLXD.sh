#!/bin/bash
CONTAINER=$1
NETWORK=$2
PASSWORD=$3
LXDSERVER=$4
if [[ $(echo $CONTAINER | grep -i server) || $(echo $CONTAINER | grep -i container) ]]; then
  sudo echo -e "Acquire::http::Proxy \"http://${LXDSERVER}:3142\"" >> /etc/apt.conf;
fi
sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable -y -q
sudo apt-get update -y -q
sudo apt-get dist-upgrade -y -q
sudo apt-get install lxd -y -q
sudo apt-get install python -y -q
if [[ ! $(echo $CONTAINER | grep -i container) ]]; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher -q
fi

sudo lxd init --auto --network-address 10.202.${NETWORK}.1 --network-port 8443 --trust-password=$PASSWORD

if [[ ! $(echo $CONTAINER | grep -i container) ]]; then
sudo systemctl stop lxd-bridge
sudo systemctl --system daemon-reload
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
EOF
'
sudo systemctl enable lxd-bridge
sudo systemctl start lxd-bridge

lxc config set core.https_address [::]:8443
lxc config set core.trust_password $PASSWORD
fi

