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
This will simply copy the precompiled lxd.nex script into your [inventory directory](http://docs.ansible.com/ansible/intro_dynamic_inventory.html#using-inventory-directories-and-multiple-inventory-sources "Ansible documentation on multiple inventory sources")
## Building from source
```
$ npm build
```
Will compile the lxd.js script into a self contained executable lxd.nex which can be used without requiring installation of node dependancies.

Although the actual build of the lxd.js script should work anywhere (that node would work), the npm install from source only supports Ubuntu and has been tested on both Trusty (Travis-ci) and Xenial.  Basically the tests involve creating a test LXD server which in turn creates several nested test containers, afterwhich the script can be used on the aforementioned test environment.

## License
MIT © [June07](https://github.com/june07)