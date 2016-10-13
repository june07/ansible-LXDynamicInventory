#!/bin/bash -x

toilet -f wideterm --gay Starting tests... -S

cd ansible
echo -e "[defaults]\nremote_tmp     = $HOME/.ansible/tmp" > ansible.cfg
echo -e "inventory     = inventory" >> ansible.cfg
mkdir inventory
echo -e "[lxdhosts]\nubuntu-adi-test-lxdserver ansible_connection=lxd" > ./inventory/development_inventory

LXD_BRIDGE_IP=$(ip addr show dev lxdbr0 scope global | grep inet | grep -v inet6 | awk 'BEGIN {FS=" "}{print $2}' | cut -f1 -d"/")
# Update hosts file to resolv hostname of LXD container.
sudo cp /etc/resolv.conf /tmp/.resolv.conf.backup-$(date +%s)
sudo perl -0 -pi -e "s/nameserver /nameserver $LXD_BRIDGE_IP\nnameserver /" /etc/resolv.conf
echo -e "\n$(sudo lxc list ubuntu-adi-test-lxdserver -c4 | grep eth0 | cut -d' ' -f2)\tubuntu-adi-test-lxdserver" | sudo tee -a /etc/hosts

# Execute tests.
cat /etc/hosts
source ./hacking/env-setup
sudo ansible --version
sudo ./inventory/lxd.nex --list
cat /etc/hosts
sudo lxc list ubuntu-adi-test-lxdserver:
sudo ansible -m setup ubuntu-adi-test-lxdserver

# Recover state of resolv and hosts file
sudo perl -pi -e "s/nameserver $LXD_BRIDGE_IP\n//" /etc/resolv.conf
sudo grep -v ubuntu-adi-test-lxdserver /etc/hosts | sudo tee -a /etc/hosts
