#!/bin/bash

sudo apt install -y qemu-kvm libvirt-daemon-system virt-manager
sudo usermod -aG libvirt $USER
reboot