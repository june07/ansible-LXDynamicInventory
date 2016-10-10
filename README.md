# ![pageres](https://june07.github.io/Ansible-LXDynamic-Inventory/media/aLXDiLogo.png)![Build Status](https://img.shields.io/travis/june07/Ansible-LXDynamic-Inventory.svg)
## Ansible LXDynamic Inventory ##
A dynamic inventory script for use with Ansible and LXD Containers.

I did find one other dynamic inventory script for LXD, however it did not meet my needs.  Some requirements which are met by this script are:
* Utilizes the LXD REST API throughout starting at the Ansible host.
* Groups can be dynamically configured based on meta variables set on the containers.

## Install
```
$ npm install --save
```
This will simply copy the precompiled lxd.nex script, along with lxd.ini into your [inventory directory](http://docs.ansible.com/ansible/intro_dynamic_inventory.html#using-inventory-directories-and-multiple-inventory-sources "Ansible documentation on multiple inventory sources").  Then update your inventory file and add any LXD hosts using the lxd connector as in ```ubuntu-adi-test-lxdserver ansible_connection=lxd```.

You should then be able to issue a playbook or other applicable ansible command to any LXD containers configured on that LXD host!

### a bit more detail...

Since authentication for the LXD API is done through client certificate authentication, this script will automatically generate a client certificate.  You will want to change the lxd.ini file to reflect your own SSL cert details:

![Code Editor Screenshot lxd.ini](https://june07.github.io/image/dillinger.june07.com-clipboard01.jpg)

The certifcate will be stored in ```~/.ansible/tmp/ssl``` or whatever location you have configured for **_remote_tmp_** in your ```ansible.cfg``` file.

## Building from source
```
$ npm build
```
Will compile the lxd.js script into a self contained executable lxd.nex which can be used without requiring installation of node dependancies.

Although the actual build of the lxd.js script should work anywhere (that node would work), the npm install from source only supports Ubuntu and has been tested on both Trusty (Travis-ci) and Xenial.  Basically the tests involve creating a test LXD server which in turn creates several nested test containers, afterwhich the script can be used on the aforementioned test environment.

## License
MIT © [June07](https://github.com/june07)