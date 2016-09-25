#!/bin/bash
CONTAINER=$1
sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable -y
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install lxd -y

newgrp lxd
sudo lxd init

lxc launch ubuntu-daily:16.04 $CONTAINER

