#!/bin/bash
export DEBIAN_FRONTEND=noninteractive;
#PASSWORD=$(date | md5sum | cut -f1 -d " " | tee /tmp/adi-password.txt)
PASSWORD=8hJKBwMzxAycXf0CfVWy
#IMAGE="ubuntu-daily:16.04"
IMAGE="ubuntu-daily:14.04"
sudo add-apt-repository ppa:ansible/ansible -y > /dev/null 2>&1
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" update -qq
#sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -qq 
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -y git build-essential python toilet apt-cacher-ng python-yaml python-pip
sudo pip install ansible

git clone https://github.com/ansible/ansible.git
cd ansible
git submodule update --init --recursive
cd ..

compile() {
	node --harmony node_modules/nexe/bin/nexe -i lxd.js -o lxd.nex -f
	chmod +x ./lxd.nex;
	mkdir ./ansible/inventory
	cp ./lxd.nex ./ansible/inventory/
	cp ./lxd.ini ./ansible/inventory/
}
compile

spinner() {
	COUNTER=0
	SECS=$1
  chars="/-\|"
	while [[ $COUNTER -lt $SECS ]]; do
    for (( i=0; i<${#chars}; i++ )); do
      sleep 0.5
      echo -en "${chars:$i:1}" "\r"
    done
	  ((COUNTER++))
	done
	echo ""
}

chmod +x ./installSetupLXD.sh

if [[ ! $(dpkg --list lxd) ]]; then
  toilet -f wideterm --gay Configuring LXD on this host... -S
  ./installSetupLXD.sh local 80 $PASSWORD
else
  toilet -f wideterm --gay LXD present, skipping configuration... -S
fi

sudo usermod -a -G lxd $USER
sudo lxc launch $IMAGE ubuntu-adi-test-lxdserver -c security.nesting=true -c security.privileged=true
spinner 15

CACHERIP=$(ip addr show dev lxdbr0 scope global | grep inet | grep -v inet6 | awk 'BEGIN {FS=" "}{print $2}' | cut -f1 -d"/")

# Update hosts file to resolv hostname of LXD container.
sudo cp /etc/resolv.conf /tmp/.resolv.conf.backup-$(date +%s)
sudo perl -0 -pi -e "s/nameserver /nameserver $CACHERIP\nnameserver /" /etc/resolv.conf
echo -e "$(sudo lxc list ubuntu-adi-test-lxdserver -c4 | grep eth0 | cut -d' ' -f2)\tubuntu-adi-test-lxdserver" | sudo tee -a /etc/hosts

toilet -f wideterm --gay Configuring LXD HOST container... -S
sudo lxc file push installSetupLXD.sh ubuntu-adi-test-lxdserver/tmp/
sudo lxc exec ubuntu-adi-test-lxdserver /tmp/installSetupLXD.sh ubuntu-adi-test-lxdserver 90 $PASSWORD $CACHERIP
spinner 15

LXDIP=$(sudo lxc list ubuntu-adi-test-lxdserver --format=json | jq '.[0].state.network.eth0.addresses[0].address'|tr -d "\"")
sudo lxc remote add ubuntu-adi-test-lxdserver https://$LXDIP --password=$PASSWORD --accept-certificate

sudo lxc remote list; spinner 5

count=1
howmany=3
function setupNestedContainer {
  toilet -f wideterm --gay Configuring nested container $1... -S
  sudo lxc launch $IMAGE ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer${1}
  sudo lxc config set ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer${1} user.ansible.group adigroup
  #lxc config set ubuntu-adi-test-lxdserver core.https_address [::]:8443
  #lxc config set ubuntu-adi-test-lxdserver core.trust_password $PASSWORD
  #lxc file push installSetupLXD.sh ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer${1}/tmp/
  #lxc exec ubuntu-adi-test-lxdserver:ubuntu-adi-test-lxdcontainer${1} /tmp/installSetupLXD.sh ubuntu-adi-test-lxdcontainer${1} 100 $PASSWORD $LXDIP
}
while [[ $count -le $howmany ]]; do
  if [[ $count -eq $howmany ]]; then
    setupNestedContainer $count
    toilet -f wideterm --gay Waiting 60 seconds... -S
    spinner 60
  else
    setupNestedContainer $count &
  fi
  ((count++))
done

sudo lxc list
toilet -f wideterm --gay $0 complete. -S

