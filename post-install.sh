#!/bin/bash
export DEBIAN_FRONTEND=noninteractive;
HOSTNAME=$1
#PASSWORD=$(date | md5sum | cut -f1 -d " " | tee /tmp/adi-password.txt)
PASSWORD=8hJKBwMzxAycXf0CfVWy
IMAGE="ubuntu-daily:16.04"
sudo apt-get remove -y postgresql-9.1
sudo apt-get remove -y postgresql-9.2
sudo apt-get remove -y postgresql-9.3
sudo apt-get remove -y postgresql-9.4
sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable -y
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update -y -q
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y -q
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install git build-essential python toilet -y -q

git clone https://github.com/ansible/ansible.git
cd ansible
git submodule update --init --recursive
cd ..

node --harmony node_modules/nexe/bin/nexe -i lxd.js -o lxd.nex -f

chmod +x ./lxd.nex;
mkdir ./ansible/inventory
cp ./lxd.nex ./ansible/inventory/
cp ./lxd.ini ./ansible/inventory/

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
  toilet -f wideterm --gay Configuring LXD on this host... -S
  ./installSetupLXD.sh local 80
else
  toilet -f wideterm --gay LXD is already on this host, skipping configuration... -S
  toilet -f wideterm --gay Updating apt and installing apt-cacher-ng... -S
  sudo sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update -y -q
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y -q
  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -y -q apt-cacher-ng
  lxc image copy $IMAGE local:
  lxc launch $IMAGE ubuntu-adi-test-lxdserver -c security.nesting=true -c security.privileged=true
  spinner 15
fi

CACHERIP=$(ip addr show dev lxdbr0 scope global | grep inet | grep -v inet6 | awk 'BEGIN {FS=" "}{print $2}' | cut -f1 -d"/")
toilet -f wideterm --gay Configuring LXD HOST container... -S
lxc file push installSetupLXD.sh ubuntu-adi-test-lxdserver/tmp/
lxc exec ubuntu-adi-test-lxdserver /tmp/installSetupLXD.sh ubuntu-adi-test-lxdserver 90 $PASSWORD $CACHERIP

spinner 15

LXDIP=$(lxc list ubuntu-adi-test-lxdserver --format=json | jq '.[0].state.network.eth0.addresses[0].address'|tr -d "\"")
#sudo iptables -t nat -A PREROUTING -d localhost -i eth0 -p tcp -m tcp --dport 18443 -j DNAT --to-destination $LXDIP:8443
lxc remote add ubuntu-adi-test-lxdserver https://$LXDIP --password=$PASSWORD --accept-certificate

lxc remote list; spinner 5

toilet -f wideterm --gay Configuring nested container... -S
lxc launch $IMAGE ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer
lxc config set ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer user.ansible.group adigroup
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

sudo cp /etc/resolv.conf /tmp/.resolv.conf.backup-$(date +%s)
sudo perl -0 -pi -e "s/nameserver /nameserver $CACHERIP\nnameserver /" /etc/resolv.conf
./inventory/lxd.nex --list
ansible -m setup ubuntu-adi-test-lxdserver
sudo perl -0 -pi -e "s/nameserver $CACHERIP\n//" /etc/resolv.conf

