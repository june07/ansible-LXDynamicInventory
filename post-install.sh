#!/bin/bash
HOSTNAME=$1
#PASSWORD=$(date | md5sum | cut -f1 -d " " | tee /tmp/adi-password.txt)
PASSWORD=8hJKBwMzxAycXf0CfVWy
IMAGE="ubuntu-daily:16.04"
sudo apt-get install git -y
git clone https://github.com/ansible/ansible.git

nexe -i lxd.js -o lxd.nex -f

chmod +x ./lxd.nex;
cp ./lxd.nex ./ansible/inventory/

function spinner {
COUNTER=0
SECONDS=$1
while [[ $COUNTER -lt $SECONDS ]]; do
  sleep 0.5; printf "\r${sp:i++%${#sp}:1}";
  COUNTER=$(($COUNTER+1))
done
echo ""
}

chmod +x ./installSetupLXD.sh

if [[ ! $(dpkg --list lxd) ]]; then
  figlet -f wideterm --gay Configuring LXD on this host... -S
  ./installSetupLXD.sh local 80
else
  figlet -f wideterm --gay LXD is already on this host, skipping configuration... -S
  figlet -f wideterm --gay Updating apt and installing apt-cacher... -S
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher
  sudo perl -pi -e s/AUTOSTART=0/AUTOSTART=1/g /etc/default/apt-cacher
  sudo systemctl start apt-cacher.service
  lxc image copy $IMAGE local:
  lxc launch $IMAGE ubuntu-adi-test-lxdserver -c security.nesting=true -c security.privileged=true
  spinner 15
fi

CACHERIP=$(ip addr show dev lxdbr0 scope global | grep inet | grep -v inet6 | awk 'BEGIN {FS=" "}{print $2}' | cut -f1 -d"/")
figlet -f wideterm --gay Configuring LXD HOST container... -S
lxc file push installSetupLXD.sh ubuntu-adi-test-lxdserver/tmp/
lxc exec ubuntu-adi-test-lxdserver /tmp/installSetupLXD.sh ubuntu-adi-test-lxdserver 90 $PASSWORD $CACHERIP

spinner 15

LXDIP=$(lxc list ubuntu-adi-test-lxdserver --format=json | jq '.[0].state.network.eth0.addresses[0].address'|tr -d "\"")
#sudo iptables -t nat -A PREROUTING -d localhost -i eth0 -p tcp -m tcp --dport 18443 -j DNAT --to-destination $LXDIP:8443
lxc remote add ubuntu-adi-test-lxdserver https://$LXDIP --password=$PASSWORD --accept-certificate

lxc remote list; spinner 5

figlet -f wideterm --gay Configuring nested container... -S
lxc launch $IMAGE ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer
#lxc config set ubuntu-adi-test-lxdserver core.https_address [::]:8443
#lxc config set ubuntu-adi-test-lxdserver core.trust_password $PASSWORD
lxc file push installSetupLXD.sh ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer/tmp/
lxc exec ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer /tmp/installSetupLXD.sh ubuntu-adi-test-lxdcontainer 100 $PASSWORD $LXDIP
# Setup LXD container


cd ansible
echo -e "[defaults]\nremote_tmp     = $HOME/.ansible/tmp" > ansible.cfg
echo -e "inventory     = inventory" >> ansible.cfg
mkdir inventory
echo -e "[lxdhosts]\nubuntu-adi-test-lxdserver ansible_connection=lxd" > ./inventory/development_inventory

