#!/bin/bash
HOSTNAME=$1
sudo apt-get install git
git clone https://github.com/ansible/ansible.git
cd ansible
echo "remote_tmp     = $HOME/.ansible/tmp" > ansible.cfg
mkdir inventory
echo "$HOSTNAME ansible_connection=lxd" > ./inventory/development_inventory

cd ..
nexe -i lxd.js -o lxd.nex -f

chmod +x ./lxd.nex;
cp ./lxd.nex ./ansible/inventory/development_inventory

chmod +x ./installSetupLXD.sh
./installSetupLXD.sh ubuntu-adi-test

lxc file push installSetupLXD.sh ubuntu-adi-test/tmp/
lxc exec ubuntu-adi-test -- ubuntu-adi-test/tmp/installSetupLXD.sh

