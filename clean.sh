#!/bin/bash
lxc remote remove ubuntu-adi-test-lxdserver
lxc delete ubuntu-adi-test-lxdserver --force
rm -fR ansible node_modules tmp
